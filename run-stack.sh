#!/bin/bash
set -e
set -x

STACK_NAME=$1
ALB_LISTENER_ARN=$2

if ! aws cloudformation describe-stacks --region us-east-1 --stack-name $STACK_NAME 2>&1 > /dev/null
then
    finished_check=stack-create-complete
else
    finished_check=stack-update-complete
fi

aws cloudformation deploy \
    --region us-east-1 \
    --stack-name $STACK_NAME \
    --template-file service.yaml \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
    "DockerImage=351403397006.dkr.ecr.us-east-1.amazonaws.com/example-webapp:$(git rev-parse HEAD)" \
    "VPC=vpc-094b327a81363a5f4" \
    "Subnet=subnet-094493abe656b7a1c" \
    "Cluster=default" \
    "Listener=$ALB_LISTENER_ARN"

aws cloudformation wait $finished_check --region us-east-1 --stack-name $STACK_NAME
