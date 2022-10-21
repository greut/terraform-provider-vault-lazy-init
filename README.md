# Terraform provider for Vault and late Client initialization

This repository is a demo showing a bug when the Vault server is created in the same state than the Vault provider is being used.

The issue is simple, as the Terraform provider uses data coming from other resources it has to wait for them to be resolved before
using them. The current provider doesn't wait and uses default values causing trouble.

E.g. https://github.com/hashicorp/terraform-provider-hcp/issues/132#issuecomment-1279468134

## Running it

Let's run it. [`init-vault.sh`](./init-vault.sh) starts a Vault server on a random port with a random root token. However, the provider fires way too quickly the `lookup-self` even thought there is `depends_on` constraint that tries to wait for the Vault server to be up and running.

```console
$ terraform apply
╷
│ Error: Get "https://127.0.0.1:8200/v1/auth/token/lookup-self": dial tcp 127.0.0.1:8200: connect: connection refused
│
│   with provider["registry.terraform.io/hashicorp/vault"],
│   on providers.tf line 20, in provider "vault":
│   20: provider "vault" {
│
╵
```

## Trying the fix

Modify your `.terraformrc` to use [that branch](https://github.com/greut/terraform-provider-vault/tree/feat/lazy-init-2) and try it again.

```
$ terraform apply
╷
│ Warning: Provider development overrides are in effect
│
│ The following provider development overrides are set in the CLI configuration:
│  - hashicorp/vault in /home/yoan/soft/terraform-provider-vault
│
│ The behavior may therefore not match any released version of the provider and applying changes may cause the state to become incompatible with published releases.
╵

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # null_resource.init_vault will be created
  + resource "null_resource" "init_vault" {
      + id       = (known after apply)
      + triggers = (known after apply)
    }

  # random_integer.vault_port will be created
  + resource "random_integer" "vault_port" {
      + id     = (known after apply)
      + max    = 20000
      + min    = 10000
      + result = (known after apply)
    }

  # random_password.vault_token will be created
  + resource "random_password" "vault_token" {
      + bcrypt_hash = (sensitive value)
      + id          = (known after apply)
      + length      = 32
      + lower       = true
      + min_lower   = 0
      + min_numeric = 0
      + min_special = 0
      + min_upper   = 0
      + number      = true
      + numeric     = true
      + result      = (sensitive value)
      + special     = false
      + upper       = true
    }

  # vault_kv_secret_v2.secret will be created
  + resource "vault_kv_secret_v2" "secret" {
      + cas                 = 1
      + data                = (sensitive value)
      + data_json           = (sensitive value)
      + delete_all_versions = true
      + disable_read        = false
      + id                  = (known after apply)
      + metadata            = (known after apply)
      + mount               = "kvv2"
      + name                = "secret"
      + path                = (known after apply)
    }

  # vault_mount.kvv2 will be created
  + resource "vault_mount" "kvv2" {
      + accessor                     = (known after apply)
      + audit_non_hmac_request_keys  = (known after apply)
      + audit_non_hmac_response_keys = (known after apply)
      + default_lease_ttl_seconds    = (known after apply)
      + description                  = "KV Version 2 secret engine mount"
      + external_entropy_access      = false
      + id                           = (known after apply)
      + max_lease_ttl_seconds        = (known after apply)
      + options                      = {
          + "version" = "2"
        }
      + path                         = "kvv2"
      + seal_wrap                    = (known after apply)
      + type                         = "kv"
    }

Plan: 5 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + vault = {
      + addr  = (known after apply)
      + token = (known after apply)
    }

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

random_integer.vault_port: Creating...
random_password.vault_token: Creating...
random_integer.vault_port: Creation complete after 0s [id=15982]
random_password.vault_token: Creation complete after 0s [id=none]
null_resource.init_vault: Creating...
null_resource.init_vault: Provisioning with 'local-exec'...
null_resource.init_vault (local-exec): (output suppressed due to sensitive value in config)
null_resource.init_vault (local-exec): (output suppressed due to sensitive value in config)
null_resource.init_vault (local-exec): (output suppressed due to sensitive value in config)
null_resource.init_vault (local-exec): (output suppressed due to sensitive value in config)
null_resource.init_vault: Creation complete after 0s [id=1425452812432460266]
vault_mount.kvv2: Creating...
vault_mount.kvv2: Creation complete after 0s [id=kvv2]
vault_kv_secret_v2.secret: Creating...
vault_kv_secret_v2.secret: Creation complete after 0s [id=kvv2/data/secret]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

vault = {
  "addr" = "http://127.0.0.1:15982"
  "token" = "WfnKUhHBAelu9KS7Nz5rPvWVTrAAn6x7"
}

$ # cleanup
$ killall vault
```

And it works!
