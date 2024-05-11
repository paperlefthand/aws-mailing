import json
import os

import boto3
from aws_lambda_powertools import Tracer
from aws_lambda_powertools.logging.logger import Logger
from aws_lambda_powertools.utilities.data_classes import S3Event, event_source

TABLE_NAME = os.environ["TABLE_NAME"]
QUEUE_URL = os.environ["QUEUE_URL"]
dynamodb = boto3.client("dynamodb")
sqs = boto3.client("sqs")
logger = Logger()
tracer = Tracer()


@event_source(data_class=S3Event)
@tracer.capture_lambda_handler
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
            logger.debug(response)
        except Exception as e:
            logger.exception(e)

        else:
            for item in response["Items"]:
                try:
                    username = item["username"]["S"]
                    response = sqs.send_message(
                        QueueUrl=QUEUE_URL,
                        # TODO メールアドレス形式のvalidation
                        MessageBody=item["email"]["S"],
                        # バケット名/ファイル名で重複排除.SQSでコンテンツベースの重複排除が設定されている.
                        MessageGroupId=f"{bucket_name}/{filename}",
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
                    logger.debug(response)

                except Exception as e:
                    logger.exception(e)

    return {
        "statusCode": 200,
        "body": json.dumps("success"),
    }
