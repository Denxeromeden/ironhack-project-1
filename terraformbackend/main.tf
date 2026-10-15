variable "aws_region" {
  type        = string
  description = "The region where the resources will be located"
  default     = "us-east-1"
}
variable "unique_id" {
  type        = string
  description = "Unique id to attach to the created resources"
  default     = "user-uniqueid-3669"
}

resource "aws_s3_bucket" "state-bucket" {
  bucket = "terraform-state-bucket-${var.unique_id}"
  region = var.aws_region

  tags = {
    Name = "terraform-state-bucket-${var.unique_id}"
  }
}

output "bucket-name" {
  value = aws_s3_bucket.state-bucket.id
}
