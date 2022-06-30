terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

resource "null_resource" "igc-pipeline" {
  provisioner "local-exec" {
    command = "BINPATH=\"bin\" && ./$BINPATH/igc pipeline ${var.git-url} --username ${var.github-user} --password ${var.github-token} --pipeline ibm-general-multiarch --param image-server=${var.image-server} --param image-namespace=${var.image-namespace} --param scan-image=${var.scan-image} --param lint-dockerfile=${var.lint-dockerfile} --param health-protocol=${var.health-protocol} --param health-endpoint=${var.health-endpoint} --param build-on-x86=${var.build-on-x86} --param build-on-power=${var.build-on-power} --param build-on-z=${var.build-on-z} --tekton"
  }
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
      - name: ${var.app-name}.submariner.enabled
        value: "true"
    path: ${var.app-name}
    repoURL: ${var.gitops-repo}
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
      - name: ${var.app-name}.submariner.enabled
        value: "true"
    path: ${var.app-name}
    repoURL: ${var.gitops-repo}
    targetRevision: prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - PruneLast=true
YAML
}

module "pipeline-trigger" {
  depends_on = [
    # kubectl_manifest.pipeline
    null_resource.igc-pipeline
  ]
  source          = "./pipeline-trigger"
  app-name        = var.app-name
  github-user     = "ibm-ecosystem-lab"
  image-namespace = var.image-namespace
  image-server    = var.image-server
  health-protocol = var.health-protocol
  build-on-x86    = var.build-on-x86
  build-on-z      = var.build-on-z
  build-on-power  = var.build-on-power
  project-name    = var.project-name
}
