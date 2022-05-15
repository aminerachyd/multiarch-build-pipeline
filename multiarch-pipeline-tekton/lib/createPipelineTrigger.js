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

// TODO Create a github webhook for the pipeline
// Update the eventlistener to be able to handle multiple events from different repositories
module.exports = createPipelineTrigger = ({
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
  // Create the triggerbinding file and write it to the directory
  const triggerBindingPath = `${process.env.HOME}/.mpt/applied-pipelines/triggers/triggerbinding.yaml`;
  const triggerTemplatePath = `${process.env.HOME}/.mpt/applied-pipelines/triggers/triggerTemplate-${appName}.yaml`;
  const eventListenerPath = `${process.env.HOME}/.mpt/applied-pipelines/triggers/eventListener.yaml`;

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
                header.match('X-GitHub-Event', 'push') && body.repository.full_name ==
                '${namespace}/${appName}'
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
        generateName: ${appName}-multiarch-pipeline-run-
      spec:
        params:
          - name: git-url
            value: $(tt.params.gitrepositoryurl)
          - name: git-revision
            value: $(tt.params.gitrevision)
          - name: image-server
            value: ${imageRegistry}
          - name: image-namespace
            value: ${namespace}
          ${
            buildOnX86
              ? `
          - name: x86-server-url
            value: ${apiServerX86}
          `
              : ""
          }
          ${
            buildOnPower
              ? `
          - name: power-server-url
            value: ${apiServerPower}
          `
              : ""
          }
          ${
            buildOnZ
              ? `
          - name: z-server-url
            value: ${apiServerZ}
          `
              : ""
          }
          - name: health-protocol
            value: ${healthProtocol}
          - name: build-namespace
            value: ${buildNamespace}
        pipelineRef:
          name: ${pipelineName}
`;

  const pEventListener = {
    spec: {
      triggers: [
        {
          bindings: [
            {
              kind: "TriggerBinding",
              ref: "trigger-binding",
            },
          ],
          interceptors: [
            {
              params: [
                {
                  name: "filter",
                  value: `header.match('X-GitHub-Event', 'push') && body.ref == 'refs/heads/master' && body.repository.full_name == '${namespace}/${appName}'`,
                },
                {
                  name: "overlays",
                  value: null,
                },
              ],
              ref: {
                kind: "ClusterInterceptor",
                name: "cel",
              },
            },
          ],
          name: `${namespace}-${appName}-master`,
          template: {
            ref: `${appName}`,
          },
        },
      ],
    },
  };

  // If it exists, patch it with the new trigger
  try {
    fs.writeFileSync(triggerBindingPath, triggerBinding);
    fs.writeFileSync(triggerTemplatePath, triggerTemplate);
    fs.writeFileSync(eventListenerPath, eventListener);
    // fs.writeFileSync(patchEventListenerPath, pEventListener);
  } catch (error) {
    const errmsg = `Failed to write file: ${error}`;
    throw new Error(errmsg);
  }

  // Apply the files
  const applyTriggerBinding = `oc apply -f ${triggerBindingPath} -n ${buildNamespace}`;
  const applyTriggerTemplate = `oc apply -f ${triggerTemplatePath} -n ${buildNamespace}`;
  const applyEventListener = `oc apply -f ${eventListenerPath} -n ${buildNamespace}`;

  exec(applyTriggerBinding, (err, stdout, stderr) => {
    if (err) {
      throw err;
    }
    console.log(stdout);
  });

  // Check if the event listener exists on the cluster
  exec(
    `oc get eventlistener event-listener -o json -n ${buildNamespace}`,
    (err, stdout, stderr) => {
      if (err) {
        console.log("Event listener does not exist, creating one");
        exec(applyEventListener, (err, stdout, stderr) => {
          if (err) {
            throw err;
          }
          console.log(stdout);
        });
      } else {
        // Patch the event listener
        console.log("Event listener exists, patching it");
        const existingEventListener = JSON.parse(stdout);
        const newTriggers = [
          ...[...existingEventListener.spec.triggers].filter(
            (trigger) => trigger.name !== `${namespace}-${appName}-master`
          ),
          ...pEventListener.spec.triggers,
        ];

        const newEventListener = {
          ...existingEventListener,
          spec: {
            ...existingEventListener.spec,
            triggers: newTriggers,
          },
        };
        fs.writeFileSync(eventListenerPath, JSON.stringify(newEventListener));
        const patchEventListener = `oc apply -f ${eventListenerPath} -n ${buildNamespace}`;
        // Create patch file with the new trigger
        exec(patchEventListener, (err, stdout, stderr) => {
          if (err) {
            throw err;
          }
          console.log(stdout);
        });
      }
    }
  );

  exec(applyTriggerTemplate, (err, stdout, stderr) => {
    if (err) {
      throw err;
    }
    console.log(stdout);
  });
};
