terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}


resource "kubectl_manifest" "trigger-template" {
  yaml_body = <<YAML
apiVersion: triggers.tekton.dev/v1alpha1
kind: TriggerTemplate
metadata:
  labels: 
    app: ${var.app-name}
  namespace: ${var.project-name}-dev
  name: ${var.app-name}
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
        generateName: ${var.app-name}-
        namespace: ${var.project-name}-dev
        labels:
          tekton.dev/pipeline: ${var.app-name}
      spec:
        params:
          - name: git-url
            value: $(tt.params.gitrepositoryurl)
          - name: git-revision
            value: $(tt.params.gitrevision)
          - name: image-server
            value: ${var.image-server}
          - name: image-namespace
            value: ${var.image-namespace}
          - name: build-namespace
            value: ${var.project-name}-dev
          - name: scan-image
            value: '${var.scan-image}'
          - name: lint-dockerfile
            value: '${var.lint-dockerfile}'
          - name: health-protocol
            value: '${var.health-protocol}'
          - name: health-endpoint
            value: ${var.health-endpoint}
          - name: build-on-x86
            value: '${var.build-on-x86}'
          - name: build-on-power
            value: '${var.build-on-power}'
          - name: build-on-z
            value: '${var.build-on-z}'
        pipelineRef:
          name: ${var.app-name}
        serviceAccountName: pipeline
YAML
}

resource "null_resource" "event-listener" {
  depends_on = [kubectl_manifest.trigger-template]

  # Create event listener if it doesn't exist, patch it if it does
  provisioner "local-exec" {
    command = <<EOF
BINPATH=bin
$BINPATH/kubectl get eventlistener event-listener -n ${var.project-name}-dev
EXIT_CODE=$?

# Test exit code
if [ $EXIT_CODE -eq 0 ]; then
  $BINPATH/kubectl patch eventlistener/event-listener -n ${var.project-name}-dev --type=json -p '[{"op":"add","path":"/spec/triggers/-","value":{"bindings":[{"kind":"TriggerBinding","ref":"trigger-binding"}],"interceptors":[{"params":[{"name":"filter","value": "header.match('"'"'X-GitHub-Event'"'"', '"'"'push'"'"') && body.ref == '"'"'refs/heads/master'"'"' && body.repository.full_name == '"'"'${var.github-user}/${var.app-name}'"'"'"},{"name":"overlays","value":null}],"ref":{"kind":"ClusterInterceptor","name":"cel"}}],"name":"${var.project-name}-dev-${var.app-name}-master","template":{"ref":"${var.app-name}"}}}]'
else
  cat << YAML | $BINPATH/kubectl apply -f -
  apiVersion: triggers.tekton.dev/v1alpha1
  kind: EventListener
  metadata:
    name: event-listener
    labels:
      app: event-listener
    namespace: ${var.project-name}-dev
  spec:
    triggers:
    - bindings:
      - kind: TriggerBinding
        ref: trigger-binding
      interceptors:
      - params:
        - name: filter
          value: header.match('X-GitHub-Event', 'push') && body.ref == 'refs/heads/master' && body.repository.full_name == '${var.github-user}/${var.app-name}'
        - name: overlays
          value: null
        ref:
          kind: ClusterInterceptor
          name: cel
      name: ${var.project-name}-dev-${var.app-name}-master
      template:
        ref: ${var.app-name}
YAML
fi
EOF
  }
}
