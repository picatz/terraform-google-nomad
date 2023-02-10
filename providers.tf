terraform {
  required_providers {
    tls = {
        version = ">= 4.0.4"
        source = "hashicorp/tls"
    }
    
    local = {
        version = ">= 2.3.0"
        source = "hashicorp/local"
    }

    google = {
        version = ">= 4.52.0"
        source = "hashicorp/google"
    }
    
    random = {
        version = ">= 3.4.3"
        source = "hashicorp/random"
    }
  }
}