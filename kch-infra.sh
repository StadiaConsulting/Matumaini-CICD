#!//bin/bash

# bash script to build HFK - Kajiado Children's Home App Environment
# Author: John P. Chao

# Assumption: AWS CLI installed

# Setup Variables
  BaseDir="$HOME/environment/KCH-App"
  RunID=$(date +%s)
  AppName="kch-matumaini"     # Not used
  WebS3Bucket="kch-matumaini" # S3 Bucket to host static files.  If this changes, look for other files that will also require updates.
  JSONDir="$BaseDir/aws-cli"  # Directory to hold AWS JSON config files
  WebDir="$BaseDir/web"
  CFNDir="$BaseDir/cfn"
  OutputDir="$BaseDir/output"
  
  WebSiteBucketPolicy="$JSONDir/website-bucket-policy.json"  # Website S3 policy
  WebIndexPage="$WebDir"/index.html  # Website index page
  
  InfraCoreStackName="KCHMatumainiCoreStack" 
  InfraCoreStackConfig="$CFNDir/core.yml" 
  InfraCoreStackOutput="$OutputDir/infra-core-output.json.$RunID"
  
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
  
  DBTable="KCHTable"  # DynamoDB table

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

# Step 1 - Create S3 bucket for static website
aws s3 mb s3://$WebS3Bucket
if [ "$?" = "0" ]; then
  echo "Created $WebS3Bucket S3 bucket"
else
  echo "Error creating $WebS3Bucket"
  exit 1
fi

# Step 2 - Create Website Index
aws s3 website s3://$WebS3Bucket --index-document index.html
if [ "$?" = "0" ]; then
  echo "Configured $WebS3Bucket index file to use index.html"
else
  echo "Error configuring $WebS3Bucket to use index.html as index file"
  exit 1
fi

# Step 3 - Set AWS S3 bucket policy
aws s3api put-bucket-policy --bucket $WebS3Bucket --policy file://$WebSiteBucketPolicy
if [ "$?" = "0" ]; then
  echo "Set $WebS3Bucket S3 bucket policy"
else
  echo "Error setting $WebS3Bucket S3 bucket policy to $WebSiteBucketPolicy"
  exit 1
fi

# Step 4 - Copy index.html to S3 Web Bucket
aws s3 cp "$WebIndexPage" s3://$WebS3Bucket/index.html
#aws s3 cp index.html s3://$WebS3Bucket/index.html  # DEBUG LATER
if [ "$?" = "0" ]; then
  echo "Copied $WebIndexPage S3 bucket policy"
else
  echo "Error copying $WebIndexPage to S3 bucket"
  exit 1
fi

# Step 5 - Build Core Infrastucture Stack - Including VPC, NAT Gateway, Private Subnets, etc.
aws cloudformation create-stack --stack-name $InfraCoreStackName --capabilities CAPABILITY_NAMED_IAM --template-body file://$InfraCoreStackConfig
if [ "$?" = "0" ]; then
echo -n "Started creation of $InfraCoreStackName Stack.  Waiting to generate stack output file."
  aws cloudformation describe-stacks --stack-name $InfraCoreStackName | grep -q "CREATE_COMPLETE"
  while [ "$?" != "0" ]; do
    # Keep looping until the stack build is completed.
    sleep 60
    echo -n "."
    aws cloudformation describe-stacks --stack-name $InfraCoreStackName | grep -q "CREATE_COMPLETE"
  done
  # Generate Core Stack output with ARNs that will be used in future environment builds.
  aws cloudformation describe-stacks --stack-name $InfraCoreStackName > $InfraCoreStackOutput
  echo "Done"
else
  echo "Error creating $InfraCoreStackName stack"
  exit 1
fi


# Step 6 - Build Docker Image (Flask) (This will be replaced by CI/CD)
#cd $DockerAppDir
REPLACE_ME_ACCOUNT_ID=$(JSON_Replace REPLACE_ME_ACCOUNT_ID $InfraCoreStackOutput)
echo "AWS Account = $REPLACE_ME_ACCOUNT_ID"

REPLACE_ME_REGION=$(JSON_Replace REPLACE_ME_REGION $InfraCoreStackOutput)
echo "AWS Account = $REPLACE_ME_REGION"

tmpDocker="$REPLACE_ME_ACCOUNT_ID.dkr.ecr.$REPLACE_ME_REGION.amazonaws.com/$DockerAppName/service:latest"
# FOR NOW - DONE ON COMMANDLINE
echo "enter in shell prompt: docker build -t $tmpDocker . > $DockerImageOutput"
read WAIT
echo "Proceeding..."
# 

# Step 7 - Push Docker Image to Elastic Container Repository (ECR)
aws ecr create-repository --repository-name $DockerAppName/service > $DockerECROutput
if [ "$?" = "0" ]; then
  echo "Created $tmpDocker repository in ECR"
else
  echo "Error creating $tmpDocker repository in ECR"
  exit 1
fi

cd $BaseDir

# Step 8 - Push docker image to newly created ECR (This will be replaced by CI/CD)
echo "enter at shell prompt: '\$(aws ecr get-login --no-include-email)'"
echo "docker push $tmpDocker"
read WAIT
echo "Proceeding..."

