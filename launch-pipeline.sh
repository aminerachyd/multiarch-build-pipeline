#!/bin/bash

# Create variables
echo "Enter the git repository url to run the pipeline on"
read GIT_URL
APP_NAME=$(basename "$GIT_URL" | sed s/".git"//)
PIPELINE_NAME=$APP_NAME-multiarch-build
echo "Enter the image registry where you want to push your image"
read IMAGE_SERVER
echo "Enter the name of your user/organisation on your registry"
read IMAGE_NAMESPACE
echo "Enter the api server url for your x86 cluster"
read X86_SERVER_URL

# Update pipeline name in the template pipeline
sed s/PIPELINE_NAME/$PIPELINE_NAME/ local-cluster-pipelines/general-pipeline.template.yaml | oc apply -f -

# Start pipeline
tkn pipeline start $PIPELINE_NAME \
  --use-param-defaults \
  --param git-url=$GIT_URL \
  --param image-server=$IMAGE_SERVER \
  --param image-namespace=$IMAGE_NAMESPACE \
  --param x86-server-url=$X86_SERVER_URL \

# TODO Create webhook to trigger the pipeline on repo push event
