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

module "clusters-setup" {
  source = "github.com/ibm-ecosystem-lab/multiarch-build-clusters-setup"

  project-name = var.project-name

  dev-cluster-host   = var.dev-cluster-host
  x86-cluster-host   = var.x86-cluster-host
  power-cluster-host = var.power-cluster-host
  z-cluster-host     = var.z-cluster-host

  dev-cluster-token   = var.dev-cluster-token
  x86-cluster-token   = var.x86-cluster-token
  power-cluster-token = var.power-cluster-token
  z-cluster-token     = var.z-cluster-token

  registry-user   = var.registry-user
  registry-token  = var.registry-token
} 

resource "null_resource" "igc-gitops-dev-cluster" {
  depends_on = [
    module.clusters-setup,
  ]
  provisioner "local-exec" {
    command = "BINPATH=\"bin\" && ./$BINPATH/oc login --token=${var.dev-cluster-token} --server=${var.dev-cluster-host} --insecure-skip-tls-verify && ./$BINPATH/igc gitops ${github_repository.gitops-repo.html_url} -n ${var.project-name}-dev -u ${var.github-user} -p ${var.github-token}"
  }
}

module "multiarch-pipelines" {
  depends_on = [
    # module.dev-cluster,
    module.clusters-setup,
  ]
  source      = "./module/multiarch-pipelines"
  gitops-repo = github_repository.gitops-repo.html_url
  # User of the github code repositories
  # github-user           = "ibm-ecosystem-lab"
  github-user           = var.github-user
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

