module "z-cluster" {
  source       = "./module/workload-cluster"
  project-name = var.project-name
  providers = {
    kubernetes.cluster-context = kubernetes.z-cluster
  }
}

module "x86-cluster" {
  source       = "./module/workload-cluster"
  project-name = var.project-name
  providers = {
    kubernetes.cluster-context = kubernetes.x86-cluster
  }
}

module "power-cluster" {
  source       = "./module/workload-cluster"
  project-name = var.project-name
  providers = {
    kubernetes.cluster-context = kubernetes.power-cluster
  }
}

module "dev-cluster" {
  source       = "./module/dev-cluster"
  project-name = var.project-name
  providers = {
    kubernetes.cluster-context = kubernetes.dev-cluster
  }
}

# Fetch secret outputs from workload clusters
output "z-cluster-secret" {
  value = module.z-cluster.pipeline-starter-token
}

output "x86-cluster-secret" {
  value = module.x86-cluster.pipeline-starter-token
}

output "power-cluster-secret" {
  value = module.power-cluster.pipeline-starter-token
}