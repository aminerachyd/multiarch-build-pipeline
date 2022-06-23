# Multiarch demo Terraform setup

This Terraform script setups the multiarch demo.

## Pre-requisites:

- Terraform CLI installed
- Admin access to two x86 clusters, a Z cluster and a Power cluster
- One x86 cluster is used as a development cluster, the Cloud Native Toolkit should be installed on this cluster
- Image registry repositories setup, the script won't handle the creation of the repositories for each application
