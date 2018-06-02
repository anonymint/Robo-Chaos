#!/bin/sh 

set -e

######
# Generate sample ASG - EC2 for Chaos
######

# sample apps! this will create ASG with 2 instances sitting behind ELB, you have to pay!
# if you have ASG with at least 1 instance, you can skip this step

# Comment it out if you want to have sample apps, below is sample vpc all you need to provide

# export TF_VAR_aws_vpc_id=vpc-f492a190
#(cd apps && terraform init && terraform get)
#(cd apps && terraform apply -auto-approve)


######
# Generate Target and Master account for Chaos
# Simple scenario target and master are the same account
######

MY_ACCOUNT=AWS_ACCOUNT_ID
export TF_VAR_master_account=${MY_ACCOUNT}
export TF_VAR_target_accounts=${MY_ACCOUNT}
# Optional here if not it will default send alert to http://chaos.requestcatcher.com check it out! or you can provide Slack
# export TF_VAR_hook_url=https://hooks.slack.com/services/bla bla bla

#Target
echo "Builder Target Account role and etc"
(cd ../infra_target && terraform init && terraform get)
(cd ../infra_target && terraform apply -auto-approve)

# Master
echo "Builder Master Account role and etc"
(cd ../infra && terraform init && terraform get)
(cd ../infra && terraform apply -auto-approve -var-file="config/master.tfvar")