# AWS Serverless Security - Zero Trust Approach

This project secures a serverless AWS application using a zero-trust model. Built with AWS Lambda, API Gateway, IAM, and Security Hub.

## Project Structure
- `infra/` – Terraform setup
- `lambda/` – Lambda functions
- `docs/` – Architecture diagrams, policies
- `logs/` – Placeholder/example logs

## Getting Started
1. Clone this repo
2. Run Terraform to deploy base infrastructure
3. Develop and secure Lambda functions
4. Implement logging and compliance checks

## Team Roles
- Anthony: Project Lead & IAM, Infra Setup
- Arun: Serverless & API Security
- Peter: Threat Detection & Logging
- Gagen: Compliance & Data Protection

## Role-Based Templates
- Arun: `lambda/templates/handler_api_template.py`
- Peter: `lambda/templates/logging_cloudwatch_template.py`
- Gagen: `lambda/templates/secrets_manager_template.py`

Each team member should use these as a base and implement/test in their own module.

### AWS Access
Each team member will be provisioned with IAM credentials for a shared AWS environment. Use these credentials to authenticate via the AWS CLI (`aws configure`) and begin deploying/testing resources in your assigned modules.

