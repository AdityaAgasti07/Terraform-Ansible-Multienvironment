set -x  # Add this line at the top of your script for debug mode

#!/bin/bash

# Paths
TERRAFORM_OUTPUT="/home/adityaagasti/ansible/terraform_output.json"
INVENTORIES_DIR="/home/adityaagasti/ansible/inventories"
ENVIRONMENTS=("dev" "stg" "prd")

# Check if Terraform output JSON exists
if [ ! -f "$TERRAFORM_OUTPUT" ]; then
  echo "Error: Terraform output JSON not found at $TERRAFORM_OUTPUT!"
  exit 1
fi

# Validate JSON
if ! jq empty "$TERRAFORM_OUTPUT" >/dev/null 2>&1; then
  echo "Error: Invalid JSON in $TERRAFORM_OUTPUT!"
  exit 1
fi

# Loop through environments and generate inventory files
for ENV in "${ENVIRONMENTS[@]}"; do
  ENV_DIR="$INVENTORIES_DIR/$ENV"
  INVENTORY_FILE="$ENV_DIR/inventory.ini"

  # Ensure environment directory exists
  if [ ! -d "$ENV_DIR" ]; then
    echo "Creating directory $ENV_DIR..."
    mkdir -p "$ENV_DIR"
  fi

  # Extract IP addresses for the environment
  PUBLIC_IPS=$(jq -r ".${ENV}_infra_ec2_public_ips.value[]" "$TERRAFORM_OUTPUT")
  PRIVATE_IPS=$(jq -r ".${ENV}_infra_ec2_private_ips.value[]" "$TERRAFORM_OUTPUT")

  if [ -z "$PUBLIC_IPS" ]; then
    echo "Warning: No public IPs found for $ENV environment."
    continue
  fi

  echo "Generating inventory for $ENV at $INVENTORY_FILE..."

  # Write inventory header
  {
    echo "[${ENV}_servers]"
    COUNT=1
    for IP in $PUBLIC_IPS; do
      echo "server$COUNT ansible_host=$IP"
      COUNT=$((COUNT + 1))
    done

    echo
    echo "[${ENV}_servers:vars]"
    echo "ansible_user=ubuntu"
    echo "ansible_ssh_private_key_file=/home/adityaagasti/ansible/tws-terra-key"
    echo "ansible_python_interpreter=/usr/bin/python3"
  } >"$INVENTORY_FILE"

  echo "$ENV inventory generated successfully!"
done

echo "All inventories have been generated!"

