module "clis" {
  source  = "github.com/cloud-native-toolkit/terraform-util-clis.git"
  clis    = ["igc", "oc"]
  bin_dir = "bin"
}

resource "github_repository" "gitops-repo" {
  name        = "${var.project-name}-gitops"
  description = "Gitops for the ${var.project-name} project."

  visibility = "public"

  template {
    owner      = "IBM"
    repository = "template-argocd-gitops"
  }
}

resource "github_repository_collaborator" "gitops-repo-collaborator" {
  depends_on = [
    github_repository.gitops-repo
  ]
  repository = github_repository.gitops-repo.name
  username   = var.github-user
  permission = "admin"
}

resource "github_branch" "test-branch" {
  depends_on = [
    github_repository.gitops-repo
  ]
  repository = github_repository.gitops-repo.name
  branch     = "test"
}

resource "github_branch" "prod-branch" {
  depends_on = [
    github_repository.gitops-repo
  ]
  repository = github_repository.gitops-repo.name
  branch     = "prod"
}

resource "github_branch_default" "default-branch-test" {
  depends_on = [
    github_repository.gitops-repo,
    github_branch.test-branch,
    github_branch.prod-branch
  ]

  repository = github_repository.gitops-repo.name
  branch     = "test"
}

resource "null_resource" "git-clone-tekton-tasks-repo" {
  # TODO Change to garage org git repo
  provisioner "local-exec" {
    command = "git clone -b multiarch-pipeline https://github.com/aminerachyd/ibm-garage-tekton-tasks"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ibm-garage-tekton-tasks"
  }
}


module "z-cluster" {
  depends_on = [
    module.clis,
    null_resource.git-clone-tekton-tasks-repo,
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
    module.clis,
    module.z-cluster,
    null_resource.git-clone-tekton-tasks-repo,
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
    module.clis,
    module.x86-cluster,
    null_resource.git-clone-tekton-tasks-repo,
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
    module.clis,
    null_resource.git-clone-tekton-tasks-repo,
  ]
  x86-module-name    = "x86-cluster"
  z-module-name      = "z-cluster"
  power-module-name  = "power-cluster"
  x86-cluster-host   = var.x86-cluster-host
  z-cluster-host     = var.z-cluster-host
  power-cluster-host = var.power-cluster-host
  cluster-host       = var.dev-cluster-host
  cluster-token      = var.dev-cluster-token
  registry-user      = var.registry-user
  registry-token     = var.registry-token
  gitops-repo        = github_repository.gitops-repo.html_url
  github-user        = "ibm-ecosystem-lab"
  github-token       = var.github-token
  providers = {
    kubernetes.cluster-context = kubernetes.dev-cluster
  }
}

module "multiarch-pipelines" {
  depends_on = [
    module.dev-cluster,
    null_resource.git-clone-tekton-tasks-repo,
  ]
  source                = "./module/dev-cluster/multiarch-pipelines"
  gitops-repo           = github_repository.gitops-repo.html_url
  github-user           = "ibm-ecosystem-lab"
  github-token          = var.github-token
  project-name          = var.project-name
  x86-cluster-host      = var.x86-cluster-host
  z-cluster-host        = var.z-cluster-host
  power-cluster-host    = var.power-cluster-host
  image-namespace       = var.image-namespace
  image-server          = var.image-server
  smee-client           = var.smee-client
  frontendservice       = var.frontendservice
  productcatalogservice = var.productcatalogservice
  cartservice           = var.cartservice
  shippingservice       = var.shippingservice
  checkoutservice       = var.checkoutservice
  recommendationservice = var.recommendationservice
  paymentservice        = var.paymentservice
  emailservice          = var.emailservice
  currencyservice       = var.currencyservice
}