# Step 9 - Build Fargate Cluster
aws ecs create-cluster --cluster-name $ECSCluster > $DockerECSClusterOutput
aws logs create-log-group --log-group-name "$DockerAppName"-logs > $DockerAppLogOutput
# Insert search replace for ARN in JSON config
REPLACE_ME_ECS_SERVICE_ROLE_ARN=$(JSON_Replace REPLACE_ME_ECS_SERVICE_ROLE_ARN $InfraCoreStackOutput)
echo "REPLACE_ME_ECS_SERVICE_ROLE_ARN = $REPLACE_ME_ECS_SERVICE_ROLE_ARN"
REPLACE_ME_ECS_TASK_ROLE_ARN=$(JSON_Replace REPLACE_ME_ECS_TASK_ROLE_ARN $InfraCoreStackOutput)
echo "REPLACE_ME_ECS_TASK_ROLE_ARN = $REPLACE_ME_ECS_TASK_ROLE_ARN"

cp -p $ECSTaskDefinition $ECSTaskDefinition.$RunID
echo "Edit $ECSTaskDefinition.$RunID"
read WAIT
echo "Proceeding..."
aws ecs register-task-definition --cli-input-json file://$ECSTaskDefinition.$RunID > $DockerECSTaskOutput


# Step 10 - Build NLB and enable NLB Fargate Services
REPLACE_ME_PUBLIC_SUBNET_ONE=$(JSON_Replace REPLACE_ME_PUBLIC_SUBNET_ONE $InfraCoreStackOutput)
echo "REPLACE_ME_PUBLIC_SUBNET_ONE = $REPLACE_ME_PUBLIC_SUBNET_ONE"
REPLACE_ME_PUBLIC_SUBNET_TWO=$(JSON_Replace REPLACE_ME_PUBLIC_SUBNET_TWO $InfraCoreStackOutput)
echo "REPLACE_ME_PUBLIC_SUBNET_TWO = $REPLACE_ME_PUBLIC_SUBNET_TWO"
aws elbv2 create-load-balancer --name $DockerAppName-nlb --scheme internet-facing --type network --subnets $REPLACE_ME_PUBLIC_SUBNET_ONE $REPLACE_ME_PUBLIC_SUBNET_TWO > $NLBOutput

REPLACE_ME_VPC_ID=$(JSON_Replace REPLACE_ME_VPC_ID $InfraCoreStackOutput)
echo "REPLACE_ME_VPC_ID = $REPLACE_ME_VPC_ID"
aws elbv2 create-target-group --name $NLBTargetGroupName-TargetGroup --port 8080 --protocol TCP --target-type ip --vpc-id $REPLACE_ME_VPC_ID --health-check-interval-seconds 10 --health-check-path / --health-check-protocol HTTP --healthy-threshold-count 3 --unhealthy-threshold-count 3 > $NLBTargetGroupOutput

REPLACE_ME_NLB_TARGET_GROUP_ARN=$(JSON_Get TargetGroupArn $NLBTargetGroupOutput)
echo "REPLACE_ME_NLB_TARGET_GROUP_ARN = $REPLACE_ME_NLB_TARGET_GROUP_ARN"
REPLACE_ME_NLB_ARN=$(JSON_Get LoadBalancerArn $NLBOutput)
echo "REPLACE_ME_NLB_ARN = $REPLACE_ME_NLB_ARN"
aws elbv2 create-listener --default-actions TargetGroupArn=$REPLACE_ME_NLB_TARGET_GROUP_ARN,Type=forward --load-balancer-arn $REPLACE_ME_NLB_ARN --port 80 --protocol TCP > $NLBListenerpOutput

# Step 11 - IAM Service Linked role for ECS
aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com

# Step 12 - Create Service with Fargate
REPLACE_ME_SECURITY_GROUP_ID=$(JSON_Replace REPLACE_ME_SECURITY_GROUP_ID $InfraCoreStackOutput)
echo "REPLACE_ME_SECURITY_GROUP_ID = $REPLACE_ME_SECURITY_GROUP_ID"
REPLACE_ME_PRIVATE_SUBNET_ONE=$(JSON_Replace REPLACE_ME_PRIVATE_SUBNET_ONE $InfraCoreStackOutput)
echo "REPLACE_ME_PRIVATE_SUBNET_ONE = $REPLACE_ME_PRIVATE_SUBNET_ONE"
REPLACE_ME_PRIVATE_SUBNET_TWO=$(JSON_Replace REPLACE_ME_PRIVATE_SUBNET_TWO $InfraCoreStackOutput)
echo "REPLACE_ME_PRIVATE_SUBNET_TWO = $REPLACE_ME_PRIVATE_SUBNET_TWO"
echo "REPLACE_ME_NLB_TARGET_GROUP_ARN = $REPLACE_ME_NLB_TARGET_GROUP_ARN"

cp -p $ECSServiceDefinition $ECSServiceDefinition.$RunID
echo "Edit $ECSServiceDefinition.$RunID"
read WAIT
echo "Proceeding..."
aws ecs create-service --cli-input-json file://$ECSServiceDefinition.$RunID > $ECSServiceDefinitionOutput

