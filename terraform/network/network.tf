# Create VPC1 for GKE and Redis.
resource "google_compute_network" "vpc1" {
  name = "vpc1"
}

# Create a subnet within VPC1 with a specific IP range.
resource "google_compute_subnetwork" "vpc1_subnet" {
  name          = "vpc1-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = "europe-southwest1"
  network       = google_compute_network.vpc1.self_link
}

# Create VPC2 for SQL Database.
resource "google_compute_network" "vpc2" {
  name = "vpc2"
}

# Create a subnet within VPC2 with a specific IP range.
resource "google_compute_subnetwork" "vpc2_subnet" {
  name          = "vpc2-subnet"
  ip_cidr_range = "10.1.0.0/24"
  region        = "europe-southwest1"
  network       = google_compute_network.vpc2.self_link
}

# Create network peering between vpc1 and vpc2
resource "google_compute_network_peering" "vpc1_to_vpc2" {
  name           = "vpc1-to-vpc2"
  network        = google_compute_network.vpc1.self_link
  peer_network   = google_compute_network.vpc2.self_link
}

# Output the vpc2.self_link so that the root module can use it
output "vpc2_self_link" {
  value = google_compute_network.vpc2.self_link
  description = "The self-link of VPC2"
}

