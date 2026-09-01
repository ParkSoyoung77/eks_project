terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~>6.0"
        }
        random = { 
            source = "hashicorp/random" 
        }
        tls = {
            source = "hashicorp/tls"
        }
        kubernetes = {
            source  = "hashicorp/kubernetes"
            version = "~>2.30"
        }
    }
    cloud {
        organization = "terraform_code_test"
        workspaces {
            name = "terraform-test"
        }
    }
}