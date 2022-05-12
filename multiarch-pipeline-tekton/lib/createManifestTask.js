const { exec } = require("child_process");

const fs = require("fs");

module.exports = createManifestTask = ({
  buildOnX86,
  buildOnPower,
  buildOnZ,
  buildNamespace,
  appName,
}) => {
  // Task template
  const manifest = `
apiVersion: tekton.dev/v1alpha1
kind: Task
metadata:
  name: manifest-${appName}
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
        buildOnX86
          ? "buildah manifest add $APP_IMAGE docker://$X86_APP_IMAGE"
          : ""
      }
      ${
        buildOnPower
          ? "buildah manifest add $APP_IMAGE docker://$POWER_APP_IMAGE"
          : ""
      }
      ${buildOnZ ? "buildah manifest add $APP_IMAGE docker://$Z_APP_IMAGE" : ""}

      set -x
      buildah manifest push --all $APP_IMAGE docker://$APP_IMAGE
`;

  // Create the task file and write it to the directory
  const path = `${process.env.HOME}/.mpt/applied-pipelines/tasks/manifest-${appName}.yaml`;
  try {
    fs.writeFileSync(path, manifest);
  } catch (error) {
    const errmsg = `Failed to write manifest task file: ${error}`;
    throw new Error(errmsg);
  }

  // Apply the pipeline
  const applyCommand = `oc apply -f ${path} -n ${buildNamespace}`;
  exec(applyCommand, (err, stdout, stderr) => {
    if (err) {
      throw err;
    }
    console.log(stdout);
  });
};
