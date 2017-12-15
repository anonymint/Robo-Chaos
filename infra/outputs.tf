output "lamba_arn" {
  description = "Chaos Monkey Lambda ARN"
  value       = "${aws_lambda_function.chaos_lambda.arn}"
}
