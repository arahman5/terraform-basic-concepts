terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "local" {}
}

locals {
  common_prefix = "arn:aws:iam::aws:policy"
}

provider "aws" {  
  region = "eu-west-2"
}

provider "aws" {
  alias  = "data-science"
  region = "eu-west-1"
}

resource "aws_ecr_repository" "my_ecr_repo" {
  name                 = var.ecr_repo_name 
  image_tag_mutability = var.ecr_repo_name != "example" ? "MUTABLE" : "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = false 
  }
}

data "aws_caller_identity" "current" {}

import {
  to = module.iam.aws_iam_user.redshift-user
  id = "redshift-user"
}

output "basic" {
    value = aws_ecr_repository.my_ecr_repo.arn
}

resource "aws_iam_role" "example_role" {
  name = "examplerole"

  assume_role_policy = file("./ec2-role-policy.json")
}

resource "aws_iam_role_policy_attachment" "example_attachment" {
  role       = aws_iam_role.example_role.name
  policy_arn = "${common_prefix}/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "example_policy_attachments" {
  for_each = toset(var.policies)
  policy_arn = "${common_prefix}/${each.key}"
  role       = aws_iam_role.example_role.name
}