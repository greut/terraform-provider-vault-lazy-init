resource "random_password" "vault_token" {
  length  = 32
  special = false
}

resource "random_integer" "vault_port" {
  min = 10000
  max = 20000
}

locals {
  vault_address = "127.0.0.1:${random_integer.vault_port.result}"
}

resource "null_resource" "init_vault" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "./init-vault.sh 10" # sleep x seconds before starting Vault
    environment = {
      VAULT_DEV_LISTEN_ADDRESS = local.vault_address
      VAULT_DEV_ROOT_TOKEN_ID  = random_password.vault_token.result
    }
  }
}

# Cf. https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kv_secret_v2
resource "vault_mount" "kvv2" {
  depends_on = [null_resource.init_vault]

  path = "kvv2"
  type = "kv"
  options = {
    version = "2"
  }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "secret" {
  mount               = vault_mount.kvv2.path
  name                = "secret"
  cas                 = 1
  delete_all_versions = true
  data_json = jsonencode(
    {
      zip = "zap",
      foo = "bar"
    }
  )
}

output "vault" {
  value = {
    addr  = "http://${local.vault_address}"
    token = nonsensitive(random_password.vault_token.result)
  }
}
