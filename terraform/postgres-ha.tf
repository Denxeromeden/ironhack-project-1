locals {
  ha_proxy_az = sort(tolist(local.az_set))[1]

  ha_proxy_subnet_key = "${local.ha_proxy_az}-${var.subnet_list[1]}"

  etcd_database_members = slice(
    sort([
      for key, inst in aws_instance.instances :
      key
      if startswith(inst.tags.Name, var.subnet_list[2])
    ]),
    0,
    2
  )
}
resource "aws_security_group" "ha_proxy" {
  name        = "security-group-ha-proxy-${var.unique_id}"
  description = "HAProxy and third etcd member"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name      = "security-group-ha-proxy-${var.unique_id}"
    ManagedBy = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ha_proxy_postgres" {
  security_group_id            = aws_security_group.ha_proxy.id
  description                  = "PostgreSQL write endpoint from workers"
  from_port                    = var.postgres_port
  to_port                      = var.postgres_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.backend.id
}

resource "aws_vpc_security_group_ingress_rule" "ha_proxy_etcd_client" {
  security_group_id            = aws_security_group.ha_proxy.id
  description                  = "etcd client traffic from database nodes"
  from_port                    = 2379
  to_port                      = 2379
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_vpc_security_group_ingress_rule" "ha_proxy_etcd_peer" {
  security_group_id            = aws_security_group.ha_proxy.id
  description                  = "etcd peer traffic from database nodes"
  from_port                    = 2380
  to_port                      = 2380
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_vpc_security_group_ingress_rule" "ha_proxy_etcd_self" {
  security_group_id            = aws_security_group.ha_proxy.id
  description                  = "etcd peer traffic within proxy security group"
  from_port                    = 2380
  to_port                      = 2380
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ha_proxy.id
}

resource "aws_vpc_security_group_egress_rule" "ha_proxy_postgres" {
  security_group_id            = aws_security_group.ha_proxy.id
  description                  = "Connect to PostgreSQL nodes"
  from_port                    = var.postgres_port
  to_port                      = var.postgres_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_vpc_security_group_egress_rule" "ha_proxy_patroni" {
  security_group_id            = aws_security_group.ha_proxy.id
  description                  = "Patroni REST health checks"
  from_port                    = 8008
  to_port                      = 8008
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_vpc_security_group_egress_rule" "ha_proxy_etcd_client" {
  security_group_id            = aws_security_group.ha_proxy.id
  description                  = "etcd client traffic to database members"
  from_port                    = 2379
  to_port                      = 2379
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_vpc_security_group_egress_rule" "ha_proxy_etcd_peer" {
  security_group_id            = aws_security_group.ha_proxy.id
  description                  = "etcd peer traffic to database members"
  from_port                    = 2380
  to_port                      = 2380
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_vpc_security_group_egress_rule" "ha_proxy_https" {
  security_group_id = aws_security_group.ha_proxy.id
  description       = "HTTPS for package and image downloads"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_instance" "ha_proxy" {
  ami                         = data.aws_ssm_parameter.ec2_image.value
  instance_type               = var.ha_proxy_instance_type
  subnet_id                   = aws_subnet.subnets[local.ha_proxy_subnet_key].id
  vpc_security_group_ids      = [aws_security_group.ha_proxy.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  key_name                    = var.ssh_key_name

  root_block_device {
    volume_size = var.ha_proxy_instance_ebs
    volume_type = "gp3"
    encrypted   = true
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name      = "ha-proxy-etcd-${local.ha_proxy_az}-${var.unique_id}"
    ManagedBy = "Terraform"
  }

  depends_on = [
    aws_route_table_association.private_rt_assoc
  ]
}


output "postgres_write_endpoint" {
  description = "Internal PostgreSQL write endpoint"
  value       = "${aws_instance.ha_proxy.private_ip}:5432"
}
