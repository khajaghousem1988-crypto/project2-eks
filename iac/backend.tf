terraform {
  backend "s3" {
    bucket         = "banking-infra-dev"
    key            = "project2-eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-dev"
    encrypt        = true
  }
}
