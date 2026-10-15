variable "aws_region" {
  type        = string
  description = "The region where the resources will be located"
  default     = "us-east-1"
}
variable "unique_id" {
  type        = string
  description = "Unique id to attach to the created resources"
  default     = "user-unique-id-3669"
}
variable "ssh_key_name" {
  type        = string
  description = "ssh key name for the ec2 instances"
}
variable "ssh_key_path" {
  type        = string
  description = "ssh key name path to save the key"
}
variable "env_tag" {
  type        = string
  description = "Tag for environment"
  default     = "dev"
}
variable "az" {
  type        = set(string)
  description = "Availability zones where to deploy the resources, must be compatible with region"
  default     = null
  validation {
    condition     = var.az == null ? true : (length(var.az) >= 2 && alltrue([for az in var.az : contains(data.aws_availability_zones.available.names, az)]))
    error_message = "One or more AZ are not available in region ${var.aws_region}. Choose at least 2. The following AZs are available: ${join(", ", data.aws_availability_zones.available.names)}"
  }
}
variable "vpc_cidr" {
  type        = string
  description = "IPv4 CIDR for the VPC"
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "The vpc_cidr value must be a valid IPv4 CIDR block, such as 10.0.0.0/16."
  }
}
variable "tenancy" {
  type        = string
  description = "Instance tenancy for the vpc"
  default     = "default"
  validation {
    condition     = contains(["default", "dedicated"], var.tenancy)
    error_message = "Values must be eithr 'default' or 'dedicated'"
  }
}
variable "subnet_list" {
  type        = list(string)
  description = "Subnet prefixes. Use first element for subnet containing the frontend, second for backend and third for database"
  default     = ["frontend", "backend", "db", "alb"]
  validation {
    condition     = length(distinct(var.subnet_list)) == 4
    error_message = "The subnet_list variable must have 4 unique entries."
  }
}
variable "ec2_image" {
  type        = string
  description = "Image to be used for EC2 instances. It needs to be compatible with Amazon Linux and arm64 architecture. Uses automatic resolution"
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}
variable "app_url" {
  type        = string
  description = "Url the application will be reachable from"
  default     = "app.mydomain.com"
}
variable "zone_name" {
  type        = string
  description = "Name of the hosted zone in AWS. The hosted zone needs to be already available. It won't be created"
  default     = "mydomain.com"
}
variable "redis_port" {
  type        = number
  description = "Redis port"
  default     = 6379
}
variable "postgres_port" {
  type        = number
  description = "Postgres port"
  default     = 5432
}
variable "frontend_instance_type" {
  type        = string
  description = "Instance type for the frontend. Must be compatible with ec2_image"
  default     = "t4g.small"
}
variable "backend_instance_type" {
  type        = string
  description = "Instance type for the backend. Must be compatible with ec2_image"
  default     = "t4g.small"
}
variable "db_instance_type" {
  type        = string
  description = "Instance type for the database. Must be compatible with ec2_image"
  default     = "t4g.small"
}
variable "ha_proxy_instance_type" {
  type        = string
  description = "Instance type for the HAProxy and thrid etcd member. Must be compatible with ec2_image"
  default     = "t4g.small"
}
variable "frontend_instance_ebs" {
  type        = number
  description = "Instance root volume size in gb"
  default     = 15
}
variable "backend_instance_ebs" {
  type        = number
  description = "Instance root volume size in gb"
  default     = 15
}
variable "db_instance_ebs" {
  type        = number
  description = "Instance root volume size in gb"
  default     = 15
}
variable "ha_proxy_instance_ebs" {
  type        = number
  description = "Instance root volume size in gb"
  default     = 12
}