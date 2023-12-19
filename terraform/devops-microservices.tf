# Define provider (Google Cloud Platform).
provider "google" {
  credentials = file("devops-microservices_credentials.json")
  project     = "devops-microservices"
  region      = "europe-southwest1-a"
}

# Use modules.
# storage module not needed because the backend state is persisted in a bucket already (see backend.tf)

module "network" {
  source = "./network"
}
module "gke" {
  source = "./gke"
}
module "redis" {
  source = "./redis"
}
module "sql" {
  source         = "./sql"
  vpc2_self_link = module.network.vpc2_self_link
  project        = "devops-microservices"
  region         = "europe-southwest1"
}
module "helm" {
  source = "./helm"
}
