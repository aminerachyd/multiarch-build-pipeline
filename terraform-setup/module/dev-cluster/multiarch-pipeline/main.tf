terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      configuration_aliases = [
        kubernetes.cluster-context,
      ]
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

# TODO Update the pipeline, introduce tasks
resource "kubectl_manifest" "pipeline" {
  yaml_body = <<YAML
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: ${var.pipeline-name}
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
    default: "false"
  - name: lint-dockerfile
    description: Enable the pipeline to lint the Dockerfile for best practices
    default: "false"
  - name: health-protocol
    description: Protocol to check health after deployment, either https or grpc, defaults to grpc
    default: grpc
  - name: health-endpoint
    description: Endpoint to check health after deployment, defaults to /
    default: /
  - name: build-on-x86
    description: Boolean flag to enable building on x86 cluster
    default: "false"
  - name: build-on-power
    description: Boolean flag to enable building on Power cluster
    default: "false"
  - name: build-on-z
    description: Boolean flag to enable building on Z cluster
    default: "false"
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
    - name: health-endpoint
      value: $(params.health-endpoint)
    taskRef:
      name: ibm-setup-v2-7-8
YAML
}
