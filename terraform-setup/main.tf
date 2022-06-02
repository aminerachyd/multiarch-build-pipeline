module "clis" {
  source  = "github.com/cloud-native-toolkit/terraform-util-clis.git"
  clis    = ["igc", "oc"]
  bin_dir = "bin"
}

module "z-cluster" {
  depends_on = [
    module.clis
  ]
  source         = "./module/workload-cluster"
  project-name   = var.project-name
  cluster-host   = var.z-cluster-host
  cluster-token  = var.z-cluster-token
  registry-user  = var.registry-user
  registry-token = var.registry-token
  module-name    = "z-cluster"
  providers = {
    kubernetes.cluster-context = kubernetes.z-cluster
  }
}

module "x86-cluster" {
  depends_on = [
    module.clis
  ]
  source         = "./module/workload-cluster"
  project-name   = var.project-name
  cluster-host   = var.x86-cluster-host
  cluster-token  = var.x86-cluster-token
  registry-user  = var.registry-user
  registry-token = var.registry-token
  module-name    = "x86-cluster"
  providers = {
    kubernetes.cluster-context = kubernetes.x86-cluster
  }
}

module "power-cluster" {
  depends_on = [
    module.clis
  ]
  source         = "./module/workload-cluster"
  project-name   = var.project-name
  cluster-host   = var.power-cluster-host
  cluster-token  = var.power-cluster-token
  registry-user  = var.registry-user
  registry-token = var.registry-token
  module-name    = "power-cluster"
  providers = {
    kubernetes.cluster-context = kubernetes.power-cluster
  }
}

module "dev-cluster" {
  source       = "./module/dev-cluster"
  project-name = var.project-name
  # Depends on the file
  depends_on = [
    module.x86-cluster,
    module.z-cluster,
    module.power-cluster,
    module.clis
  ]
  x86-module-name   = "x86-cluster"
  z-module-name     = "z-cluster"
  power-module-name = "power-cluster"
  cluster-host      = var.dev-cluster-host
  cluster-token     = var.dev-cluster-token
  registry-user     = var.registry-user
  registry-token    = var.registry-token
  gitops-repo       = var.gitops-repo
  git-user          = var.git-user
  git-token         = var.git-token
  providers = {
    kubernetes.cluster-context = kubernetes.dev-cluster
  }
}

module "multiarch-pipeline" {
  depends_on = [
    module.dev-cluster
  ]
  source             = "./module/dev-cluster/multiarch-pipeline"
  project-name       = var.project-name
  x86-cluster-host   = var.x86-cluster-host
  z-cluster-host     = var.z-cluster-host
  power-cluster-host = var.power-cluster-host
}

