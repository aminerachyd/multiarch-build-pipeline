terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      configuration_aliases = [
        kubernetes.cluster-context
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

# Create test project
resource "kubernetes_namespace" "test-project" {
  provider = kubernetes.cluster-context
  metadata {
    name = "${var.project-name}-test"
  }
}

# Create prod project
resource "kubernetes_namespace" "prod-project" {
  provider = kubernetes.cluster-context
  metadata {
    name = "${var.project-name}-prod"
  }
}

# Create cluster role pipeline starter
resource "kubernetes_cluster_role" "pipeline-starter" {
  provider = kubernetes.cluster-context
  metadata {
    name = "${var.project-name}-pipeline-starter"
  }
  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods/log"]
    verbs      = ["get"]
  }
  rule {
    api_groups = ["tekton.dev"]
    resources  = ["pipelines"]
    verbs      = ["get"]
  }
  rule {
    api_groups = ["tekton.dev"]
    resources  = ["pipelineresources"]
    verbs      = ["list"]
  }
  rule {
    api_groups = ["tekton.dev"]
    resources  = ["pipelinereruns"]
    verbs      = ["create", "get", "list", "watch"]
  }
  rule {
    api_groups = ["tekton.dev"]
    resources  = ["taskruns"]
    verbs      = ["get"]
  }
}

# Create role binding for pipeline starter
resource "kubernetes_role_binding" "pipeline-starter" {
  provider = kubernetes.cluster-context
  metadata {
    name      = kubernetes_cluster_role.pipeline-starter.metadata[0].name
    namespace = kubernetes_namespace.dev-project.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.pipeline-starter.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_cluster_role.pipeline-starter.metadata[0].name
    namespace = kubernetes_namespace.dev-project.metadata[0].name
  }

}

# Create pipeline starter service account
resource "kubernetes_service_account" "pipeline-starter" {
  provider = kubernetes.cluster-context
  metadata {
    name      = kubernetes_cluster_role.pipeline-starter.metadata[0].name
    namespace = kubernetes_namespace.dev-project.metadata[0].name
  }
}

# Get token for pipeline starter service account
output "pipeline-starter-token" {
  value = kubernetes_service_account.pipeline-starter.secret
}
