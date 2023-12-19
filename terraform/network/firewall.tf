# Define firewall rules for VPC1 to access VPC2's PostgreSQL port.
resource "google_compute_firewall" "vpc1_to_vpc2" {
  name    = "vpc1-to-vpc2"
  network = google_compute_network.vpc1.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]  # PostgreSQL port
  }

  source_ranges = ["10.0.0.0/24"]
}
