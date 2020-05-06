terraform init \
    -backend-config="storage_account_name=${TF_VAR_rp_prefix}tfstate" \
    -backend-config="container_name=tfstate-cluster" \
    -backend-config="key=terraform.tfstate" \
    -reconfigure

terraform apply -auto-approve