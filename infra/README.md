# Infrastructure for master account

This is the account which is the main account that's going to schedule to run, randomlly pick up targets and apply chaos via assuming role we created in `infra_target`

## How to run

```
MY_ACCOUNT=YOUR_13_DIGIT_ACCOUNT_ID
export TF_VAR_target_accounts=${MY_ACCOUNT}
# Optional here if not it will default send alert to http://chaos.requestcatcher.com check it out! or you can provide Slack
export TF_VAR_hook_url=SLACK_WEB_HOOK

terraform init && terraform get

terraform plan -var-file="config/master.tfvar"

terraform apply -var-file="config/master.tfvar" 

terraform destroy -var-file="config/master.tfvar" 
```
