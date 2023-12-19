terraform {
  backend "gcs" {
    bucket         = "devops-microservices-bucket"
    prefix         = "terraform/state"
    credentials    = "devops-microservices_credentials.json"
  }
}

