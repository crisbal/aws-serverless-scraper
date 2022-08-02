import boto3
import datetime
import os
import uuid

def handler(event, lambda_contex):
    dynamodb = boto3.client('dynamodb')
    dynamodb.put_item(
        TableName=os.environ['DYNAMODB_TABLE_NAME'],
        Item={
            'Id': {'S': str(uuid.uuid4())},
            'ts': {'S': datetime.datetime.now().isoformat()}
        },
    )
