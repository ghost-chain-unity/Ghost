terraform {
  backend "s3" {
    bucket         = "ghost-protocol-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "ghost-protocol-terraform-locks"
    
  }
}
