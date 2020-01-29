#!//bin/bash

# bash script to build HFK - Kajiado Children's Home Dynamo Environment
# Author: John P. Chao

# Assumption: AWS CLI installed

# Setup Variables
  BaseDir="$HOME/environment/KCH-App"
  RunID=$(date +%s)
  AppName="kch-matumaini" # Not used
  JSONDir="$BaseDir/aws-cli"    # Directory to hold AWS JSON config files
  WebDir="$BaseDir/web"
  CFNDir="$BaseDir/cfn"
  OutputDir="$BaseDir/output"
  
  WebSiteBucketPolicy="$JSONDir/website-bucket-policy.json"  # Website S3 policy
  WebIndexPage="$WebDir"/index.html  # Website index page
  
  InfraCoreStackName="KCHMatumainiCoreStack" 
  InfraCoreStackConfig="$CFNDir/core.yml" 
#  InfraCoreStackOutput="$OutputDir/infra-core-output.json.$RunID"

# Hard code for now
  InfraCoreStackOutput="$OutputDir/infra-core-output.json.1557428040"

  
  ECSCluster="KCHMatumaini-Cluster"
  ECSTaskDefinition="$JSONDir/ecs-task-definition.json"
  ECSServiceDefinition="$JSONDir/service-definition.json"
  
  DockerImageOutput=$OutputDir/docker-image-output.$RunID
  DockerECROutput=$OutputDir/docker-ECR-output.$RunID
  DockerAppLogOutput=$OutputDir/docker-AppLog-output.$RunID
  DockerECSClusterOutput=$OutputDir/docker-ECS-output.$RunID
  DockerECSTaskOutput=$OutputDir/docker-ECS-Task-output.$RunID
  ECSServiceDefinitionOutput=$OutputDir/service-definition-output.$RunID
  DockerAppDir="$BaseDir/app"
  DockerAppName="kchmatumaini"
  
  NLBOutput=$OutputDir/nlb-output.json.$RunID
  NLBTargetGroupOutput=$OutputDir/nlb-target-group.json.$RunID
  NLBListenerpOutput=$OutputDir/nlb-listener.json.$RunID
  NLBTargetGroupName=KCHMatumaini
  NLBIndexPage="$WebDir"/index-nlb.html  # Website index page
  
  DBTable="KCHMatumainiDB"  # DynamoDB table
  DBTableSchema="$JSONDir/dynamodb-table.json"
  DBTableData="$JSONDir/populate-dynamodb.json"

#New variables below
  CodeS3Bucket="kch-matumaini-source" # S3 Bucket to for application code

  CodeBucketPolicy="$JSONDir/artifacts-bucket-policy.json"  # Code Artifacts S3 policy
  CodeBucketPolicyOutput="$OutputDir/artifacts-bucket-policy-output.json.$RunID"
  CodeCommitRepo=$AppName-Repo

  CodeBuildProject="$JSONDir/code-build-project.json"  # Code Artifacts S3 policy
  CodeBuildProjectOutput="$OutputDir/code-build-project-output.json.$RunID"
  
  CodePipeline="$JSONDir/code-pipeline.json"  # Code Pipeline
  CodePipelineOutput="$OutputDir/code-pipeline-output.json.$RunID"

  EcrPolicy="$JSONDir/ecr-policy.json"  # Code Pipeline
  EcrPolicyOutput="$OutputDir/ecr-policy-output.json.$RunID"
#################
#
# ACTION REQUIRED
#
# ADD CODE TO MAKE SURE ALL SOURCE FILES AND OUTPUT DIRECTORIES EXIST
#
# NEED TO MAKE THIS SCRIPT EXECUTE IDEPONTENTLY
#
#################

# Function to replace all "Stubs" with AWS instance values
#
# First parameter passed ($1) in will be the filename followed by one or more
# replacement values.
# 
# This function will generate a new file based on first parameter with RunID
# appended to the filename.
FILE_Replace() {
  if [ $# != 3 ]; then
    echo "First paramater must be a configuration file."
    echo "Second paramater must be the string that will be replaced."
    echo "Third parameter must be the new string"
    exit 1
  fi
  
  echo $2
  echo $3
  sed 's/"$2"/"$3"/g' $1 > $1.$RunID
}

#FILE_Replace $ECSTaskDefinition "REPLACE_ME_ECS_SERVICE_ROLE_ARN" "arn:aws:iam::422389313567:role/KCHMatumainiCoreStack-EcsServiceRole-1HB3W6PVJDZWH"
#FILE_Replace $ECSTaskDefinition.$RunID REPLACE_ME_ECS_TASK_ROLE_ARN arn:aws:iam::422389313567:role/KCHMatumainiCoreStack-ECSTaskRole-9GB16RY4SQFF
#exit


JSON_Replace() {

  # test / debug code
  #echo "String to find $1"
  #echo "File to find string $2"
  
  # The instance value is the 4th element on the line.
  TmpValue=$(grep $1 -A3 $2 | grep "OutputValue" | cut -d'"' -f 4)
  echo $TmpValue
}

JSON_Get() {

  # test / debug code
  #echo "String to find $1"
  #echo "File to find string $2"
  
  # The instance value is the 4th element on the line.
  TmpValue=$(grep $1 $2 | cut -d'"' -f 4)
  echo $TmpValue
}

# Variables and functions defined above.

# Test Code Below

# test / debug code
#Foo="$OutputDir/infra-core-output.1555618670.json"
#JSON_Replace "REPLACE_ME_ACCOUNT_ID" "$Foo"
#exit

# Test Code Above

# Start Module 3

# Step 1 A - Create DynamoDB Table

echo "Creating DynamoDB Table"
aws dynamodb create-table --cli-input-json file://$DBTableSchema
if [ "$?" = "0" ]; then
  echo "Created Code Pipeline"
else
  echo "Error Creating Code Pipeline"
  exit 1
fi

echo "Naming DynamoDB Table"
aws dynamodb describe-table --table-name $DBTable

sleep 300

aws dynamodb scan --table-name $DBTable

echo "Populating DynamoDB Table"
aws dynamodb batch-write-item --request-items file://$DBTableData

aws dynamodb scan --table-name $DBTable