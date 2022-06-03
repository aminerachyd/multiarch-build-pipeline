terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

resource "kubectl_manifest" "pipelinerun" {
  yaml_body = <<YAML
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: multiarch-build-${var.app-name}
  namespace: ${var.project-name}-dev
  labels:
    tekton.dev/pipeline: multiarch-build-pipeline
spec:
  params:
    - name: git-url
      value: ${var.git-url}
    - name: git-revision
      value: ${var.git-revision}
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
    - name: x86-server-url
      value: ${var.x86-server-url}
    - name: power-server-url
      value: ${var.power-server-url}
    - name: z-server-url
      value: ${var.z-server-url}
  pipelineRef:
    name: multiarch-build-pipeline
  serviceAccountName: pipeline
  timeout: 1h0m0s
YAML
}

resource "kubectl_manifest" "argo-app-test" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${var.app-name}-test-${var.project-name}
  namespace: openshift-gitops
  labels:
    env: test
    project : ${var.project-name}
spec:
  destination:
    name: ${var.destination-cluster}
    namespace: ${var.project-name}-test
  project: online-boutique
  source:
    helm:
      parameters:
      - name: ${var.app-name}.namespaceToDeploy
        value: ${var.project-name}-test
    path: ${var.app-name}
    repoURL: https://github.com/aminerachyd/multiarch-build-gitops.git
    targetRevision: test
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - PruneLast=true
YAML
}

resource "kubectl_manifest" "argo-app-prod" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${var.app-name}-prod-${var.project-name}
  namespace: openshift-gitops
  labels:
    env: prod
    project : ${var.project-name}
spec:
  destination:
    name: ${var.destination-cluster}
    namespace: ${var.project-name}-prod
  project: online-boutique
  source:
    helm:
      parameters:
      - name: ${var.app-name}.namespaceToDeploy
        value: ${var.project-name}-prod
    path: ${var.app-name}
    repoURL: https://github.com/aminerachyd/multiarch-build-gitops.git
    targetRevision: prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - PruneLast=true
YAML
}

