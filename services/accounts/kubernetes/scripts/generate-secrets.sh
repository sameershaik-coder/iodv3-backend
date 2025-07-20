#!/bin/bash
SECRET_KEY=$(openssl rand -base64 32)
echo "Creating secrets.yaml..."
cat << EOF > secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: accounts-secrets
  namespace: default
type: Opaque
data:
  secret_key: $(echo -n "${SECRET_KEY}" | base64)
EOF
chmod 600 secrets.yaml
echo "secrets.yaml created successfully"