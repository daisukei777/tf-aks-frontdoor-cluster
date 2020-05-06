#!/bin/bash

# Please Specify Resouce Identifier (ex. daisukei99)
export TF_VAR_rp_prefix="daisukeiaksrs"

# 1st region
export TF_VAR_rp_resource_group_location_1="japanwest"

# 2nd region
export TF_VAR_rp_resource_group_location_2="japaneast"

# 3nd region
export TF_VAR_rp_resource_group_location_3="japanwest"

# (No edit) Get Azure AD tenant ID 
export TF_VAR_rp_aad_tenant_id=$(az account show --query tenantId -o tsv)


# Create Azrue Storage and Container for Terraform state
RESOURCE_GROUP_NAME=${TF_VAR_rp_prefix}-rp-tfstate-rg
STORAGE_ACCOUNT_NAME=${TF_VAR_rp_prefix}tfstate
CONTAINER_NAME_CLUSTER=tfstate-cluster
PRIMARY_LOCATION=${TF_VAR_rp_resource_group_location_1}

az group create --name $RESOURCE_GROUP_NAME --location $PRIMARY_LOCATION

az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

export ARM_ACCESS_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

az storage container create --name ${CONTAINER_NAME_CLUSTER} --account-name $STORAGE_ACCOUNT_NAME --account-key $ARM_ACCESS_KEY