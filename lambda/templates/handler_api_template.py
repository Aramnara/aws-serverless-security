import json

def lambda_handler(event, context):
    # Extract data from request
    try:
        print("Received event:", json.dumps(event))
        
        # Example response
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "message": "Lambda function hit successfully"
            })
        }

    except Exception as e:
        print("Error:", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }

