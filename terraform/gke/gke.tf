# Create GKE cluster in VPC1.
resource "google_container_cluster" "gke_cluster" {
  name     = "devops-microservices"
  location = "europe-southwest1-a"
  network  = "projects/devops-microservices/global/networks/vpc1"
  initial_node_count = 1
}

# Outputs the cluster endpoint
output "cluster_endpoint" {
  value = google_container_cluster.gke_cluster.endpoint
}

# Outputs the cluster ca certificate 
output "cluster_ca_certificate" {
  value = google_container_cluster.gke_cluster.master_auth[0].cluster_ca_certificate
}

