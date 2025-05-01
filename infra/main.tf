# Full commented Terraform configuration for final project
# ==============================================================================
# FINAL TERRAFORM CONFIGURATION FOR SECURE SERVERLESS AWS PROJECT (SPRING 2025)
# Author: Anthony
# ==============================================================================
# This Terraform script provisions a secure, zero-trust serverless application
# in AWS using Lambda, API Gateway, WAF, IAM, Secrets Manager, CloudWatch,
# Security Hub, and is AWS Config ready.
# ==============================================================================
# ----------------------------------------------------
# IAM Role for Lambda Execution
# ----------------------------------------------------
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Basic Lambda execution permissions
resource "aws_iam_policy_attachment" "lambda_basic_execution" {
  name       = "lambda-basic-execution"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ----------------------------------------------------
# IAM Role for API Gateway to push logs to CloudWatch
# ----------------------------------------------------
resource "aws_iam_role" "apigw_logs_role" {
  name = "APIGatewayCloudWatchLogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "apigateway.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_role_policy_attachment" "apigw_logs_policy" {
  role       = aws_iam_role.apigw_logs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# IAM Policy to allow Lambda to access Secrets Manager
resource "aws_iam_policy" "lambda_secrets_policy" {
  name        = "lambda-secrets-access"
  description = "Allow Lambda to read from AWS Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["secretsmanager:GetSecretValue"],
      Resource = aws_secretsmanager_secret.my_secret.arn
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_secrets_policy_attach" {
  name       = "lambda-secrets-access-attach"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = aws_iam_policy.lambda_secrets_policy.arn
}

# -------------------------------------
# Lambda Function
# -------------------------------------
resource "aws_lambda_function" "secure_lambda" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.11"
  handler       = "lambda_function.lambda_handler"
  filename      = "${path.module}/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")
}

# -------------------------------------
# Secrets Manager - Simulated App Secrets
# -------------------------------------
resource "aws_secretsmanager_secret" "my_secret" {
  name        = "serverless-demo-secret"
  description = "Secret used for the serverless security project"
}

resource "aws_secretsmanager_secret_version" "my_secret_value" {
  secret_id     = aws_secretsmanager_secret.my_secret.id
  secret_string = jsonencode({
    username = "testuser"
    password = "SuperSecurePassword123!"
  })
}

# -------------------------------------
# REST API Gateway Setup (Secured via API Key + WAF)
# -------------------------------------
resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "secure-serverless-api"
  description = "REST API for secured Lambda access"
}

resource "aws_api_gateway_resource" "root_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "hello"
}

resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.root_resource.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.root_resource.id
  http_method = aws_api_gateway_method.get_method.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.secure_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "rest_deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id

  # add a trigger to force redeploys when Lambda changes
  triggers = {
    redeployment = timestamp()
  }
}

resource "aws_api_gateway_stage" "api_stage" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  deployment_id = aws_api_gateway_deployment.rest_deployment.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_logs.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      status                  = "$context.status"
      integrationStatus       = "$context.integration.status"
      responseLatency         = "$context.responseLatency"
      errorMessage            = "$context.error.message"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }

  depends_on = [aws_api_gateway_deployment.rest_deployment]
}

resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name              = "/aws/apigateway/serverless-secure-http-api"
  retention_in_days = 7
}

# -------------------------------------
# API Gateway Usage Plan (Rate Limiting)
# -------------------------------------
resource "aws_api_gateway_api_key" "secure_api_key" {
  name        = "secure-api-key"
  description = "API key for secure access"
  enabled     = true
}

resource "aws_api_gateway_usage_plan" "secure_usage_plan" {
  name = "secure-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.rest_api.id
    stage  = aws_api_gateway_stage.api_stage.stage_name
  }

  throttle_settings {
    burst_limit = 5
    rate_limit  = 2
  }
}

resource "aws_api_gateway_usage_plan_key" "secure_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.secure_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.secure_usage_plan.id
}

# -------------------------------------
# Allow API Gateway to Invoke Lambda
# -------------------------------------
resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secure_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"
}

# -------------------------------------
# AWS WAF - Protect API Gateway from Common Threats
# -------------------------------------
resource "aws_wafv2_web_acl" "api_acl" {
  name        = "serverless-waf-acl"
  scope       = "REGIONAL"
  description = "WAF to protect API Gateway"
  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-requests"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common-rule"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_association" "api_acl_attach" {
  resource_arn = "arn:aws:apigateway:us-east-1::/restapis/${aws_api_gateway_rest_api.rest_api.id}/stages/${aws_api_gateway_stage.api_stage.stage_name}"
  web_acl_arn  = aws_wafv2_web_acl.api_acl.arn
}

# -------------------------------------
# Enable Security Hub for Security Posture
# -------------------------------------
resource "aws_securityhub_account" "security_hub" {
  enable_default_standards = true
}
