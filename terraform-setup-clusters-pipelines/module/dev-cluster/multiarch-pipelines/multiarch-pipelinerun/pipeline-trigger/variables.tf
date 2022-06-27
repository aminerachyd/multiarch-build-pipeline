variable "app-name" {}
variable "project-name" {}
variable "github-user" {

}
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
variable "x86-server-url" {
  default = "_"
}
variable "power-server-url" {
  default = "_"
}
variable "z-server-url" {
  default = "_"
}
