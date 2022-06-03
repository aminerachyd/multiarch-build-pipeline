terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

resource "kubectl_manifest" "pipeline" {
  yaml_body = <<YAML
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: multiarch-build-pipeline
  namespace: ${var.project-name}-dev
spec:
  params:
  - name: git-url
    description: The url for the git repository
  - name: git-revision
    description: The git revision (branch, tag or sha) that shoulf be built
  - name: image-server
    description: Image registry to store the image in
  - name: image-namespace
    description: Image namespace in the registry (user or organisation)
  - name: build-namespace
    description: The namespace in the builder clusters on which you want to build your image
  - name: scan-image
    description: Enable the pipeline to scan the image for vulnerabilities
    default: 'false'
    type: string
  - name: lint-dockerfile
    description: Enable the pipeline to lint the Dockerfile for best practices
    default: 'false'
    type: string
  - name: health-protocol
    description: Protocol to check health after deployment, either https or grpc, defaults to grpc
    default: grpc
  - name: health-endpoint
    description: Endpoint to check health after deployment, defaults to /
    default: "/"
  - name: build-on-x86
    description: Boolean flag to enable building on x86 cluster
    default: 'false'
    type: string
  - name: build-on-power
    description: Boolean flag to enable building on Power cluster
    default: 'false'
    type: string
  - name: build-on-z
    description: Boolean flag to enable building on Z cluster
    default: 'false'
    type: string
  - name: x86-server-url
    description: X86 cluster API server
    default: ""
  - name: power-server-url
    description: Power cluster API server
    default: ""
  - name: z-server-url
    description: Z cluster API server
    default: ""
  tasks:
  - name: setup
    params:
    - name: git-url
      value: $(params.git-url)
    - name: git-revision
      value: $(params.git-revision)
    - name: image-server
      value: $(params.image-server)
    - name: image-namespace
      value: $(params.image-namespace)
    - name: scan-image
      value: $(params.scan-image)
    - name: lint-dockerfile
      value: $(params.lint-dockerfile)
    - name: health-protocol
      value: $(params.health-protocol)
    - name: health-endpoint
      value: $(params.health-endpoint)
    taskRef:
      name: ibm-setup-v2-7-8
  - name: code-test
    runAfter:
      - setup
    taskRef:
      kind: Task
      name: code-test
  - name: code-lint
    params:
      - name: git-url
        value: $(tasks.setup.results.git-url)
      - name: git-revision
        value: $(tasks.setup.results.git-revision)
      - name: source-dir
        value: $(tasks.setup.results.source-dir)
      - name: app-name
        value: $(tasks.setup.results.app-name)
    runAfter:
      - code-test
    taskRef:
      kind: Task
      name: ibm-sonar-test-v2-7-7
  - name: dockerfile-lint
    params:
      - name: git-url
        value: $(tasks.setup.results.git-url)
      - name: git-revision
        value: $(tasks.setup.results.git-revision)
      - name: source-dir
        value: $(tasks.setup.results.source-dir)
      - name: lint-dockerfile
        value: $(tasks.setup.results.dockerfile-lint)
    runAfter:
      - code-lint
    taskRef:
      kind: Task
      name: ibm-dockerfile-lint-v2-7-7
  - name: simver
    params:
      - name: git-url
        value: $(tasks.setup.results.git-url)
      - name: git-revision
        value: $(tasks.setup.results.git-revision)
      - name: source-dir
        value: $(tasks.setup.results.source-dir)
      - name: js-image
        value: $(tasks.setup.results.js-image)
      - name: skip-push
        value: "true"
    runAfter:
      - dockerfile-lint
    taskRef:
      kind: Task
      name: ibm-tag-release-v2-7-7
  - name: build-x86
    params:
      - name: git-url
        value: $(tasks.setup.results.git-url)
      - name: git-revision
        value: $(tasks.setup.results.git-revision)
      - name: image-server
        value: $(params.image-server)
      - name: image-namespace
        value: $(params.image-namespace)
      - name: image-repository
        value: $(tasks.setup.results.app-name)
      - name: image-tag
        value: $(tasks.simver.results.tag)
      - name: pipeline-name
        value: build-push
      - name: pipeline-namespace
        value: $(params.build-namespace)
      - name: openshift-server-url
        value: $(params.x86-server-url)
      - name: openshift-token-secret
        value: x86-cluster-secret
      - name: run-task
        value: $(params.build-on-x86)
    runAfter:
      - simver
    taskRef:
      kind: Task
      name: execute-remote-pipeline
  - name: build-power
    params:
      - name: git-url
        value: $(tasks.setup.results.git-url)
      - name: git-revision
        value: $(tasks.setup.results.git-revision)
      - name: image-server
        value: $(params.image-server)
      - name: image-namespace
        value: $(params.image-namespace)
      - name: image-repository
        value: $(tasks.setup.results.app-name)
      - name: image-tag
        value: $(tasks.simver.results.tag)
      - name: pipeline-name
        value: build-push
      - name: pipeline-namespace
        value: $(params.build-namespace)
      - name: openshift-server-url
        value: $(params.power-server-url)
      - name: openshift-token-secret
        value: power-cluster-secret
      - name: run-task
        value: $(params.build-on-power)
    runAfter:
      - simver
    taskRef:
      kind: Task
      name: execute-remote-pipeline
  - name: build-z
    params:
      - name: git-url
        value: $(tasks.setup.results.git-url)
      - name: git-revision
        value: $(tasks.setup.results.git-revision)
      - name: image-server
        value: $(params.image-server)
      - name: image-namespace
        value: $(params.image-namespace)
      - name: image-repository
        value: $(tasks.setup.results.app-name)
      - name: image-tag
        value: $(tasks.simver.results.tag)
      - name: pipeline-name
        value: build-push
      - name: pipeline-namespace
        value: $(params.build-namespace)
      - name: openshift-server-url
        value: $(params.z-server-url)
      - name: openshift-token-secret
        value: z-cluster-secret
      - name: run-task
        value: $(params.build-on-z)
    runAfter:
      - simver
    taskRef:
      kind: Task
      name: execute-remote-pipeline
  - name: manifest
    params:
      - name: image-server
        value: $(params.image-server)
      - name: image-namespace
        value: $(params.image-namespace)
      - name: image-repository
        value: $(tasks.setup.results.app-name)
      - name: image-tag
        value: $(tasks.simver.results.tag)
      - name: build-on-x86
        value: $(params.build-on-x86)
      - name: build-on-z
        value: $(params.build-on-z)
      - name: build-on-power
        value: $(params.build-on-power)
    runAfter:
      - build-x86
      - build-power
      - build-z
    taskRef:
      kind: Task
      name: manifest
  - name: deploy
    params:
      - name: git-url
        value: $(tasks.setup.results.git-url)
      - name: git-revision
        value: $(tasks.setup.results.git-revision)
      - name: source-dir
        value: $(tasks.setup.results.source-dir)
      - name: image-server
        value: $(tasks.setup.results.image-server)
      - name: image-namespace
        value: $(tasks.setup.results.image-namespace)
      - name: image-repository
        value: $(tasks.setup.results.image-repository)
      - name: image-tag
        value: $(tasks.simver.results.tag)
      - name: app-namespace
        value: $(tasks.setup.results.app-namespace)
      - name: app-name
        value: $(tasks.setup.results.app-name)
      - name: deploy-ingress-type
        value: $(tasks.setup.results.deploy-ingress-type)
      - name: tools-image
        value: $(tasks.setup.results.tools-image)
    runAfter:
      - manifest
    taskRef:
      kind: Task
      name: ibm-deploy-v2-7-7
  - name: health
    params:
      - name: app-namespace
        value: $(tasks.setup.results.app-namespace)
      - name: app-name
        value: $(tasks.setup.results.app-name)
      - name: deploy-ingress-type
        value: $(tasks.setup.results.deploy-ingress-type)
      - name: health-protocol
        value: $(tasks.setup.results.health-protocol)
      - name: health-endpoint
        value: $(tasks.setup.results.health-endpoint)
      - name: health-url
        value: $(tasks.setup.results.health-url)
      - name: health-curl
        value: $(tasks.setup.results.health-curl)
      - name: tools-image
        value: $(tasks.setup.results.tools-image)
    runAfter:
      - deploy
    taskRef:
      kind: Task
      name: ibm-health-check-v2-7-8
  - name: img-scan
    params:
      - name: image-url
        value: $(tasks.setup.results.image-server)/$(tasks.setup.results.image-namespace)/$(tasks.setup.results.image-repository):$(tasks.simver.results.tag)
      - name: scan-trivy
        value: $(tasks.setup.results.scan-trivy)
      - name: scan-ibm
        value: $(tasks.setup.results.scan-ibm)
    runAfter:
      - health
    taskRef:
      kind: Task
      name: ibm-img-scan-v2-7-7
  - name: tag-release
    params:
      - name: git-url
        value: $(tasks.setup.results.git-url)
      - name: git-revision
        value: $(tasks.setup.results.git-revision)
      - name: source-dir
        value: $(tasks.setup.results.source-dir)
      - name: js-image
        value: $(tasks.setup.results.js-image)
    runAfter:
      - img-scan
    taskRef:
      kind: Task
      name: ibm-tag-release-v2-7-7
  - name: helm-release
    params:
      - name: git-url
        value: $(tasks.setup.results.git-url)
      - name: git-revision
        value: $(tasks.setup.results.git-revision)
      - name: source-dir
        value: $(tasks.setup.results.source-dir)
      - name: image-url
        value: $(tasks.setup.results.image-url):$(tasks.simver.results.tag)
      - name: app-name
        value: $(tasks.setup.results.app-name)
      - name: deploy-ingress-type
        value: $(tasks.setup.results.deploy-ingress-type)
      - name: tools-image
        value: $(tasks.setup.results.tools-image)
      - name: image-tag
        value: $(tasks.simver.results.tag)
    runAfter:
      - tag-release
    taskRef:
      kind: Task
      name: ibm-helm-release-v2-7-7
  - name: gitops
    params:
      - name: app-name
        value: $(tasks.setup.results.app-name)
      - name: version
        value: $(tasks.simver.results.tag)
      - name: helm-url
        value: $(tasks.helm-release.results.helm-url)
      - name: tools-image
        value: $(tasks.setup.results.tools-image)
    runAfter:
      - helm-release
    taskRef:
      kind: Task
      name: ibm-gitops-v2-7-7
YAML
}

module "frontend-pipelinerun" {
  depends_on = [
    kubectl_manifest.pipeline
  ]
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
    kubectl_manifest.pipeline
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
    kubectl_manifest.pipeline
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
    kubectl_manifest.pipeline
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
    kubectl_manifest.pipeline
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
    kubectl_manifest.pipeline
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
    kubectl_manifest.pipeline
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
    kubectl_manifest.pipeline
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
    kubectl_manifest.pipeline
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
