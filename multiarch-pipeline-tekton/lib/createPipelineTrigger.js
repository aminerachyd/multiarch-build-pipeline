const fs = require("fs");
const { exec } = require("child_process");

const triggerBinding = `
apiVersion: triggers.tekton.dev/v1alpha1
kind: TriggerBinding
metadata:
  labels:
    app: trigger-binding
  name: trigger-binding
spec:
  params:
    - name: gitrevision
      value: $(body.head_commit.id)
    - name: gitrepositoryurl
      value: $(body.repository.url)
`;

// TODO
// Update the eventlistener to be able to handle multiple events from different repositories
module.exports = createPipelineTrigger = ({
  pipelineName,
  namespace,
  appName,
}) => {
  // Create the triggerbinding file and write it to the directory
  const triggerBindingPath = `${process.env.HOME}/.mpt/applied-pipelines/triggers/triggerbinding.yaml`;
  const eventListenerPath = `${process.env.HOME}/.mpt/applied-pipelines/triggers/eventListener.yaml`;
  const triggerTemplatePath = `${process.env.HOME}/.mpt/applied-pipelines/triggers/triggerTemplate-${appName}.yaml`;

  // Create the tekton event listener
  const eventListener = `
apiVersion: triggers.tekton.dev/v1alpha1
kind: EventListener
metadata:
  labels:
    app: event-listener
  name: event-listener
spec:
  serviceAccountName: pipeline
  triggers:
    - bindings:
      - kind: TriggerBinding
        ref: trigger-binding
      interceptors:
        - params:
          - name: filter
            value: >-
              header.match('X-GitHub-Event', 'push') && body.ref == 'refs/heads/master' && body.repository.full_name == '${namespace}/${appName}'
          - name: overlays
            value: null
          ref: 
            kind: ClusterInterceptor
            name: cel
      name: ${namespace}-${appName}-master
      template:
        ref: ${appName}
        
`;
  // Create the trigger template
  const triggerTemplate = `
apiVersion: triggers.tekton.dev/v1alpha1
kind: TriggerTemplate
metadata:
  labels:
    app: ${appName}
  name: ${appName}
spec:
  params:
    - name: gitrevision
      description: The git revision
    - name: gitrepositoryurl
      description: The git repository url
  resourcetemplates:
    - apiVersion: tekton.dev/v1beta1
      kind: PipelineRun
      metadata: 
        generateName: ${appName}-
      spec:
        params:
          - name: git-url
            value: $(tt.params.gitrepositoryurl)
          - name: git-revision
            value: $(tt.params.gitrevision)
        pipelineRef:
          name: ${pipelineName}
`;

  // If it exists, patch it with the new trigger
  try {
    fs.writeFileSync(triggerBindingPath, triggerBinding);
    fs.writeFileSync(eventListenerPath, eventListener);
    fs.writeFileSync(triggerTemplatePath, triggerTemplate);
  } catch (error) {
    const errmsg = `Failed to write file: ${error}`;
    throw new Error(errmsg);
  }

  // Apply the files
  const applyTriggerBinding = `oc apply -f ${triggerBindingPath}`;
  const applyEventListener = `oc apply -f ${eventListenerPath}`;
  const applyTriggerTemplate = `oc apply -f ${triggerTemplatePath}`;

  exec(applyTriggerBinding, (err, stdout, stderr) => {
    if (err) {
      throw err;
    }
    console.log(stdout);
  });

  exec(applyEventListener, (err, stdout, stderr) => {
    if (err) {
      throw err;
    }
    console.log(stdout);
  });

  exec(applyTriggerTemplate, (err, stdout, stderr) => {
    if (err) {
      throw err;
    }
    console.log(stdout);
  });
};
