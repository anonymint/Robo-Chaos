###
# Lambda Role Policy
###
module "iam_assume_role" {
  source                        = "anonymint/iam-role/aws"
  role_name                     = "lambda-chaos-monkey-execution-role"
  policy_arns_count             = "2"
  policy_arns                   = ["arn:aws:iam::152303423357:policy/sre/chaos_monkey", "arn:aws:iam::aws:policy/AWSOpsWorksCloudWatchLogs"]
  create_instance_role          = false
  iam_role_policy_document_json = "${data.aws_iam_policy_document.lambda_role_policy.json}"
}

# ROLE Policy
data "aws_iam_policy_document" "lambda_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }

    effect = "Allow"
  }
}

###
# Lambda function
###
resource "aws_lambda_function" "chaos_lambda" {
  function_name    = "chaos_monkey_lambda"
  handler          = "chaos.handler"
  role             = "${module.iam_assume_role.this_iam_role_arn}"
  runtime          = "python3.6"
  source_code_hash = "${base64sha256(file("${path.module}/../package.zip"))}"
  filename         = "${path.module}/../package.zip"

  environment {
    variables {
      region         = "us-east-1,us-west-2"
      probability    = "1"
      unleash_chaos  = "no"
      asg_group_name = "monkey_target"
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.chaos_lambda.function_name}"
  principal     = "events.amazonaws.com"
  statement_id  = "AlowExecutionFromCloudWatch"
  source_arn    = "${aws_cloudwatch_event_rule.scheduler.arn}"
}

###
# CloudWatch
###
resource "aws_cloudwatch_event_rule" "scheduler" {
  name                = "chaos_scheduler"
  description         = "This rule will trigger Lambda 9-3 5 days a week"
  schedule_expression = "cron(0/5 15-21 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "target" {
  arn  = "${aws_lambda_function.chaos_lambda.arn}"
  rule = "${aws_cloudwatch_event_rule.scheduler.name}"
}

###
# Alert
###
# TODO send alert if killing happen

###
# DB
###
# TODO keep information in SDB or Dynamodb or whatnot as same as SimianMonkey

provider "aws" {
  region  = "us-east-1"
  profile = "saml"
}
