const { exec } = require("child_process");

const fs = require("fs");

module.exports = createPipeline = ({
  pipelineName,
  apiServerPower,
  apiServerX86,
  apiServerZ,
  gitUrl,
  imageRegistry,
  healthProtocol,
  namespace,
  buildNamespace,
  buildOnX86,
  buildOnPower,
  buildOnZ,
  appName,
}) => {
  // Pipeline template
  const pipeline = `
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
    - description: The namespace in the builder clusters on which you want to build your image
      name: build-namespace
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
      buildOnX86
        ? `
    - name: x86-server-url
      description: "X86 cluster API server for multiarch build"
     `
        : ""
    }
    ${
      buildOnPower
        ? `
    - name: power-server-url
      description: "Power cluster API server for multiarch build"
     `
        : ""
    }
    ${
      buildOnZ
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
      buildOnX86
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
          value: $(params.build-namespace)
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
      buildOnPower
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
          value: $(params.build-namespace)
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
      buildOnZ
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
          value: $(params.build-namespace)
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
        name: manifest-${appName}
      runAfter:
        ${buildOnX86 ? `- build-x86` : ""}
        ${buildOnPower ? `- build-power` : ""}
        ${buildOnZ ? `- build-z` : ""}
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
        - name: image-tag
          value: $(tasks.simver.results.tag)
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

  // Create the pipeline file and write it to the directory
  const path = `${process.env.HOME}/.mpt/applied-pipelines/pipeline-to-apply-${appName}.yaml`;
  try {
    fs.writeFile(path, pipeline, (err) => {
      if (err) {
        throw err;
      }
    });
  } catch (error) {
    const errmsg = `Failed to write pipeline file: ${error}`;
    throw new Error(errmsg);
  }

  // Apply the pipeline command
  const applyCommand = `oc apply -f ${path} -n ${buildNamespace}`;
  // Run the pipeline command
  const tknCommand = `tkn pipeline start ${pipelineName} --use-param-defaults ${
    buildOnX86 ? `--param x86-server-url=${apiServerX86}` : ""
  } ${buildOnPower ? `--param power-server-url=${apiServerPower}` : ""} ${
    buildOnZ ? `--param z-server-url=${apiServerZ}` : ""
  } --param health-protocol=${healthProtocol} --param git-url=${gitUrl} --param image-server=${imageRegistry} --param image-namespace=${namespace} --param build-namespace=${buildNamespace} -n ${buildNamespace}`;

  exec(applyCommand, (err, stdout, stderr) => {
    if (err) {
      throw err;
    }
    console.log(stdout);

    exec(tknCommand, (err, stdout, stderr) => {
      if (err) {
        throw err;
      }
      console.log(stdout);
    });
  });
};
