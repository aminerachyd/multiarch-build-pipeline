#!/usr/bin/env node

const { program } = require("commander");
const { exec } = require("child_process");
const fs = require("fs");

program
  .name("mpt")
  .description(
    "A CLI for launching multiarch build pipelines on Tekton across different clusters"
  )
  .version("0.0.1");

program
  .option("-a, --app-name <name>", "Name of the app")
  .option("-g, --git-url <repo>", "Git repository of the app")
  .option(
    "-r, --image-registry <registry>",
    "Image registry to store the images"
  )
  .option(
    "-n, --namespace <namespace>",
    "Name of the user/organisation on the registry"
  )
  .option(
    "-h, --health-protocol <health-protocol>",
    "Protocol to check the health of the app, either https or grpc"
  )
  .option("-x86, --build-on-x86", "Toggle build on x86 architecture")
  .option("-power, --build-on-power", "Toggle build on IBM Power architecture")
  .option("-z, --build-on-z", "Toggle build on IBM Z architecture")
  .option("--api-server-x86 <api-server-x86-url>", "API server for x86 cluster")
  .option(
    "--api-server-power <api-server-power-url>",
    "API server for power cluster"
  )
  .option("--api-server-z <api-server-z-url>", "API server for z cluster")
  .parse(process.argv);

const options = program.opts();
if (
  !options.appName ||
  !options.gitUrl ||
  !options.imageRegistry ||
  !options.namespace ||
  !options.healthProtocol
) {
  console.log("Please provide all the required options");
  process.exit(1);
}

const pipelineName = options.appName + "-multiarch-pipeline";

if (!options.buildOnX86 && !options.buildOnPower && !options.buildOnZ) {
  console.log("Please provide atleast one build option");
  process.exit(1);
}

if (!options.apiServerX86 && !options.apiServerPower && !options.apiServerZ) {
  console.log("Please provide atleast one API server option");
  process.exit(1);
}

if (options.buildOnX86 && !options.apiServerX86) {
  console.log("Please provide the API server for x86 cluster");
  process.exit(1);
}

if (options.buildOnPower && !options.apiServerPower) {
  console.log("Please provide the API server for Power cluster");
  process.exit(1);
}

if (options.buildOnZ && !options.apiServerZ) {
  console.log("Please provide the API server for Z cluster");
  process.exit(1);
}

const DO_BUILD_ON_X86 = options.buildOnX86 && options.apiServerX86;
const DO_BUILD_ON_POWER = options.buildOnPower && options.apiServerPower;
const DO_BUILD_ON_Z = options.buildOnZ && options.apiServerZ;

