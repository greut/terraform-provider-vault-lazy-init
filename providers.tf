terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.9"
    }
  }
}

provider "vault" {
  address = "http://${local.vault_address}"
  token   = random_password.vault_token.result
}
