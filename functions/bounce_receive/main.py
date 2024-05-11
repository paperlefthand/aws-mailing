import json
import os

import boto3
from aws_lambda_powertools import Tracer
from aws_lambda_powertools.logging.logger import Logger
from aws_lambda_powertools.utilities.data_classes import SNSEvent, event_source

TABLE_NAME = os.environ["TABLE_NAME"]
dynamodb = boto3.client("dynamodb")
logger = Logger()
tracer = Tracer()


@event_source(data_class=SNSEvent)
@tracer.capture_lambda_handler
@logger.inject_lambda_context(log_event=True)
def lambda_handler(event: SNSEvent, context):
    for record in event.records:
        try:
            message = record.sns.message
            data = json.loads(message)
            logger.info(data)

            if data["notificationType"] == "Bounce":
                bounces = data["bounce"]["bouncedRecipients"]
                for bounce in bounces:
                    email = bounce["emailAddress"]
                    response = dynamodb.update_item(
                        TableName=TABLE_NAME,
                        Key={"email": {"S": email}},
                        UpdateExpression="SET haserror = :haserror",
                        ExpressionAttributeValues={":haserror": {"N": "1"}},
                    )
                    logger.debug(response)

        except Exception as e:
            logger.exception(e)

    return {
        "statusCode": 200,
        "body": json.dumps("success"),
    }
