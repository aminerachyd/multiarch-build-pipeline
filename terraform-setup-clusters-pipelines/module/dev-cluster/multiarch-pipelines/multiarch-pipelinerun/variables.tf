variable "app-name" {}
variable "project-name" {}
variable "gitops-repo" {}
variable "git-url" {}
variable "github-user" {}
variable "github-token" {}
variable "git-revision" {
  default = "master"
}
variable "image-server" {
  default = "quay.io"
}
variable "image-namespace" {}
variable "scan-image" {
  default = "false"
  type    = string
}
variable "lint-dockerfile" {
  default = "false"
  type    = string
}
variable "health-protocol" {
  default = "grpc"
}
variable "health-endpoint" {
  default = "/"
}
variable "build-on-x86" {
  default = "false"
  type    = string
}
variable "build-on-power" {
  default = "false"
  type    = string
}
variable "build-on-z" {
  default = "false"
  type    = string
}

variable "destination-cluster" {}
