variable "project-name" {
  description = "Name of the projects that will be created on the OpenShift clusters, then names will be -dev, -test and -prod."
}

### Clusters hosts

variable "dev-cluster-host" {}

variable "x86-cluster-host" {}

variable "z-cluster-host" {}

variable "power-cluster-host" {}

### Clusters tokens

variable "dev-cluster-token" {}

variable "x86-cluster-token" {}

variable "z-cluster-token" {}

variable "power-cluster-token" {}
