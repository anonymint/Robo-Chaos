###
# Lambda Role Policy
###
module "iam_assume_role" {
  source                        = "anonymint/iam-role/aws"
  role_name                     = "lambda-chaos-monkey-execution-role"
  policy_arns_count             = "3"
  policy_arns                   = ["arn:aws:iam::152303423357:policy/sre/chaos_monkey", "arn:aws:iam::aws:policy/AWSOpsWorksCloudWatchLogs", "arn:aws:iam::aws:policy/AmazonSNSFullAccess"]
  create_instance_role          = false
  iam_role_policy_document_json = "${data.aws_iam_policy_document.lambda_role_policy.json}"
}

module "iam_assume_role_basic_execution" {
  source                        = "anonymint/iam-role/aws"
  role_name                     = "lambda-basic-execution-trigger-by-sns-role"
  policy_arns_count             = "1"
  policy_arns                   = ["arn:aws:iam::aws:policy/AWSOpsWorksCloudWatchLogs"]
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

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../chaos.py"
  output_path = "${path.module}/chaos_package.zip"
}

resource "aws_lambda_function" "chaos_lambda" {
  function_name    = "chaos_monkey"
  handler          = "chaos.handler"
  role             = "${module.iam_assume_role.this_iam_role_arn}"
  runtime          = "python3.6"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  filename         = "${path.module}/chaos_package.zip"

  environment {
    variables {
      region         = "us-east-1,us-west-2"
      probability    = "1"
      unleash_chaos  = "no"
      asg_group_name = "monkey_target"
      sns_alert_arn  = "${aws_sns_topic.alert.arn}"
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

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.chaos_lambda.function_name}"
  retention_in_days = "7"
}

###
# Alert
###
# TODO send alert if killing happen
data "archive_file" "microsoft_connector_zip" {
  type        = "zip"
  source_file = "${path.module}/hook.py"
  output_path = "${path.module}/hook_package.zip"
}

resource "aws_lambda_function" "hook_lambda" {
  function_name    = "alert_hook"
  handler          = "hook.handler"
  role             = "${module.iam_assume_role_basic_execution.this_iam_role_arn}"
  runtime          = "python3.6"
  source_code_hash = "${data.archive_file.microsoft_connector_zip.output_base64sha256}"
  filename         = "${path.module}/hook_package.zip"

  environment {
    variables {
      hook_url = "${var.hook_url}"
    }
  }
}

resource "aws_lambda_permission" "allow_sns" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.hook_lambda.function_name}"
  principal     = "sns.amazonaws.com"
  statement_id  = "AlowExecutionFromSNS"
  source_arn    = "${aws_sns_topic.alert.arn}"
}

resource "aws_sns_topic" "alert" {
  name = "chaos-alert"
}

resource "aws_sns_topic_subscription" "lambda_sub" {
  endpoint  = "${aws_lambda_function.hook_lambda.arn}"
  protocol  = "lambda"
  topic_arn = "${aws_sns_topic.alert.arn}"
}

###
# DB
###
# TODO keep information in SDB or Dynamodb or whatnot as same as SimianMonkey

provider "aws" {
  region  = "us-east-1"
}
