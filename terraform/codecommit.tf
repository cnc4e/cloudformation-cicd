resource "aws_codecommit_repository" "cloudformation-template" {
  repository_name = var.codecommit_repository_name
  description     = "cloudformation-template repository"
}