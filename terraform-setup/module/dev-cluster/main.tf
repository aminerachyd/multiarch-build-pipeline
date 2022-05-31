terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      configuration_aliases = [
        kubernetes.cluster-context,
      ]
    }
  }
}

# Create dev project
resource "kubernetes_namespace" "dev-project" {
  provider = kubernetes.cluster-context
  metadata {
    name = "${var.project-name}-dev"
  }
}

# Create secrets using tokens from workload clusters
resource "kubernetes_secret" "z-cluster-token" {
  provider = kubernetes.cluster-context
  metadata {
    # TODO Change the name of the appropriate secret for the demo
    name      = "${var.project-name}-z-cluster-token"
    namespace = "${var.project-name}-dev"
  }
  # TODO Fetch token from the appropriate file
  # binary_data = {
  #   openshift-token = var.z-cluster-token
  # }
}