let pipeline = `
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: ${pipelineName}
spec:
  params:
    - description: The url for the git repository
      name: git-url
    - default: master
      description: "The git revision (branch, tag, or sha) that should be built"
      name: git-revision
    - name: image-server
      description: "Image registry to store the image in"
    - name: image-namespace
      description: "Image namespace in the registry (user or organisation)"
    - default: "false"
      description: Enable the pipeline to scan the image for vulnerabilities
      name: scan-image
    - default: "false"
      description: Enable the pipeline to lint the Dockerfile for best practices
      name: lint-dockerfile
    - default: grpc
      description: >-
        Protocol to check health after deployment, either https or grpc,
        defaults to https
      name: health-protocol
    - default: /
      description: "Endpoint to check health after deployment, defaults /"
      name: health-endpoint
    ${
      options.buildOnX86
        ? `
    - name: x86-server-url
      description: "X86 cluster API server for multiarch build"
     `
        : ""
    }
    ${
      options.buildOnPower
        ? `
    - name: power-server-url
      description: "Power cluster API server for multiarch build"
     `
        : ""
    }
    ${
      options.buildOnZ
        ? `
    - name: z-server-url
      description: "Z cluster API server for multiarch build"
     `
        : ""
    }
  tasks:
    - name: setup
      params:
        - name: git-url
          value: \$(params.git-url)
        - name: git-revision
          value: $(params.git-revision)
        - name: image-server
          value: $(params.image-server)
        - name: image-namespace
          value: $(params.image-namespace)
        - name: scan-image
          value: $(params.scan-image)
        - name: health-endpoint
          value: $(params.health-endpoint)
        - name: health-protocol
          value: $(params.health-protocol)
        - name: lint-dockerfile
          value: $(params.lint-dockerfile)
      taskRef:
        kind: Task
        name: ibm-setup-v2-7-8
    - name: code-test
      runAfter:
        - setup
      taskRef:
        kind: Task
        name: code-test
    - name: code-lint
      params:
        - name: git-url
          value: $(tasks.setup.results.git-url)
        - name: git-revision
          value: $(tasks.setup.results.git-revision)
        - name: source-dir
          value: $(tasks.setup.results.source-dir)
        - name: app-name
          value: $(tasks.setup.results.app-name)
      runAfter:
        - code-test
      taskRef:
        kind: Task
        name: ibm-sonar-test-v2-7-7
    - name: dockerfile-lint
      params:
        - name: git-url
          value: $(tasks.setup.results.git-url)
        - name: git-revision
          value: $(tasks.setup.results.git-revision)
        - name: source-dir
          value: $(tasks.setup.results.source-dir)
        - name: lint-dockerfile
          value: $(tasks.setup.results.dockerfile-lint)
      runAfter:
        - code-lint
      taskRef:
        kind: Task
        name: ibm-dockerfile-lint-v2-7-7
    ${
      options.buildOnX86
        ? `
    - name: simver
      params:
        - name: git-url
          value: $(tasks.setup.results.git-url)
        - name: git-revision
          value: $(tasks.setup.results.git-revision)
        - name: source-dir
          value: $(tasks.setup.results.source-dir)
        - name: js-image
          value: $(tasks.setup.results.js-image)
        - name: skip-push
          value: "true"
      runAfter:
        - dockerfile-lint
      taskRef:
        kind: Task
        name: ibm-tag-release-v2-7-7
    - name: build-x86
      params:
        - name: git-url
          value: $(tasks.setup.results.git-url)
        - name: git-revision
          value: $(tasks.setup.results.git-revision)
        - name: image-server
          value: $(params.image-server)
        - name: image-namespace
          value: $(params.image-namespace)
        - name: image-repository
          value: $(tasks.setup.results.app-name)
        - name: image-tag
          value: $(tasks.simver.results.tag)
        - name: pipeline-name
          value: build-push
        - name: pipeline-namespace
          value: multiarch-demo
        - name: openshift-server-url
          value: $(params.x86-server-url)
        - name: openshift-token-secret
          value: builder-cluster-x86-secret
      runAfter:
        - simver
      taskRef:
        kind: Task
        name: execute-remote-pipeline
      `
        : ""
    }
    ${
      options.buildOnPower
        ? `
    - name: build-power
      params:
        - name: git-url
          value: $(tasks.setup.results.git-url)
        - name: git-revision
          value: $(tasks.setup.results.git-revision)
        - name: image-server
          value: $(params.image-server)
        - name: image-namespace
          value: $(params.image-namespace)
        - name: image-repository
          value: $(tasks.setup.results.app-name)
        - name: image-tag
          value: $(tasks.simver.results.tag)
        - name: pipeline-name
          value: build-push
        - name: pipeline-namespace
          value: multiarch-demo
        - name: openshift-server-url
          value: $(params.power-server-url)
        - name: openshift-token-secret
          value: builder-cluster-power-secret
      runAfter:
        - simver
      taskRef:
        kind: Task
        name: execute-remote-pipeline
      `
        : ""
    }
    ${
      options.buildOnZ
        ? `
    - name: build-z
      params:
        - name: git-url
          value: $(tasks.setup.results.git-url)
        - name: git-revision
          value: $(tasks.setup.results.git-revision)
        - name: image-server
          value: $(params.image-server)
        - name: image-namespace
          value: $(params.image-namespace)
        - name: image-repository
          value: $(tasks.setup.results.app-name)
        - name: image-tag
          value: $(tasks.simver.results.tag)
        - name: pipeline-name
          value: build-push
        - name: pipeline-namespace
          value: multiarch-demo
        - name: openshift-server-url
          value: $(params.z-server-url)
        - name: openshift-token-secret
          value: builder-cluster-z-secret
      runAfter:
        - simver
      taskRef:
        kind: Task
        name: execute-remote-pipeline
      `
        : ""
    }
    - name: manifest
      params:
        - name: image-server
          value: $(params.image-server)
        - name: image-namespace
          value: $(params.image-namespace)
        - name: image-repository
          value: $(tasks.setup.results.app-name)
        - name: image-tag
          value: $(tasks.simver.results.tag)
      taskRef:
        kind: Task
        name: manifest-${options.appName}
      runAfter:
        ${options.buildOnX86 ? `- build-x86` : ""}
        ${options.buildOnPower ? `- build-power` : ""}
        ${options.buildOnZ ? `- build-z` : ""}
    - name: deploy
      params:
        - name: git-url
          value: $(tasks.setup.results.git-url)
        - name: git-revision
          value: $(tasks.setup.results.git-revision)
        - name: source-dir
          value: $(tasks.setup.results.source-dir)
        - name: image-server
          value: $(tasks.setup.results.image-server)
        - name: image-namespace
          value: $(tasks.setup.results.image-namespace)
        - name: image-repository
          value: $(tasks.setup.results.image-repository)
        - name: image-tag
          value: $(tasks.simver.results.tag)
        - name: app-namespace
          value: $(tasks.setup.results.app-namespace)
        - name: app-name
          value: $(tasks.setup.results.app-name)
        - name: deploy-ingress-type
          value: $(tasks.setup.results.deploy-ingress-type)
        - name: tools-image
          value: $(tasks.setup.results.tools-image)
      runAfter:
        - manifest
      taskRef:
        kind: Task
        name: ibm-deploy-v2-7-7
    - name: health
      params:
        - name: app-namespace
          value: $(tasks.setup.results.app-namespace)
        - name: app-name
          value: $(tasks.setup.results.app-name)
        - name: deploy-ingress-type
          value: $(tasks.setup.results.deploy-ingress-type)
        - name: health-protocol
          value: $(tasks.setup.results.health-protocol)
        - name: health-endpoint
          value: $(tasks.setup.results.health-endpoint)
        - name: health-url
          value: $(tasks.setup.results.health-url)
        - name: health-curl
          value: $(tasks.setup.results.health-curl)
        - name: tools-image
          value: $(tasks.setup.results.tools-image)
      runAfter:
        - deploy
      taskRef:
        kind: Task
        name: ibm-health-check-v2-7-8
    - name: img-scan
      params:
        - name: image-url
          value: $(tasks.setup.results.image-url):$(tasks.simver.results.tag)
        - name: scan-trivy
          value: $(tasks.setup.results.scan-trivy)
        - name: scan-ibm
          value: $(tasks.setup.results.scan-ibm)
      runAfter:
        - health
      taskRef:
        kind: Task
        name: ibm-img-scan-v2-7-7
    - name: tag-release
      params:
        - name: git-url
          value: $(tasks.setup.results.git-url)
        - name: git-revision
          value: $(tasks.setup.results.git-revision)
        - name: source-dir
          value: $(tasks.setup.results.source-dir)
        - name: js-image
          value: $(tasks.setup.results.js-image)
      runAfter:
        - img-scan
      taskRef:
        kind: Task
        name: ibm-tag-release-v2-7-7
    - name: helm-release
      params:
        - name: git-url
          value: $(tasks.setup.results.git-url)
        - name: git-revision
          value: $(tasks.setup.results.git-revision)
        - name: source-dir
          value: $(tasks.setup.results.source-dir)
        - name: image-url
          value: $(tasks.setup.results.image-url):$(tasks.simver.results.tag)
        - name: app-name
          value: $(tasks.setup.results.app-name)
        - name: deploy-ingress-type
          value: $(tasks.setup.results.deploy-ingress-type)
        - name: tools-image
          value: $(tasks.setup.results.tools-image)
      runAfter:
        - tag-release
      taskRef:
        kind: Task
        name: ibm-helm-release-v2-7-7
    - name: gitops
      params:
        - name: app-name
          value: $(tasks.setup.results.app-name)
        - name: version
          value: $(tasks.simver.results.tag)
        - name: helm-url
          value: $(tasks.helm-release.results.helm-url)
        - name: tools-image
          value: $(tasks.setup.results.tools-image)
      runAfter:
        - helm-release
      taskRef:
        kind: Task
        name: ibm-gitops-v2-7-7
`;

