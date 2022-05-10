const { exec } = require("child_process");

const fs = require("fs");

module.exports = createCodeTestTask = () => {
  // Task template
  const codeTest = `
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

  // Create the task file and write it to the directory
  const path = `${process.env.HOME}/.mpt/applied-pipelines/tasks/code-test.yaml`;
  try {
    fs.writeFileSync(path, codeTest);
  } catch (error) {
    const errmsg = `Failed to write manifest task file: ${error}`;
    throw new Error(errmsg);
  }

  // Apply the pipeline
  const applyCommand = `oc apply -f ${path}`;
  exec(applyCommand, (err, stdout, stderr) => {
    if (err) {
      throw err;
    }
    console.log(stdout);
  });
};
