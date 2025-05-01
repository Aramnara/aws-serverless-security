import json
import boto3
import logging
import re

# Setup structured logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info({
        "action": "LambdaInvocation",
        "event_received": event
    })

    # Input Validation: Ensure 'username' query param is provided and valid
    query_string_params = event.get('queryStringParameters') or {}
    username = query_string_params.get('username')

    # Updated regex: letters and numbers only, 3–30 characters
    if not username or not re.match(r"^[a-zA-Z0-9]{3,30}$", username):
        logger.warning({
            "action": "InputValidationFailed",
            "error": "Missing or invalid 'username'",
            "username_received": username
        })
        return {
            "statusCode": 400,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "error": "Missing or invalid 'username'. Must be 3–30 characters, letters/numbers only."
            }),
            "isBase64Encoded": False
        }

    # Secret Retrieval
    secret_name = "serverless-demo-secret"
    region_name = "us-east-1"
    client = boto3.client('secretsmanager', region_name=region_name)

    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
        secret = json.loads(get_secret_value_response['SecretString'])
        logger.info({
            "action": "SecretRetrieved",
            "secret_name": secret_name
        })
    except Exception as e:
        logger.error({
            "action": "SecretRetrievalFailed",
            "error_message": str(e)
        })
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({"error": "Unable to retrieve secret"}),
            "isBase64Encoded": False
        }

    # Successful Response
    response = {
        "message": f"Hello, {username}!",
        "retrieved_secret": secret
    }

    logger.info({
        "action": "RequestSuccessful",
        "username": username,
        "response_summary": {
            "status": 200,
            "message": f"Hello, {username}!"
        }
    })

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response),
        "isBase64Encoded": False
    }

