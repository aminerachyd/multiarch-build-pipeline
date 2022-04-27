# Multiarch build pipeline using tekton
This repo contains a pipeline for building a multiarchitecure application using Tekton pipelines inside OpenShift clusters.  
You will need a "local" OpenShift cluster, and one or many "remote" OpenShift clusters depending on what target architectures you want.  

## Setup
Log into each remote cluster and create a service account called `pipeline-starter` :   
```
oc create sa pipeline-starter
```

Then, grant him authorizations to start pipelines, you can apply the files found in the local-cluster-setup directory, change the namespaces if needed (the default namespace is multiarch-demo).   

Obtain an authentification token for the service account :
```
oc sa get-token pipeline-starter
```

Log into your local OpenShift cluster and create a secret that will hold the token :

```
oc create secret generic --from-literal=openshift-token=<YOUR_TOKEN_HERE> <NAME_OF_YOUR_SECRET>
```

Make sure to change the match the secret name with the one on the pipeline.  

After syncing your local OpenShift project, launch the pipeline using the script launch-pipeline.sh  
