#!/bin/bash -ex

# Check if the app version argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <appVersion>"
    exit 1
fi

# Read the app version from the first argument
APP_VERSION="$1"
IMAGE_NAME="gcr.io/devops-microservices/devops-microservices:$APP_VERSION"
CHART_DIR="./helm-chart"
NAMESPACE="devops-microservices"

# Step 1: Build and Push Docker Image
cd microservice
echo "Building Docker image: $IMAGE_NAME"
docker build -t $IMAGE_NAME .
echo "Pushing Docker image to registry"
docker push $IMAGE_NAME
cd ../

# Step 2: Deploy with Helm
echo "Deploying application with Helm"
helm upgrade --install helm-chart $CHART_DIR --namespace $NAMESPACE --set appVersion=$APP_VERSION

echo "Deployment complete"

