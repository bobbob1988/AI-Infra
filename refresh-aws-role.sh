#!/bin/bash

# Assume the role and get temporary credentials
CREDENTIALS=$(aws sts assume-role --role-arn arn:aws:iam::881490132681:role/AIInfraDev --role-session-name my-session --profile default)

# Extract the credentials
ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r .Credentials.AccessKeyId)
SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r .Credentials.SecretAccessKey)
SESSION_TOKEN=$(echo $CREDENTIALS | jq -r .Credentials.SessionToken)

# Update the profile with new credentials
aws configure set aws_access_key_id $ACCESS_KEY_ID --profile aiinfra
aws configure set aws_secret_access_key $SECRET_ACCESS_KEY --profile aiinfra
aws configure set aws_session_token $SESSION_TOKEN --profile aiinfra

echo "AWS credentials refreshed successfully!"
echo "You can now use the 'aiinfra' profile with: aws --profile aiinfra <command>" 