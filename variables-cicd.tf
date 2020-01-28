variable "AWSRegion" {
  description = "Default region for Stadia Consulting's AWS services."
  default = "us-east-1"
}

data "aws_availability_zones" "AZ" {}
data "aws_region" "AWSRegion" {}
data "aws_billing_service_account" "Account" {}

data "aws_s3_bucket" "AppCodeBucketRef" {
    bucket = "${aws_s3_bucket.AppCodeBucket.id}"
}
data "aws_iam_role" "CodeBuildRef" {
    name = "${aws_iam_role.KCHMatumainiServiceCodeBuildServiceRole.id}"
}
data "aws_iam_role" "CodePipelineRef" {
    name = "${aws_iam_role.KCHMatumainiServiceCodePipelineServiceRole.id}"
}
#data "aws_iam_role" "ECSServiceRef" {
#    name = "${aws_iam_role.EcsServiceRole.arn}"
#}
#data "aws_iam_role" "ECSSTaskRef" {
#    name = "${aws_iam_role.ECSTaskRole.arn}"
#}


variable "BaseS3Bucket" {
    default = "kch-matumaini"
}
variable "CodeS3Bucket" {
    default = "kch-matumaini-source"
}
variable "CodeCommitRepo" {
    default = "kch-matumaini-repo"
}

// shared with Main Infra build TF.  How to make sure they're in sync?  - John Action
variable "DockerAppName" {
    default ="kchmatumaini"
}
variable "ECSCluster" {
    default = "KCHMatumaini-Cluster"
}

variable "ECSService" {
    default = "KCHMatumaini-Service"
}
