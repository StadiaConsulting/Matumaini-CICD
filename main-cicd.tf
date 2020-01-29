provider "aws" {
    region = var.AWSRegion
}

// Break out code for CICD
resource "aws_s3_bucket" "AppCodeBucket" {
    bucket  = "${var.CodeS3Bucket}"

    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_s3_bucket_policy" "AppCodeBucketPolicy" {
  bucket = "${aws_s3_bucket.AppCodeBucket.id}"

  policy = <<EOF
{
    "Statement": [
      {
        "Sid": "WhitelistedGet",
        "Effect": "Allow",
        "Principal": {
          "AWS": [
            "${data.aws_iam_role.CodeBuildRef.arn}",
            "${data.aws_iam_role.CodePipelineRef.arn}"
          ]
        },
        "Action": [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning"
        ],
        "Resource": [
          "arn:aws:s3:::${data.aws_s3_bucket.AppCodeBucketRef.id}/*",
          "arn:aws:s3:::${data.aws_s3_bucket.AppCodeBucketRef.id}"
        ]
      },
      {
        "Sid": "WhitelistedPut",
        "Effect": "Allow",
        "Principal": {
          "AWS": [
            "${data.aws_iam_role.CodeBuildRef.arn}",
            "${data.aws_iam_role.CodePipelineRef.arn}"
          ]
        },
        "Action": "s3:PutObject",
        "Resource": [
          "arn:aws:s3:::${data.aws_s3_bucket.AppCodeBucketRef.id}/*",
          "arn:aws:s3:::${data.aws_s3_bucket.AppCodeBucketRef.id}"
        ]
      }
    ]
}
  EOF
}

resource "aws_iam_role" "KCHMatumainiServiceCodePipelineServiceRole" {
  name = "KCHMatumainiServiceCodePipelineServiceRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
					{
						"Effect": "Allow",
						"Principal": {
							"Service": [
								"codepipeline.amazonaws.com"]
						},
						"Action": [
							"sts:AssumeRole"]
					}
				]
			}
EOF
}
resource "aws_iam_policy" "KCHMatumainiService-codepipeline-service-policy" {
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
	"Statement": [
		{
			"Action": [
				"codecommit:GetBranch",
				"codecommit:GetCommit",
				"codecommit:UploadArchive",
				"codecommit:GetUploadArchiveStatus",
				"codecommit:CancelUploadArchive"
			],
			"Resource": "*",
			"Effect": "Allow"
		},
		{
			"Action": [
				"s3:GetObject",
				"s3:GetObjectVersion",
				"s3:GetBucketVersioning"
			],
			"Resource": "*",
			"Effect": "Allow"
		},
		{
			"Action": [
				"s3:PutObject"
			],
			"Resource": [
				"arn:aws:s3:::*"
			],
			"Effect": "Allow"
		},
		{
			"Action": [
				"elasticloadbalancing:*",
				"autoscaling:*",
				"cloudwatch:*",
				"ecs:*",
				"codebuild:*",
				"iam:PassRole"
			],
			"Resource": "*",
			"Effect": "Allow"
		}
	]
}
EOF
}

resource "aws_iam_policy_attachment" "KCHMatumainiServiceCodePipelineServiceRoleAttachment" {
  name = "KCHMatumainiServiceCodePipelineServiceRoleAttachment"
  roles       = ["${aws_iam_role.KCHMatumainiServiceCodePipelineServiceRole.name}"]
  policy_arn = "${aws_iam_policy.KCHMatumainiService-codepipeline-service-policy.arn}"
}

resource "aws_iam_role" "KCHMatumainiServiceCodeBuildServiceRole" {
  name = "KCHMatumainiServiceCodeBuildServiceRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
					{
						"Effect": "Allow",
						"Principal": {
							"Service": [
								"codebuild.amazonaws.com"]
						},
						"Action": [
							"sts:AssumeRole"]
					}
				]
			}

EOF
}

resource "aws_iam_policy" "KCHMatumainiService-CodeBuildServicePolicy" {
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"codecommit:ListBranches",
				"codecommit:ListRepositories",
				"codecommit:BatchGetRepositories",
				"codecommit:Get*",
				"codecommit:GitPull"
			],
			"Resource":

					"arn:aws:codecommit:${data.aws_region.AWSRegion.name}:${data.aws_billing_service_account.Account.id}:KCHMatumainiServiceRepository"
		},
		{
			"Effect": "Allow",
			"Action": [
				"logs:CreateLogGroup",
				"logs:CreateLogStream",
				"logs:PutLogEvents"
			],
			"Resource": "*"
		},
		{
			"Effect": "Allow",
			"Action": [
				"s3:PutObject",
				"s3:GetObject",
				"s3:GetObjectVersion",
				"s3:ListBucket"
			],
			"Resource": "*"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ecr:InitiateLayerUpload",
				"ecr:GetAuthorizationToken"
			],
			"Resource": "*"
		}
	]
}
EOF
}

resource "aws_iam_policy_attachment" "KCHMatumainiServiceCodeBuildServiceRoleAttachment" {
  name = "KCHMatumainiServiceCodeBuildServiceRoleAttachment"
  roles       = ["${aws_iam_role.KCHMatumainiServiceCodeBuildServiceRole.name}"]
  policy_arn = "${aws_iam_policy.KCHMatumainiService-CodeBuildServicePolicy.arn}"
}

resource "aws_ecr_repository" "KCHMatumainiECR" {
  name = "${var.DockerAppName}/service"
}

resource "aws_ecr_repository_policy" "KCHMatumainiECRPolicy" {
  repository = "${aws_ecr_repository.KCHMatumainiECR.name}"

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "AllowPushPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
         "${aws_iam_role.KCHMatumainiServiceCodeBuildServiceRole.arn}"
        ]
      },
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
    }
  ]
}
EOF
}


# Created this service link out of band.
#aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com


resource "aws_codecommit_repository" "AppCodeCommitRepo" {
  repository_name = "${var.CodeCommitRepo}"
  description     = "App Code Repository"
}






output "REPLACE_ME_CODEBUILD_ROLE_ARN" {
  value = "${aws_iam_role.KCHMatumainiServiceCodeBuildServiceRole.arn}"
}
output "REPLACE_ME_CODEPIPELINE_ROLE_ARN" {
  value = "${aws_iam_role.KCHMatumainiServiceCodePipelineServiceRole.arn}"
}
