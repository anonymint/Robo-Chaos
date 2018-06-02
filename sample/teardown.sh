#!/bin/sh

set -e

######
# Generate sample ASG - EC2 for Chaos
######

# sample apps! this will create ASG with 2 instances sitting behind ELB, you have to pay!
# if you have ASG with at least 1 instance, you can skip this step

# assume this vpc is default one allow
export TF_VAR_aws_vpc_id=vpc-f492a190
(cd apps && terraform destroy -auto-approve)


######
# Generate Target and Master account for Chaos
# Simple scenario target and master are the same account
######

MY_ACCOUNT=012140044853
export TF_VAR_master_account=${MY_ACCOUNT}
export TF_VAR_target_accounts=${MY_ACCOUNT}
# Optional here if not it will default send alert to http://chaos.requestcatcher.com check it out! or you can provide Slack
# export TF_VAR_hook_url=https://hooks.slack.com/services/bla_bla_bla

#Target
echo "Teardown Target Account role and etc"
(cd ../infra_target && terraform destroy -auto-approve)

# Master
echo "Teardown Master Account role and etc"
(cd ../infra && terraform destroy -auto-approve -var-file="config/master.tfvar")