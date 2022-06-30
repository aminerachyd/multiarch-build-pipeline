terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

resource "kubectl_manifest" "trigger-binding" {
  yaml_body = <<YAML
apiVersion: triggers.tekton.dev/v1alpha1
kind: TriggerBinding
metadata:
  name: trigger-binding
  namespace: ${var.project-name}-dev
  labels:
    app: trigger-binding
spec:
  params:
    - name: gitrevision
      value: $(body.head_commit.id)
    - name: gitrepositoryurl
      value: $(body.repository.url)
YAML
}



module "cartservice-pipelinerun" {

  source              = "./multiarch-pipelinerun"
  app-name            = "cartservice"
  gitops-repo         = var.gitops-repo
  git-url             = var.cartservice
  github-user         = var.github-user
  github-token        = var.github-token
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  destination-cluster = "topaz"
  project-name        = var.project-name
}

module "emailservice-pipelinerun" {
  depends_on = [
    module.cartservice-pipelinerun
  ]

  source              = "./multiarch-pipelinerun"
  app-name            = "emailservice"
  gitops-repo         = var.gitops-repo
  git-url             = var.emailservice
  github-user         = var.github-user
  github-token        = var.github-token
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  build-on-power      = true
  destination-cluster = "opal"
  project-name        = var.project-name
}

module "recommendationservice-pipelinerun" {
  depends_on = [
    module.emailservice-pipelinerun
  ]

  source              = "./multiarch-pipelinerun"
  app-name            = "recommendationservice"
  gitops-repo         = var.gitops-repo
  git-url             = var.recommendationservice
  github-user         = var.github-user
  github-token        = var.github-token
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  build-on-power      = true
  destination-cluster = "opal"
  project-name        = var.project-name
}

module "productcatalogservice-pipelinerun" {
  depends_on = [
    module.recommendationservice-pipelinerun
  ]

  source              = "./multiarch-pipelinerun"
  app-name            = "productcatalogservice"
  gitops-repo         = var.gitops-repo
  git-url             = var.productcatalogservice
  github-user         = var.github-user
  github-token        = var.github-token
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  build-on-z          = true
  build-on-power      = true
  destination-cluster = "diamond"
  project-name        = var.project-name
}

module "shippingservice-pipelinerun" {
  depends_on = [
    module.productcatalogservice-pipelinerun
  ]

  source              = "./multiarch-pipelinerun"
  app-name            = "shippingservice"
  gitops-repo         = var.gitops-repo
  git-url             = var.shippingservice
  github-user         = var.github-user
  github-token        = var.github-token
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  build-on-z          = true
  build-on-power      = true
  destination-cluster = "topaz"
  project-name        = var.project-name
}

module "currencyservice-pipelinerun" {
  depends_on = [
    module.shippingservice-pipelinerun
  ]

  source              = "./multiarch-pipelinerun"
  app-name            = "currencyservice"
  gitops-repo         = var.gitops-repo
  git-url             = var.currencyservice
  github-user         = var.github-user
  github-token        = var.github-token
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  build-on-z          = true
  build-on-power      = true
  destination-cluster = "topaz"
  project-name        = var.project-name
}

module "paymentservice-pipelinerun" {
  depends_on = [
    module.currencyservice-pipelinerun
  ]

  source              = "./multiarch-pipelinerun"
  app-name            = "paymentservice"
  gitops-repo         = var.gitops-repo
  git-url             = var.paymentservice
  github-user         = var.github-user
  github-token        = var.github-token
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  build-on-z          = true
  build-on-power      = true
  destination-cluster = "diamond"
  project-name        = var.project-name
}

module "checkoutservice-pipelinerun" {
  depends_on = [
    module.paymentservice-pipelinerun
  ]

  source              = "./multiarch-pipelinerun"
  app-name            = "checkoutservice"
  gitops-repo         = var.gitops-repo
  git-url             = var.checkoutservice
  github-user         = var.github-user
  github-token        = var.github-token
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  build-on-z          = true
  build-on-power      = true
  destination-cluster = "diamond"
  project-name        = var.project-name
}

module "frontend-pipelinerun" {
  depends_on = [
    module.checkoutservice-pipelinerun
  ]

  source              = "./multiarch-pipelinerun"
  app-name            = "frontend"
  gitops-repo         = var.gitops-repo
  git-url             = var.frontendservice
  github-user         = var.github-user
  github-token        = var.github-token
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "https"
  build-on-x86        = true
  build-on-z          = true
  build-on-power      = true
  destination-cluster = "opal"
  project-name        = var.project-name
}

resource "kubectl_manifest" "smee-client" {
  depends_on = [
    module.frontend-pipelinerun
  ]

  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: smee-client
  namespace: ${var.project-name}-dev
  labels:
    app: smee-client
spec:
  replicas: 1 
  selector:
    matchLabels:
      app: smee-client
  template:
    metadata:
      labels:
        app: smee-client
    spec:
      containers:
        - name: smee-client
          image: quay.io/schabrolles/smeeclient
          env:
            - name: SMEESOURCE
              value: "${var.smee-client}"
            - name: HTTPTARGET
              value: "http://el-event-listener:8080"
            - name: NODE_TLS_REJECT_UNAUTHORIZED
              value: "0"
YAML
}
