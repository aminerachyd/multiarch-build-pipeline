variable "project-name" {
  description = "Name of the projects that will be created on the OpenShift clusters, then names will be -dev, -test and -prod."
}

### Clusters hosts

variable "dev-cluster-host" {
  description = "Hostname of the dev cluster. This cluster will be used for the development stage"
}

variable "x86-cluster-host" {
  description = "Hostname of the x86 cluster. This cluster will be used for running a remote pipeline aswell as deploying the application"
}

variable "z-cluster-host" {
  description = "Hostname of the z cluster. This cluster will be used for running a remote pipeline aswell as deploying the application"
}

variable "power-cluster-host" {
  description = "Hostname of the power cluster. This cluster will be used for running a remote pipeline aswell as deploying the application"
}

### Clusters tokens

variable "dev-cluster-token" {
  description = "Token of the dev cluster."
}

variable "x86-cluster-token" {
  description = "Token of the x86 cluster."
}

variable "z-cluster-token" {
  description = "Token of the z cluster."
}

variable "power-cluster-token" {
  description = "Token of the power cluster."
}

### Image registry access

variable "image-server" {
  default     = "quay.io"
  description = "Hostname of the image registry server."
}

variable "image-namespace" {
  description = "Namespace of the image registry (user or organization)."
}

variable "registry-user" {
  description = "Username for the image registry."
}

variable "registry-token" {
  description = "Token for the image registry."
}


### Git repo access

variable "github-user" {
  description = "Git user for the git repository."
}

variable "github-token" {
  description = "Git token for the git repository."
}

### Misc
variable "smee-client" {
  description = "Smee client url for event listening, head over the smee.io. Your git repos should have webhooks configured for this url."
}

### Microservices github repos
variable "frontendservice" {
  description = "Git repo for the frontend microservice."
  default     = "https://github.com/ibm-ecosystem-lab/frontend"
}
variable "productcatalogservice" {
  description = "Git repo for the product catalog microservice."
  default     = "https://github.com/ibm-ecosystem-lab/productcatalogservice"
}
variable "cartservice" {
  description = "Git repo for the cart microservice."
  default     = "https://github.com/ibm-ecosystem-lab/cartservice"
}
variable "shippingservice" {
  description = "Git repo for the shipping microservice."
  default     = "https://github.com/ibm-ecosystem-lab/shippingservice"
}
variable "checkoutservice" {
  description = "Git repo for the checkout microservice."
  default     = "https://github.com/ibm-ecosystem-lab/checkoutservice"
}
variable "recommendationservice" {
  description = "Git repo for the recommendation microservice."
  default     = "https://github.com/ibm-ecosystem-lab/recommendationservice"
}
variable "paymentservice" {
  description = "Git repo for the payment microservice."
  default     = "https://github.com/ibm-ecosystem-lab/paymentservice"
}
variable "emailservice" {
  description = "Git repo for the email microservice."
  default     = "https://github.com/ibm-ecosystem-lab/emailservice"
}
variable "currencyservice" {
  description = "Git repo for the currency microservice."
  default     = "https://github.com/ibm-ecosystem-lab/currencyservice"
}
