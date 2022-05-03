#!/bin/bash
# Fetch server urls
source servers.sh

# Variables for the command
GIT_REPO="https://github.com/aminerachyd/"
IMAGE_REGISTRY="quay.io"
IMAGE_NAMESPACE="aminerachyd"
HEALTH_PROTOCOL="grpc"

mpt --app-name currencyservice -g "${GIT_REPO}currencyservice.git" -r $IMAGE_REGISTRY -n $IMAGE_NAMESPACE -h $HEALTH_PROTOCOL -x86 -power -z --api-server-x86 $X86_SERVER_URL --api-server-z $Z_SERVER_URL --api-server-power $POWER_SERVER_URL
mpt --app-name checkoutservice -g "${GIT_REPO}checkoutservice.git" -r $IMAGE_REGISTRY -n $IMAGE_NAMESPACE -h $HEALTH_PROTOCOL -x86 -power -z --api-server-x86 $X86_SERVER_URL --api-server-z $Z_SERVER_URL --api-server-power $POWER_SERVER_URL
mpt --app-name frontend -g "${GIT_REPO}frontend.git" -r $IMAGE_REGISTRY -n $IMAGE_NAMESPACE -h $HEALTH_PROTOCOL -x86 -power -z --api-server-x86 $X86_SERVER_URL --api-server-z $Z_SERVER_URL --api-server-power $POWER_SERVER_URL
mpt --app-name paymentservice -g "${GIT_REPO}paymentservice.git" -r $IMAGE_REGISTRY -n $IMAGE_NAMESPACE -h $HEALTH_PROTOCOL -x86 -power -z --api-server-x86 $X86_SERVER_URL --api-server-z $Z_SERVER_URL --api-server-power $POWER_SERVER_URL
mpt --app-name shippingservice -g "${GIT_REPO}shippingservice.git" -r $IMAGE_REGISTRY -n $IMAGE_NAMESPACE -h $HEALTH_PROTOCOL -x86 -power -z --api-server-x86 $X86_SERVER_URL --api-server-z $Z_SERVER_URL --api-server-power $POWER_SERVER_URL
mpt --app-name productcatalogservice -g "${GIT_REPO}productcatalogservice.git" -r $IMAGE_REGISTRY -n $IMAGE_NAMESPACE -h $HEALTH_PROTOCOL -x86 -power -z --api-server-x86 $X86_SERVER_URL --api-server-z $Z_SERVER_URL --api-server-power $POWER_SERVER_URL
# Only on x86 and Power
mpt --app-name recommendationservice -g "${GIT_REPO}recommendationservice.git" -r $IMAGE_REGISTRY -n $IMAGE_NAMESPACE -h $HEALTH_PROTOCOL -x86 -power --api-server-x86 $X86_SERVER_URL --api-server-power $POWER_SERVER_URL
mpt --app-name emailservice -g "${GIT_REPO}emailservice.git" -r $IMAGE_REGISTRY -n $IMAGE_NAMESPACE -h $HEALTH_PROTOCOL -x86 -power --api-server-x86 $X86_SERVER_URL --api-server-power $POWER_SERVER_URL
# Only on x86
mpt --app-name cartservice -g "${GIT_REPO}cartservice.git" -r $IMAGE_REGISTRY -n $IMAGE_NAMESPACE -h $HEALTH_PROTOCOL -x86 --api-server-x86 $X86_SERVER_URL

