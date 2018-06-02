# Infrastructure for target account

This is the account which is targeted from the master account. All we need for this account is role that master account can assume.

## Optional predefine
By default, Terraform script will look for 

* Bucket `chaos-engineer-target` or anything unique which you need to update `main.tf` terraform backend to match this name.

## How to run

```
terraform init && terraform get

terraform plan -var 'master_account={13_digits_codes}' -var 'region={region_you_want}'

terraform apply -var 'master_account={13_digits_codes}' -var 'region={region_you_want}'

terraform destroy -var 'master_account={13_digits_codes}' -var 'region={region_you_want}'
```