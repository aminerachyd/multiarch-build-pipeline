# Multiarch build pipeline using tekton
This repo contains a pipeline for building a multiarchitecure application using Tekton pipelines inside OpenShift clusters.  
You will need a "master" OpenShift cluster, and one or many "builder" OpenShift clusters depending on what target architectures you want.  

## Setup
### 1 - Create the projects
Create the projects on your clusters.  
A \*-dev projects on all the clusters, and \*-test and \*-prod projects on the builder clusters, we will be using them for the deployment of the application. The deployment will be configured with ArgoCD applications later on.  
You can apply the files under the setup/step-1 directory. The projects will be *multiarch-demo-dev* *multiarch-demo-test* and *multiarch-demo-prod*

### 2 - Give the master cluster access to launch pipelines on the builder clusters
Log into each builder cluster and create a service account called `pipeline-starter` :   
```
oc create sa pipeline-starter
```

Then, grant him authorizations to start pipelines, you can apply the files found in the builder-cluster-setup directory, change the namespaces if needed (the default namespace is multiarch-demo-dev).   

Obtain an authentification token for the service account :
```
oc sa get-token pipeline-starter
```

Log into your master OpenShift cluster and create a secret that will hold the token :

```
oc create secret generic --from-literal=openshift-token=<YOUR_TOKEN_HERE> <NAME_OF_YOUR_SECRET>
```
You could create the secrets on the tools namespace as we will be syncing our dev project to it later on.  

We will be calling the secrets for x86, Z and Power clusters respectively *builder-cluster-x86-secret* *builder-cluster-z-secret* *builder-cluster-power-secret*  

After syncing your local OpenShift project, launch the pipeline using the script launch-pipeline.sh  

### 3 - Create/Update git credentials and the docker registry access token on the clusters

On each dev project on all the clusters create or update the *registry-access* secret.  
Put in it the following values:
 - REGISTRY_USER : Your username
 - REGISTRY_PASSWORD : Your password/access token

The registry to use will be specified within the pipeline options.  

Next create another secret, this will be a source secret, give it the name of git-credentials and put in it your git username and password (or access token)  

### 4 - Sync the dev project on the master cluster

Run `oc sync <DEV_NAMESPACE> --tekton`on the all cluster's dev namespace, this should copy all the required secrets (by the master cluter pipeline nd give the project SCC privileges when running Tekton pipelines  

### 5 - Point the dev project on the master cluster to the GitOps repo (testing branch) 

Run `oc gitops` or `igc gitops`. This will tell the project to use the current repo you're in as a GitOps repo. Make sure you are on the correct branch you want to keep updating with the GitOps task of the pipeline.  

### 6 - Apply some task files necessary for the piplines

Head over to setup/step-6 and apply the yaml files corresponding the each cluster.

### 7 - Configure ArgoCD clusters and create applications

The applications are under argocd-application directory, they will be deployed using ArgoCD on the projects multiarch-demo-test and multiarch-demo-prod.  
To create the applications, you can apply the yaml files on each subdir to master cluster on the openshift-gitops project.  
ArgoCD will probably give errors if your GitOps repo doesn't have versions of your applications yet.   


At this point you can launch the pipelines using the launch-pipelines.sh script, make sure to give the variables the correct values.
