data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "zone" {
  name = var.zone_name
}

data "aws_ssm_parameter" "ec2_image" {
  name = var.ec2_image
}