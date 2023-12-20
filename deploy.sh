#!/bin/bash -ex

# Check if the app version argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <appVersion>"
    exit 1
fi

# Read the app version from the first argument
APP_VERSION="$1"
IMAGE_NAME="gcr.io/devops-microservices/devops-microservices:$APP_VERSION"
CHART_DIR="./helm"
NAMESPACE="devops-microservices"
major_version="${APP_VERSION%%.*}"

# Build and Push Docker Image
cd microservice
echo "Building Docker image: $IMAGE_NAME"
docker build -t $IMAGE_NAME .
echo "Deleting Docker image from registry"
gcloud container images delete $IMAGE_NAME --force-delete-tags --quiet || echo "No docker image existed"
echo "Pushing Docker image to registry"
docker push $IMAGE_NAME
cd ../

# Deploy with Helm
echo "Deploying application with Helm"
helm upgrade --install helm-${major_version} $CHART_DIR --namespace $NAMESPACE --set majorVersion=$major_version --set appVersion=$APP_VERSION

echo "Deployment complete"

