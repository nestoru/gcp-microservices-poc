[![](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/donate/?hosted_button_id=58F9TDDRBND4L)

# GCP Terraform Helm Microservices PoC for Devops
This PoC shows how to use Terraform to host TLS microservices (or many) in Google Kubernetes Engine (GKE), part of Google Cloud Platform (GCP), deployed with Helm charts. The structure of the project is below and it is the first of three cloud projects (GCP, AZ, AWS) that show how to manage microservices hosted in different cloud providers.

```
.
├── README.md
├── deploy.sh
├── helm
│   ├── Chart.yaml
│   ├── charts
│   ├── templates
│   │   ├── certificate.yaml
│   │   ├── deployment.yaml
│   │   ├── ingress.yaml
│   │   ├── service.yaml
│   │   └── tls-issuer.yaml
│   └── values.yaml
├── microservice
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
└── terraform
    ├── backend.tf
    ├── cert-manager.crds.yaml
    ├── devops-microservices.tf
    ├── gke
    │   └── gke.tf
    ├── helm
    │   └── helm.tf
    ├── network
    │   ├── firewall.tf
    │   └── network.tf
    ├── providers.tf
    ├── redis
    │   └── redis.tf
    ├── sql
    │   ├── sql.tf
    │   └── variables.tf
    └── tfplan
```

## Preconditions
- Install gcloud command: Download the tarball from https://cloud.google.com/sdk/docs/install-sdk, select your OS (I am using OSX here), uncompress and make sure your OS PATH is updated to point to its bin directory:
```
export PATH=$PATH:/Users/nu/Downloads/google-cloud-sdk/bin/
```
- Create the GCS bucket where terraform state will be persisted
```
gsutil mb -p devops-microservices -l europe-southwest1 gs://devops-microservices-bucket
```
- Enable the usage of the necessary google APIs
```
gcloud services enable container.googleapis.com --project=devops-microservices
gcloud services enable compute.googleapis.com --project=devops-microservices
gcloud services enable redis.googleapis.com --project=devops-microservices
gcloud services enable sqladmin.googleapis.com --project=devops-microservices
gcloud services enable cloudresourcemanager.googleapis.com --project=devops-microservices
gcloud services enable servicenetworking.googleapis.com --project=devops-microservices
```
- Install terraform and helm locally (showing commands for OSX here) for validations
```
brew install terraform
brew install helm
```
- Install kubectl (it is installed in the gcloud bin directory) and google gcloud-auth-plugin to be able to use kubernetes on GCP
```
gcloud components install kubectl
gcloud components install gke-gcloud-auth-plugin
```
- Create project in Google Cloud a service account with all privileges needed and a credentials file authorized to create the resources
```
gcloud auth login
gcloud projects create devops-microservices 
gcloud config set project devops-microservices
gcloud config set compute/region europe-southwest1-a
gcloud iam service-accounts create devops-microservices --display-name "devops-microservices"
gcloud projects add-iam-policy-binding devops-microservices \
  --member serviceAccount:devops-microservices@devops-microservices.iam.gserviceaccount.com \
  --role roles/editor
gcloud projects add-iam-policy-binding devops-microservices \
  --member serviceAccount:devops-microservices@devops-microservices.iam.gserviceaccount.com \
  --role roles/servicenetworking.networksAdmin
gcloud iam service-accounts keys create devops-microservices_credentials.json \
  --iam-account devops-microservices@devops-microservices.iam.gserviceaccount.com
```
- Make sure devops-microservices_credentials.json is in the .gitignore file as you do not want to commit that to the same repo where developers and devops work. Use the need to know principle. Instead have the file somewhere else in a secure vault and copy it temporarily to the project as needed.
- Configure docker to allow interactions with google cloud registry (GCR)
```
gcloud auth configure-docker

```
## Changing the IaC
After any change validate
```
terraform init && terraform validate
```

## CI/CD
Using GitHub Actions trigger terraform init, validate and push to GCP when changes appear in the main branch (resulting of PR from branch code being reviewed, approved and merged)

## Manual deployment
- Make sure to review what you plan to deploy and that it contains no errors:
```
find ./ -type f -name "*.tf" -exec sh -c 'echo "File: {}"; cat {}' \;
```
- Create a plan
```
terraform init && terraform validate && terraform plan -out=tfplan
```
- Apply the created plan
```
export KUBE_CONFIG_PATH=~/.kube/config && terraform init && terraform validate && terraform apply "tfplan"        
```

## Useful GKE related commands
- Reauthenticate when kubectl does not work
```
gcloud auth login
```
- List available clusters
```
gcloud container clusters list
```
- Generate a kubeconfig entry to authorize kubectl to interact with the cluster named devops-microservices
```
gcloud container clusters get-credentials devops-microservices --region europe-southwest1-a  --project devops-microservices
``` 
- Create a namespace
```
kubectl create  namespace devops-microservices
```
- Set context and namespace for kubectl 
```
kubectl config get-contexts
kubectl get namespaces
kubectl config set-context --current --namespace=devops-microservices
kubectl get pods 
```
- Get pods in all namespaces
```
kubectl get pods --all-namespaces
```
- Get pods and services in the devops-microservices namespace
```
kubectl get pods -n devops-microservices && kubectl get services -n devops-microservices
```
- Get logs for the ingress nginx service
```
kubectl logs -n devops-microservices -l app.kubernetes.io/component=controller -l app.kubernetes.io/name=ingress-nginx
```
## Microservice
In the previous IaC we will deploy a microservice called DevOps. 

### Specifications
Use Helm to deploy the following microservice. Provide instructions on how to handle API versioning.
- Request Payload example. Note that unless the API key is passed it should not respond.
```
export EXPECTED_API_KEY='2f5ae96c-b558-4c7b-a590-a501ae1c3f6c' && \
export HOST=localhost:8080 && \
curl -kX POST \
-H "X-Parse-REST-API-Key: ${EXPECTED_API_KEY}" \
-H "Content-Type: application/json" \
-d '{ "message": "This is a test", "to": "Juan Perez", "from": "Rita Asturia", "timeToLifeSec": 45 }' \
http://${HOST}/DevOps
```
- Response Payload error example:
```
{
  "major_version": null,
  "message": "Error: Provide correct X-Parse-REST-API-Key HTTP Header, and message/to/from/timeToLifeSec in your request payload"
}
```
- Response Payload success example:
```
{
  "major_version": null,
  "message": "Hello Rita Asturia your message will be sent"
}
```
The major_version is returned if the endpoint is invoked with a path that starts with /v{major_version}/. This is important to assert that the version of the microservice being returned is the one the client expects.
 
### Deploy and run locally
The microservice is written in python:
```
cd microservice
python -m venv myenv
source myenv/bin/activate
pip install -r requirements.txt
export EXPECTED_API_KEY='2f5ae96c-b558-4c7b-a590-a501ae1c3f6c' && python app.py
```

### Deploy and run locally with Docker to confirm it will run in kubernetes
```
cd microservice
docker build . -t devops-microservices 
docker stop devops-microservices; docker rm devops-microservices
docker run -e EXPECTED_API_KEY='2f5ae96c-b558-4c7b-a590-a501ae1c3f6c' --detach --publish 8080:8080 --name devops-microservices devops-microservices
# issue curl command and conmfirm it works. To further debug, enter the running container:
docker exec -ti devops-microservices bash
```

### Deploy and run on Kubernetes
The microservice is deployed in the devops-microservices project in GKE. We will package it in a docker image our simple devops-microservices app that listens on port 8080 for HTTPS requests; will deploy it to our GCP cluster called devops-microservice; will use the cert-manager available in that cluster and which was installed via terraform and Helm to make sure the service is encrypted with a valid certificate key; Let's encrypt is used as the certificate issuer; a public IP should expose the service; Google loadbalancer should be attached to that IP by means of an ingress descriptor; if the request is made to the loadbalancer with pattern /v${majorVersion}/  where majorVersion can be any integer, then load balance the request to the pods with name devops-microservices-${majorVersion}; Any request not starting with that pattern should be refused; use Helm to adhoc deploy the app with a given version number (The version number should be passed via CLI parameter and all necessary files should be built on the fly out of existing helm templates with a .Value placeholder).

- Find the external IP address being used in the ingress
```
kubectl get services -n devops-microservices
```
- Promote the external IP address of the ingress loadbalancer as reserved (in my case it was the below)
```
gcloud compute addresses create devops-microservices-ip --addresses 34.175.201.131 --region europe-southwest1 
gcloud compute addresses describe devops-microservices-ip --region europe-southwest1 
gcloud compute addresses list

```
The output should give you the external address. With that address you should map it to a subdomain you own via an A record, in my case gcp.nestorurquiza.com for the purpose of this PoC..

```
ping gcp.nestorurquiza.com 
```
- Let's encrypt should be the certificate issuer.
- A public IP reserved in GCP and DNS setup to point to that IP 
- The app should be deployed in two pods and registered dynamically as devops-microservices-1 if "1" is set to be its version, devops-microservices-2 if "2" is set to be its version and so on. The version is mandatory to be able to deploy.
- Google loadbalancer should respond to requests to the FQDN specified in DNS
- If the request is made to the loadbalancer with pattern /v${majorVersion}/  where majorVersion can be any integer, then load balance the request to the pods with name devops-microservices-${majorVersion}
- Any request not starting with that pattern should be refused
- deploy.sh is used to deploy a specific version number (the major version) passed as unique argument.
- It should not be used manually but for the purpose of this PoC we first use it manually and then later use it from CI/CD.
We will use helm for deploying the app to Google Kubernetes Engine (GKE). Terraform already used helm to deploy the ingress controller needed for load balancing microservices routes (check the terraform helm module).
- In the helm directory we have already created and customized our chart, this is done using the below command and then changing files as needed
```
helm create helm
rm -fr helm/templates/*
```
- helm/Chart.yaml contains the bare minimum (name and description of the help chart).
- helm/values.yaml is blank on purpose as we want to add just what we need and no values are needed other than the version which will be passed via command line.
- helm/templates/deployment.yaml contains the image to deploy using this version number.
- helm/certificate.yaml determines the domain for which the certificate is issued as well as the issuer.
- helm/templates/tls-issuer.yaml has the Let's Encrypt ClusterIssuer configuration.
- helm/templates/service.yaml exposes the deployed pods as clusterIP kind which allows for round robin load balancing, and defines source/detination ports for the service.
- helm/templates/ingress.yaml has the rules for routing the microservice version /v{majorVersion/ to the correct app devops-microservices-{majorVersion}}, indirectly creates the loadbalancer using the proper certificate for TLS termination in that point.
- Use the below to deploy a specific version adhoc
```
helm dependency update ./helm && helm upgrade --install helm-1 ./helm --namespace devops-microservices --set appVersion=1.0.3 --set majorVersion=1 
```
- Deploy microservice version 1.0.3 directly from devops-microservices-1 branch
```
git checkout devops-microservices-1 && git pull; ./deploy.sh 1.0.3
```
- Use port forwarding to interact with the pod running app
```
kubectl port-forward pod/`kubectl get pods --namespace devops-microservices | grep devops | head -1 | awk '{print $1}'` 8080/8080
kubectl get pods
export pod='devops-microservices-1-57cbbb9779-fbx79'
kubectl port-forward pod/${pod} 3443:3443
```
- Uninstall all current helm deployed resources
```
helm uninstall helm -n devops-microservices
```
- Reviee all helm templates
```
find ./helm/templates -type f -name "*.yaml" -exec sh -c 'echo "File: {}"; cat {}' \;
```
- Deploy all helm resources. Pay attention to version numbers as well as the branch from where the microservices are maintained and deployed
```
helm upgrade --install helm-1 ./helm --namespace devops-microservices --set majorVersion=1 --set appVersion=1.0.3
helm upgrade --install helm-2 ./helm --namespace devops-microservices --set majorVersion=2 --set appVersion=2.0.2
```
- Confirm resources are deployed
```
kubectl get pods -n devops-microservices && kubectl get services -n devops-microservices
```
- Branch microservice version 1
```
git checkout -b devops-microservices-1
git push -u origin devops-microservices-1
```
- Switch to microservice version 1 and merge new code from branch into it
```
git branch
git checkout devops-microservices-1
git merge main
git push
```
- Deploy microservices from their proper branches
```
git checkout devops-microservices-1 && git pull; git branch && ./deploy.sh 1.0.3
git checkout devops-microservices-2 && git pull; git branch && ./deploy.sh 2.0.2
```
## Testing the two microservices are separate versions
This test proves that we have two microservices whcih are hit based on the major version number provided in the url path
```
nu@34 gcp-devops-iac % export EXPECTED_API_KEY='2f5ae96c-b558-4c7b-a590-a501ae1c3f6c'
export HOST=34.175.201.131
curl -kX POST \
-H "X-Parse-REST-API-Key: ${EXPECTED_API_KEY}" \
-H "Content-Type: application/json" \
-d '{ "message": "This is a test", "to": "Juan Perez", "from": "Rita Asturia", "timeToLifeSec": 45 }' \
http://${HOST}/v1/DevOps
{
  "major_version": 1,
  "message": "Hello Rita Asturia your message will be sent"
}
nu@34 gcp-devops-iac % export EXPECTED_API_KEY='2f5ae96c-b558-4c7b-a590-a501ae1c3f6c'
export HOST=34.175.201.131
curl -kX POST \
-H "X-Parse-REST-API-Key: ${EXPECTED_API_KEY}" \
-H "Content-Type: application/json" \
-d '{ "message": "This is a test", "to": "Juan Perez", "from": "Rita Asturia", "timeToLifeSec": 45 }' \
http://${HOST}/v2/DevOps
{
  "major_version": 2,
  "message": "Hello Rita Asturia your message will be sent to Juan Perez."
}
nu@34 gcp-devops-iac % 
```

## Make HTTP to port 80 to redirect to HTTPS port 443 and ensure that the certificate is autorenewed
This is achieved by adding SSL configuration and the host to ingress.yaml, adding resource "helm_release" "nginx_ingress in helm.tf and adding Certificate manifests and ClusterIssuer in helm/templates/certificate.yaml helm/templates/tls-issuer.yaml respectively.


After all this is done we should get the two microservices responding correctly without the need for the curl -k (ignore certificate) option:
```
nu@gcp gcp-devops-iac % export EXPECTED_API_KEY='2f5ae96c-b558-4c7b-a590-a501ae1c3f6c'                       
export HOST=gcp.nestorurquiza.com
curl -X POST \ 
-H "X-Parse-REST-API-Key: ${EXPECTED_API_KEY}" \
-H "Content-Type: application/json" \
-d '{ "message": "This is a test", "to": "Juan Perez", "from": "Rita Asturia", "timeToLifeSec": 45 }' \
https://${HOST}/v2/DevOps
{
  "major_version": 2,
  "message": "Hello Rita Asturia your message will be sent to Juan Perez."
}
nu@gcp gcp-devops-iac % export EXPECTED_API_KEY='2f5ae96c-b558-4c7b-a590-a501ae1c3f6c'
export HOST=gcp.nestorurquiza.com
curl -X POST \
-H "X-Parse-REST-API-Key: ${EXPECTED_API_KEY}" \
-H "Content-Type: application/json" \
-d '{ "message": "This is a test", "to": "Juan Perez", "from": "Rita Asturia", "timeToLifeSec": 45 }' \
https://${HOST}/v1/DevOps
{
  "major_version": 1,
  "message": "Hello Rita Asturia your message will be sent"
}
```

### Release
Releasing is the process of tagging and registering the status of such tag like whether tests pass or not. TODO: Add a gke-deploy.sh script that will check any new tag in valid branches and deploy the specific version with deploy.sh.

### Testing
End to end Testing should be triggered when any new microservice is deployed but API releated e2e tests for the specific microservice should be triggered first and if those pass you might want to push the microservice new version to prod.

### API version management
Adding a new version of a microservice and using that version from multiple other microservices or UIs is serious business. Logging aggregation, metrics, thressholds and many more SRE concerns have to be considered. Microservices can reduce delivery time significantly but the investment is not little.

### SDLC recommendations
1. Start from main branch
2. Once you get a v1 that is good enough then create a branch out of it
3. release (tag) v1 branch
4. Keep working on v1 for any fixes needed
5. Use git cherry-pick to select what to merge from v1 code to main branch every time it is tagged as well as collect changes from other branches into v1
6. When a new feature demands a new branch, create it out of the main branch into v2, v3 etc. branches
7. Organizing this requires a lot of transaction costs, which is one of the disadvantages of this modus operandi versus handling all versions at the app layer (treating each microservice as a monolith).
8. Have a deprecation policy for each version.

## Cleanup
- Find out your projects
```
gcloud projects list
```
- Delete the ones that apply to this POC (Warning: Make sure you you understand that you are deleting all resources for this project)
```
gcloud projects delete <your-POC-project>
```

