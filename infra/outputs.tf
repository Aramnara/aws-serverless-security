output "lambda_function_name" {
  value = aws_lambda_function.secure_lambda.function_name
}

output "api_endpoint" {
  value = "https://${aws_api_gateway_rest_api.rest_api.id}.execute-api.us-east-1.amazonaws.com/prod/hello"
}

