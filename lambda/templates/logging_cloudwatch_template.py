import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Lambda triggered with event: %s", json.dumps(event))

    # Placeholder logic
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Logging Lambda executed"})
    }