let manifest = `
apiVersion: tekton.dev/v1alpha1
kind: Task
metadata:
  name: manifest-${options.appName}
spec:
  params:
    - name: image-server
      default: "quay.io"
    - name: image-tag
      default: "latest"
    - name: image-namespace
    - name: image-repository
  steps:
  - name: build-step
    env:
      - name: REGISTRY_USER
        valueFrom:
          secretKeyRef:
            name: registry-access
            key: REGISTRY_USER
            optional: true
      - name: REGISTRY_PASSWORD
        valueFrom:
          secretKeyRef:
            name: registry-access
            key: REGISTRY_PASSWORD
            optional: true
    image: quay.io/buildah/stable:v1.18.0
    script: |
      APP_IMAGE="$(params.image-server)/$(params.image-namespace)/$(params.image-repository):$(params.image-tag)"
      X86_APP_IMAGE="$\{APP_IMAGE\}_x86_64"
      POWER_APP_IMAGE="$\{APP_IMAGE\}_ppc64le"
      Z_APP_IMAGE="$\{APP_IMAGE\}_s390x"

      buildah login -u "$REGISTRY_USER" -p "$REGISTRY_PASSWORD" "$(params.image-server)"
      echo "buildah login -u \"$REGISTRY_USER\" -p \"$REGISTRY_PASSWORD\" \"$(params.image-server)\""

      buildah manifest create $APP_IMAGE

      ${
        options.buildOnX86
          ? "buildah manifest add $APP_IMAGE docker://$X86_APP_IMAGE"
          : ""
      }
      ${
        options.buildOnPower
          ? "buildah manifest add $APP_IMAGE docker://$POWER_APP_IMAGE"
          : ""
      }
      ${
        options.buildOnZ
          ? "buildah manifest add $APP_IMAGE docker://$Z_APP_IMAGE"
          : ""
      }

      set -x
      buildah manifest push --all $APP_IMAGE docker://$APP_IMAGE
`;

