variable profile {
  description = "AWS profile you want to use"
  default     = "default"
}

variable "hook_url" {
  description = "The Microsoft team hook url"
  default     = "http://chaos.requestcatcher.com/test"
}

variable "region" {
  description = "region to run the script"
}

variable "prob" {
  description = "probability to kill instance 1 means all the time, 0.17 ~ 1/7 or once in seventh appproximately"
  default     = 0.14
}

variable "target_regions" {
  description = "List of target regions to scan and introduce chaos"
  default     = "us-east-1"
}

variable "target_accounts" {
  description = "target accounts separate by comma 12345,1232,12312 for example"
}

variable "unleash" {
  description = "Unleash Chaos, default is no or DRYRUN mode"
  default     = "no"
}

variable "asg_group_names" {
  description = "List of ASG group that will opt in, default is blank means ALL"
  default     = ""
}

variable "schedule_run" {
  description = "Cron job to run in GMT time, please make sure it's valid cloudwatch schedule!"
  type        = "list"
  default     = ["cron(13 15-21 ? * MON-FRI *)"]
}
