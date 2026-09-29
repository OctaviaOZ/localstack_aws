terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "eu-central-1"
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3       = "http://s3.localhost.localstack.cloud:4566"
    dynamodb = "http://localhost:4566"
    sqs      = "http://localhost:4566"
    sns      = "http://localhost:4566"
    lambda   = "http://localhost:4566"
    iam      = "http://localhost:4566"
  }
}

# Example resource
resource "aws_s3_bucket" "demo_bucket" {
  bucket = "localstack-demo-bucket"
}

resource "aws_iam_group" "workshop_admins" {
  name = "WorkshopAdmins"
}

resource "aws_iam_policy" "workshop_s3_athena_glue" {
  name = "WorkshopS3AthenaGluePolicy"

  policy = replace(
    file("${path.module}/tmp/WorkshopS3AthenaGluePolicy.json"),
    "<YOUR-BUCKET-NAME>",
    aws_s3_bucket.demo_bucket.bucket
  )
}

resource "aws_iam_group_policy_attachment" "workshop_admins_s3_athena_glue" {
  group      = aws_iam_group.workshop_admins.name
  policy_arn = aws_iam_policy.workshop_s3_athena_glue.arn
}

resource "aws_iam_user" "workshop_user" {
  name = "Workshop-User"
}

resource "aws_iam_user_login_profile" "workshop_user" {
  user                    = aws_iam_user.workshop_user.name
  password_reset_required = false
}

resource "aws_iam_user_group_membership" "workshop_user" {
  user   = aws_iam_user.workshop_user.name
  groups = [aws_iam_group.workshop_admins.name]
}

output "workshop_user_password" {
  value     = aws_iam_user_login_profile.workshop_user.password
  sensitive = true
}
