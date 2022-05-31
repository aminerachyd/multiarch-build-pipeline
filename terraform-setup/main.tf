module "z-cluster" {
  source       = "./module/workload-cluster"
  project-name = var.project-name
  module-name  = "z-cluster"
  providers = {
    kubernetes.cluster-context = kubernetes.z-cluster
  }
}

module "x86-cluster" {
  source       = "./module/workload-cluster"
  project-name = var.project-name
  module-name  = "x86-cluster"
  providers = {
    kubernetes.cluster-context = kubernetes.x86-cluster
  }
}

module "power-cluster" {
  source       = "./module/workload-cluster"
  project-name = var.project-name
  module-name  = "power-cluster"
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
