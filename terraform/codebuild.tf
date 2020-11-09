# アーティファクトストアとなるS3バケット
resource "aws_s3_bucket" "codebuild_bucket" {
  bucket = "cloudformation-cicd-codebuild-bucket"
  acl    = "private"
}

resource "aws_codebuild_project" "codebuild" {
  name          = "taskcat-test"
  description   = "taskcat test project"
  build_timeout = "10"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.codebuild_bucket.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "cloudformation-cicd"
      stream_name = "taskcat-log"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.codebuild_bucket.id}/build-log"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  source_version = "master"

  //vpc_config {
  //  vpc_id = aws_vpc.example.id

  //  subnets = [
  //    aws_subnet.example1.id,
  //    aws_subnet.example2.id,
  //  ]

  //  security_group_ids = [
  //    aws_security_group.example1.id,
  //    aws_security_group.example2.id,
  //  ]
  //}

}

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:*",
        "codecommit:*",
        "codepipeline:*",
        "cloudformation:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "iam:*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
POLICY
}