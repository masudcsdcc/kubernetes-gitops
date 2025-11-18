#!/bin/bash

# Install SOPS
curl -LO https://github.com/mozilla/sops/releases/download/v3.7.3/sops-v3.7.3.linux.amd64
sudo mv sops-v3.7.3.linux.amd64 /usr/local/bin/sops
sudo chmod +x /usr/local/bin/sops

# Get public key from age-key.txt
PUBLIC_KEY=$(cat age-key.txt | grep "public" | cut -d: -f2 | tr -d ' ')

# Encrypt the secret
sops --encrypt \
  --age $PUBLIC_KEY \
  --encrypted-regex '^(data|stringData)$' \
  applications/secrets/mysql-secret-unencrypted.yaml > applications/secrets/mysql-secret.enc.yaml

echo "Secret encrypted and saved to applications/secrets/mysql-secret.enc.yaml"
