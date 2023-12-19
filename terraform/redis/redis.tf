# Create Redis cache in VPC1.
resource "google_redis_instance" "redis" {
  name        = "devops-redis"
  memory_size_gb = 1
  region      = "europe-southwest1"
  authorized_network  = "projects/devops-microservices/global/networks/vpc1"
}

