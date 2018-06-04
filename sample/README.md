# Sample 

There are 2 files `run.sh` and `teardown.sh` as the name suggested, just run this script in this path! 

### Run

I have provided /apps sample applications creating ASG as starting point to have instances so you can use it to run chaos on them

Sample App section
```$shell
# Sample Apps if you need it
export TF_VAR_aws_vpc_id=YOUR_VLC
(cd apps && terraform init && terraform get)
(cd apps && terraform apply -auto-approve)
```

Master and Target account, for a simple case they are the same

```$shell
MY_ACCOUNT=YOUR_13_DIGIT_ACCOUNT_ID
export TF_VAR_master_account=${MY_ACCOUNT}
export TF_VAR_target_accounts=${MY_ACCOUNT}
# Optional here if not it will default send alert to http://chaos.requestcatcher.com check it out! or you can provide Slack
export TF_VAR_hook_url=SLACK_WEB_HOOK

#Target
echo "Builder Target Account role and etc"
(cd ../infra_target && terraform init && terraform get)
(cd ../infra_target && terraform apply -auto-approve)

# Master
echo "Builder Master Account role and etc"
(cd ../infra && terraform init && terraform get)
(cd ../infra && terraform apply -auto-approve -var-file="config/master.tfvar")
```

just a simple click
[![asciicast](https://asciinema.org/a/27WE9BqbQqlpsdmq42v1pBoVr.png)](https://asciinema.org/a/27WE9BqbQqlpsdmq42v1pBoVr)

### Teardown

Once you're done just hit `./teardown` may the money be with you!