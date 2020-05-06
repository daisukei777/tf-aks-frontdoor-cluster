#!/bin/bash

# Destroy Shared Resources
terraform init \
    -backend-config="storage_account_name=${TF_VAR_rp_prefix}tfstate" \
    -backend-config="container_name=tfstate-cluster" \
    -backend-config="key=terraform.tfstate" \
    -reconfigure

terraform destroy -auto-approve
RET=$?

# Delete Resource Group for Remote State
RESOURCE_GROUP_NAME=${TF_VAR_rp_prefix}-rp-tfstate-rg
[ ${RET} -eq 0 ] && az group delete -n $RESOURCE_GROUP_NAME -y

# Delete Service Principal
az ad sp delete --id $(az ad sp show --id https://${TF_VAR_rp_prefix}-rp-sp-aks-location-1 --query appId --output tsv)

az ad sp delete --id $(az ad sp show --id https://${TF_VAR_rp_prefix}-rp-sp-aks-location-2 --query appId --output tsv)

az ad sp delete --id $(az ad sp show --id https://${TF_VAR_rp_prefix}-rp-sp-aks-location-3 --query appId --output tsv)
