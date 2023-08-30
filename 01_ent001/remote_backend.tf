terraform {
  backend "s3" {
    bucket = "aws_s3_bucket_name"
    key    = "aws_s3_bucket_key"
    region = "aws_region"
  }
}
# terraform {
#   cloud {
#     organization = "org_name"

#     workspaces {
#       name = "workspace_name"
#     }
#   }
# }