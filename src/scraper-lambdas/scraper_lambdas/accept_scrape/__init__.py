import boto3
import os
import json


def handler(event, context):
    SQS_QUEUE_NAME = os.environ["SQS_QUEUE_NAME"]
    sqs = boto3.resource("sqs")
    queue = sqs.get_queue_by_name(QueueName=SQS_QUEUE_NAME)

    # TODO: validate incoming request
    if False:
        return
    message = {"hello": "world"}
    message_json = json.dumps(message)
    response = queue.send_message(MessageBody=message_json)
    return response["MessageId"]
