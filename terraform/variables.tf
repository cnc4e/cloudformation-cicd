provider "aws" {
  region = "ap-northeast-1"
}

variable "region" {
  default = "ap-northeast-1"
}

variable "project" {
  default = "cloudformation-cicd"
}

variable "codepipeline_name" {
  default = "cloudformation-cicd"
}

variable "codecommit_repository_name" {
  default = "CloudFormationTest"
}

variable "codecommit_branch_name" {
  default = "master"
}

variable "template_path" {
  default = "sam-templated.yaml"
}

variable "stack_name" {
  default = "codepipeline-cicd"
}