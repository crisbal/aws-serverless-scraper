import boto3
import datetime
import os
import uuid
import json

def handler(event, context):
    records = event.get("Records", [])
    for record in records:
        record_json = record["body"]
        record = json.loads(record_json)
        dynamodb = boto3.client('dynamodb')
        dynamodb.put_item(
            TableName=os.environ['DYNAMODB_TABLE_NAME'],
            Item={
                'Id': {'S': str(uuid.uuid4())},
                'ts': {'S': datetime.datetime.now().isoformat()}
            },
        )
    return f"Processed {len(records)} records"
