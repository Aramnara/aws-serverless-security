import boto3
import json
import os

def lambda_handler(event, context):
    secret_name = os.environ.get("SECRET_NAME", "test/secure/key")
    region_name = "us-east-1"

    client = boto3.client('secretsmanager', region_name=region_name)

    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
        secret = json.loads(get_secret_value_response['SecretString'])

        return {
            "statusCode": 200,
            "body": json.dumps({"retrieved_secret": secret})
        }

    except Exception as e:
        print("Secrets Manager error:", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }

