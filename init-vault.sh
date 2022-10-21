#!/bin/bash

# Assume it takes time.
sleep "${0:-0}"

nohup vault server -dev 2> ./vault.err > ./vault.log &

export VAULT_ADDR=http://${VAULT_DEV_LISTEN_ADDRESS:-127.0.0.1:8200}
export VAULT_TOKEN=${VAULT_DEV_ROOT_TOKEN_ID:-root}

while ! vault status > /dev/null
do
    echo "Wait for Vault to become ready"
done

echo "Ready!"
