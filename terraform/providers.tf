# Kubernetes provider configuration
provider "kubernetes" {
  host                   = module.gke.cluster_endpoint
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
}

data "google_client_config" "current" {}
