# Infrastructure for target account

This is the account which is targeted from the master account. All we need for this account is role that master account can assume.

## How to run

```
MY_ACCOUNT=YOUR_13_DIGIT_ACCOUNT_ID
export TF_VAR_master_account=${MY_ACCOUNT}

terraform init && terraform get

terraform plan

terraform apply 
```