let codeTest = `
apiVersion: tekton.dev/v1alpha1
kind: Task
metadata:
  name: code-test
spec:
  steps:
  - name: test
    image: quay.io/buildah/stable:v1.18.0
    script: |
      echo "Mock code test task"
`;

let pipelinePath = "";
let manifestTaskPath = "";
let codeTestTaskPath = "";

try {
  if (!fs.existsSync(`${process.env.HOME}/.mpt`)) {
    fs.mkdirSync(`${process.env.HOME}/.mpt`);
  }
  if (!fs.existsSync(`${process.env.HOME}/.mpt/applied-pipelines`)) {
    fs.mkdirSync(`${process.env.HOME}/.mpt/applied-pipelines`);
  }
  if (!fs.existsSync(`${process.env.HOME}/.mpt/applied-pipelines/tasks`)) {
    fs.mkdirSync(`${process.env.HOME}/.mpt/applied-pipelines/tasks`);
  }

  pipelinePath = `${process.env.HOME}/.mpt/applied-pipelines/pipeline-to-apply-${options.appName}.yaml`;
  manifestTaskPath = `${process.env.HOME}/.mpt/applied-pipelines/manifest-${options.appName}.yaml`;
  codeTestTaskPath = `${process.env.HOME}/.mpt/applied-pipelines/code-test.yaml`;

  fs.writeFileSync(pipelinePath, pipeline);
  fs.writeFileSync(manifestTaskPath, manifest);
  fs.writeFileSync(codeTestTaskPath, codeTest);
} catch (e) {
  console.log("Error writing pipeline/task files");
  process.exit(1);
}

const applyPipelineCMD = `
oc apply -f ${codeTestTaskPath}
oc apply -f ${manifestTaskPath}
oc apply -f ${pipelinePath}
`;

const runPipelineCMD = `
tkn pipeline start ${pipelineName} --use-param-defaults ${
  DO_BUILD_ON_X86 ? `--param x86-server-url=${options.apiServerX86}` : ""
} ${
  DO_BUILD_ON_POWER ? `--param power-server-url=${options.apiServerPower}` : ""
} ${
  DO_BUILD_ON_Z ? `--param z-server-url=${options.apiServerZ}` : ""
} --param health-protocol=${options.healthProtocol} --param git-url=${
  options.gitUrl
} --param image-server=${options.imageRegistry} --param image-namespace=${
  options.namespace
}`;

exec(applyPipelineCMD, { cwd: options.projectDir }, (err, stdout, stderr) => {
  if (err) {
    console.error(err);
    return;
  }
  console.log(stdout);
});

exec(runPipelineCMD, { cwd: options.projectDir }, (err, stdout, stderr) => {
  if (err) {
    console.error(err);
    return;
  }
  console.log(stdout);
});
