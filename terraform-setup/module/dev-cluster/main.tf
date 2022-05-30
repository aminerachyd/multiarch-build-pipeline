terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
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