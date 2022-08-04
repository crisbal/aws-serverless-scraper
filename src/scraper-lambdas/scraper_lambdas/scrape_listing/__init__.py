import boto3
import datetime
import os
import uuid
import json


def handler(event, context):
    DYNAMODB_TABLE_NAME = os.environ["DYNAMODB_TABLE_NAME"]
    dynamodb = boto3.client("dynamodb")
    records = event.get("Records", [])
    for record in records:
        record_json = record["body"]
        record = json.loads(record_json)
        dynamodb.put_item(
            TableName=DYNAMODB_TABLE_NAME,
            Item={
                "Id": {"S": str(uuid.uuid4())},
                "record": {"S": record_json},
                "ts": {"S": datetime.datetime.now().isoformat()},
            },
        )
    return f"Processed {len(records)} records"