# Step 13 - Enable App to use NLB
REPLACE_ME_URL=$(JSON_Get DNSName $NLBOutput)
echo "REPLACE_ME_URL = 'http://$REPLACE_ME_URL'"

cp -p $NLBIndexPage $NLBIndexPage.$RunID
echo "Edit $NLBIndexPage.$RunID"
read WAIT
echo "Proceeding..."

aws s3 cp "$NLBIndexPage.$RunID" s3://$WebS3Bucket/index.html
if [ "$?" = "0" ]; then
  echo "Copied $NLBIndexPage.$RunID S3 bucket policy"
else
  echo "Error copying $NLBIndexPage.$RunID to S3 bucket"
  exit 1
fi

# Start Module 2C

# Step 2C A - Create S3 bucket for static website
aws s3 mb s3://$CodeS3Bucket
if [ "$?" = "0" ]; then
  echo "Created $CodeS3Bucket S3 bucket"
else
  echo "Error creating $CodeS3Bucket"
  exit 1
fi

# Step 2C B - Set AWS S3 bucket policy
REPLACE_ME_CODEBUILD_ROLE_ARN=$(JSON_Replace REPLACE_ME_CODEBUILD_ROLE_ARN $InfraCoreStackOutput)
echo "REPLACE_ME_CODEBUILD_ROLE_ARN = $REPLACE_ME_CODEBUILD_ROLE_ARN"
REPLACE_ME_CODEPIPELINE_ROLE_ARN=$(JSON_Replace REPLACE_ME_CODEPIPELINE_ROLE_ARN $InfraCoreStackOutput)
echo "REPLACE_ME_CODEPIPELINE_ROLE_ARN = $REPLACE_ME_CODEPIPELINE_ROLE_ARN"
echo "REPLACE_ME_ARTIFACTS_BUCKET_NAME = $CodeS3Bucket"
echo "Proceeding..."

cp -p $CodeBucketPolicy $CodeBucketPolicy.$RunID
echo "Edit $CodeBucketPolicy.$RunID"
read WAIT
echo "Proceeding..."

aws s3api put-bucket-policy --bucket $CodeS3Bucket --policy file://$CodeBucketPolicy.$RunID
if [ "$?" = "0" ]; then
  echo "Set $CodeS3Bucket S3 bucket policy"
else
  echo "Error setting $CodeS3Bucket S3 bucket policy to $CodeBucketPolicy"
  exit 1
fi


# Step 2C B - Create CodeCommit Repository
aws codecommit create-repository --repository-name $CodeCommitRepo
if [ "$?" = "0" ]; then
  echo "Created $CodeCommitRepo CodeCommit Repository"
else
  echo "Error Creating $CodeCommitRepo CodeCommit Repository"
  exit 1
fi

# Step 2C C - Create Code Build Project
echo "REPLACE_ME_CODEBUILD_ROLE_ARN = $REPLACE_ME_CODEBUILD_ROLE_ARN"
echo "REPLACE_ME_REGION = $REPLACE_ME_REGION"
echo "REPLACE_ME_ACCOUNT_ID = $REPLACE_ME_ACCOUNT_ID"
echo "Proceeding..."

cp -p $CodeBuildProject $CodeBuildProject.$RunID
echo "Edit $CodeBuildProject.$RunID"
read WAIT
echo "Proceeding..."

aws codebuild create-project --cli-input-json file://$CodeBuildProject.$RunID > $CodeBuildProjectOutput
if [ "$?" = "0" ]; then
  echo "Created $CodeCommitRepo CodeCommit Repository"
else
  echo "Error Creating $CodeCommitRepo CodeCommit Repository"
  exit 1
fi

# Step 2C D - Create Pipeline in CodePipeline

echo "REPLACE_ME_CODEPIPELINE_ROLE_ARN = $REPLACE_ME_CODEPIPELINE_ROLE_ARN"
echo "REPLACE_ME_ARTIFACTS_BUCKET_NAME = $CodeS3Bucket"

cp -p $CodePipeline $CodePipeline.$RunID
echo "Edit $CodePipeline.$RunID"
read WAIT
echo "Proceeding..."
aws codepipeline create-pipeline --cli-input-json file://$CodePipeline.$RunID > $CodePipelineOutput
if [ "$?" = "0" ]; then
  echo "Created Code Pipeline"
else
  echo "Error Creating Code Pipeline"
  exit 1
fi

# Step 2C E - Enable automated push to ECR
echo "REPLACE_ME_CODEBUILD_ROLE_ARN = $REPLACE_ME_CODEBUILD_ROLE_ARN"
cp -p $EcrPolicy $EcrPolicy.$RunID
echo "Edit $EcrPolicy.$RunID"
read WAIT
echo "Proceeding..."

aws ecr set-repository-policy --repository-name $DockerAppName/service --policy-text  file://$EcrPolicy.$RunID > $EcrPolicyOutput
if [ "$?" = "0" ]; then
  echo "Created Code Pipeline"
else
  echo "Error Creating Code Pipeline"
  exit 1
fi