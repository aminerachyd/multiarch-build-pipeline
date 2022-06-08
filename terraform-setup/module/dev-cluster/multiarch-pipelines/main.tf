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


module "frontend-pipelinerun" {
  source              = "./multiarch-pipelinerun"
  app-name            = "frontend"
  git-url             = var.frontendservice
  git-user            = var.git-user
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  build-on-z          = true
  build-on-power      = true
  destination-cluster = "diamond"
  x86-server-url      = var.x86-cluster-host
  z-server-url        = var.z-cluster-host
  project-name        = var.project-name
  power-server-url    = var.power-cluster-host
}

module "cartservice-pipelinerun" {
  depends_on = [
    module.frontend-pipelinerun
  ]

  source              = "./multiarch-pipelinerun"
  app-name            = "cartservice"
  git-url             = var.cartservice
  git-user            = var.git-user
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  destination-cluster = "topaz"
  project-name        = var.project-name
  x86-server-url      = var.x86-cluster-host
}

module "emailservice-pipelinerun" {
  depends_on = [
    module.cartservice-pipelinerun
  ]

  source              = "./multiarch-pipelinerun"
  app-name            = "emailservice"
  git-url             = var.emailservice
  git-user            = var.git-user
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  build-on-power      = true
  destination-cluster = "opal"
  x86-server-url      = var.x86-cluster-host
  project-name        = var.project-name
  power-server-url    = var.power-cluster-host
}

module "recommendationservice-pipelinerun" {
  depends_on = [
    module.emailservice-pipelinerun
  ]

  source              = "./multiarch-pipelinerun"
  app-name            = "recommendationservice"
  git-url             = var.recommendationservice
  git-user            = var.git-user
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  build-on-power      = true
  destination-cluster = "topaz"
  x86-server-url      = var.x86-cluster-host
  project-name        = var.project-name
  power-server-url    = var.power-cluster-host
}

module "productcatalogservice-pipelinerun" {
  depends_on = [
    module.recommendationservice-pipelinerun
  ]

  source              = "./multiarch-pipelinerun"
  app-name            = "productcatalogservice"
  git-url             = var.productcatalogservice
  git-user            = var.git-user
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  build-on-z          = true
  build-on-power      = true
  destination-cluster = "diamond"
  x86-server-url      = var.x86-cluster-host
  z-server-url        = var.z-cluster-host
  project-name        = var.project-name
  power-server-url    = var.power-cluster-host
}

module "shippingservice-pipelinerun" {
  depends_on = [
    module.productcatalogservice-pipelinerun
  ]

  source              = "./multiarch-pipelinerun"
  app-name            = "shippingservice"
  git-url             = var.shippingservice
  git-user            = var.git-user
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  build-on-z          = true
  build-on-power      = true
  destination-cluster = "diamond"
  x86-server-url      = var.x86-cluster-host
  z-server-url        = var.z-cluster-host
  project-name        = var.project-name
  power-server-url    = var.power-cluster-host
}

module "currencyservice-pipelinerun" {
  depends_on = [
    module.shippingservice-pipelinerun
  ]

  source              = "./multiarch-pipelinerun"
  app-name            = "currencyservice"
  git-url             = var.currencyservice
  git-user            = var.git-user
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  build-on-z          = true
  build-on-power      = true
  destination-cluster = "topaz"
  x86-server-url      = var.x86-cluster-host
  z-server-url        = var.z-cluster-host
  project-name        = var.project-name
  power-server-url    = var.power-cluster-host
}

module "paymentservice-pipelinerun" {
  depends_on = [
    module.currencyservice-pipelinerun
  ]

  source              = "./multiarch-pipelinerun"
  app-name            = "paymentservice"
  git-url             = var.paymentservice
  git-user            = var.git-user
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  build-on-z          = true
  build-on-power      = true
  destination-cluster = "opal"
  x86-server-url      = var.x86-cluster-host
  z-server-url        = var.z-cluster-host
  project-name        = var.project-name
  power-server-url    = var.power-cluster-host
}

module "checkoutservice-pipelinerun" {
  depends_on = [
    module.paymentservice-pipelinerun
  ]

  source              = "./multiarch-pipelinerun"
  app-name            = "checkoutservice"
  git-url             = var.checkoutservice
  git-user            = var.git-user
  image-namespace     = var.image-namespace
  image-server        = var.image-server
  health-protocol     = "grpc"
  build-on-x86        = true
  build-on-z          = true
  build-on-power      = true
  destination-cluster = "diamond"
  x86-server-url      = var.x86-cluster-host
  z-server-url        = var.z-cluster-host
  project-name        = var.project-name
  power-server-url    = var.power-cluster-host
}

resource "kubectl_manifest" "smee-client" {
  depends_on = [
    module.checkoutservice-pipelinerun
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
