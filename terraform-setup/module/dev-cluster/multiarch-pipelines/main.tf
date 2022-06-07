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
  git-url             = "https://github.com/aminerachyd/frontend"
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
  git-url             = "https://github.com/aminerachyd/cartservice"
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
  git-url             = "https://github.com/aminerachyd/emailservice"
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
  git-url             = "https://github.com/aminerachyd/recommendationservice"
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
  git-url             = "https://github.com/aminerachyd/productcatalogservice"
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
  git-url             = "https://github.com/aminerachyd/shippingservice"
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
  git-url             = "https://github.com/aminerachyd/currencyservice"
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
  git-url             = "https://github.com/aminerachyd/paymentservice"
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
  git-url             = "https://github.com/aminerachyd/checkoutservice"
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
