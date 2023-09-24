import json
import os

import boto3
from aws_lambda_powertools.logging.logger import Logger
from aws_lambda_powertools.utilities.data_classes import (
    SQSEvent,
    event_source,
)

SENDER_MAIL_ADDRESS = os.environ["SENDER_MAIL_ADDRESS"]
# QUEUE_URL = os.environ["QUEUE_URL"]
# dynamodb = boto3.client("dynamodb")
s3 = boto3.client("s3")
ses = boto3.client("ses")
logger = Logger()


@event_source(data_class=SQSEvent)
@logger.inject_lambda_context(log_event=True)
def lambda_handler(event: SQSEvent, context):
    for record in event.records:
        try:
            email = record.body
            message_attributes = record["messageAttributes"]
            bucket_name = message_attributes["bucket_name"]["stringValue"]
            filename = message_attributes["filename"]["stringValue"]

            response = s3.get_object(Bucket=bucket_name, Key=filename)
            _mail_body = response["Body"].read().decode("utf-8")
            subject, _, mail_body = _mail_body.split("\n", 3)

            response = ses.send_email(
                Source=SENDER_MAIL_ADDRESS,
                ReplyToAddresses=[SENDER_MAIL_ADDRESS],
                Destination={"ToAddresses": [email]},
                Message={
                    "Subject": {"Data": subject},
                    "Body": {"Text": {"Data": mail_body, "Charset": "UTF-8"}},
                },
            )
            logger.debug(json.dumps(response))

        except Exception as e:
            logger.error(e)

    return {
        "statusCode": 200,
        "body": json.dumps("success"),
    }
