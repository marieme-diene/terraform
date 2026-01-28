terraform {
  backend "s3" {
    bucket         = "mon-projet-state-2026-marieme"  # <--- METS TON BUCKET
    key            = "projet-s3/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "terraform-locks1"
    encrypt        = true
  }
}