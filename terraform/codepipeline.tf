# アーティファクトストアとなるS3バケット
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "cloudformation-cicd-bucket"
  acl    = "private"
  force_destroy = true
}

# S3へアクセスするためのマネージドキー
data "aws_kms_alias" "s3kmskey" {
  name = "alias/aws/s3"
}

resource "aws_codepipeline" "codepipeline" {
  name     = var.codepipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"

    encryption_key {
      id   = data.aws_kms_alias.s3kmskey.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = var.codecommit_repository_name
        BranchName = var.codecommit_branch_name
        
      }
    }
  }
  
  stage {
    name = "Cfn-lint"

    action {
      name             = "Cfn-lint"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts = ["source_output"]
      output_artifacts = ["lint_output"]

      configuration = {
        ProjectName = "cfn-lint"
      }
    }
  }
  
  stage {
    name = "CloudFormation-guard"

    action {
      name             = "CloudFormation-guard"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts = ["source_output"]
      output_artifacts = ["policy_output"]

      configuration = {
        ProjectName = "cloudformation-guard"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CloudFormation"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ActionMode     = "CREATE_UPDATE"
        RoleArn        = aws_iam_role.cloudformation_role.arn
        Capabilities   = "CAPABILITY_AUTO_EXPAND,CAPABILITY_IAM"
        OutputFileName = "CreateStackOutput.json"
        StackName      = var.stack_name
        TemplatePath   = "source_output::${var.template_path}"
      }
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name = "cloudformation-cicd-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codecommit:GetBranch",
        "codecommit:GetCommit",
        "codecommit:UploadArchive",
        "codecommit:GetUploadArchiveStatus",
        "codecommit:CancelUploadArchive"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:*",
        "iam:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "cloudformation_role" {
  name = "cloudformation-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudformation.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudformation_policy" {
  name = "cloudformation_policy"
  role = aws_iam_role.cloudformation_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "ec2:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

