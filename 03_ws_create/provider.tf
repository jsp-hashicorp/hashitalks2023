terraform {
  required_providers {
    tfe = {
      version = "~> 0.48.0"
    }
  }
}

provider "tfe" {
  hostname = var.hostname # Optional, defaults to Terraform Cloud `app.terraform.io`
 # token    = var.token
 # version  = "~> 0.44.0"
}
