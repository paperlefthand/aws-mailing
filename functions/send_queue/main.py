import json
import os

import boto3
from aws_lambda_powertools.logging.logger import Logger
from aws_lambda_powertools.utilities.data_classes import S3Event, event_source

TABLE_NAME = os.environ["TABLE_NAME"]
QUEUE_URL = os.environ["QUEUE_URL"]
dynamodb = boto3.client("dynamodb")
sqs = boto3.client("sqs")
logger = Logger()


@event_source(data_class=S3Event)
@logger.inject_lambda_context(log_event=True)
def lambda_handler(event: S3Event, context):
    for record in event.records:
        try:
            bucket_name = record.s3.bucket.name
            filename = record["s3"]["object"]["key"]

            response = dynamodb.query(
                TableName=TABLE_NAME,
                KeyConditionExpression="haserror = :haserror",
                ExpressionAttributeValues={":haserror": {"N": "0"}},
                IndexName="haserror-index",
            )
            logger.debug(json.dumps(response))
        except Exception as e:
            logger.error(e)

        else:
            for item in response["Items"]:
                try:
                    username = item["username"]["S"]
                    response = sqs.send_message(
                        QueueUrl=QUEUE_URL,
                        MessageBody=item["email"]["S"],
                        MessageGroupId=username,
                        MessageAttributes={
                            "username": {
                                "DataType": "String",
                                "StringValue": username,
                            },
                            "bucket_name": {
                                "DataType": "String",
                                "StringValue": bucket_name,
                            },
                            "filename": {"DataType": "String", "StringValue": filename},
                        },
                    )
                    logger.debug(json.dumps(response))

                except Exception as e:
                    logger.error(e)

    return {
        "statusCode": 200,
        "body": json.dumps("success"),
    }
