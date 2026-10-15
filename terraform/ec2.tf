resource "aws_security_group" "frontend" {
  name        = "security-group${var.subnet_list[0]}-${var.unique_id}"
  description = "Allow http access from alb"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "frontend_http_rule" {
  security_group_id            = aws_security_group.frontend.id
  description                  = "HTTP from alb 80"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}
resource "aws_vpc_security_group_ingress_rule" "frontend_http_secondary_rule" {
  security_group_id            = aws_security_group.frontend.id
  description                  = "HTTP from alb 8080"
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "frontend_all_traffic_rule" {
  security_group_id = aws_security_group.frontend.id
  description       = "Traffic to anywhere"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "db" {
  name        = "security-group${var.subnet_list[2]}-${var.unique_id}"
  description = "Allow Postgres access from frontend and backend"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "frontend_postgres_rule" {
  security_group_id            = aws_security_group.db.id
  description                  = "Allow Postgres access from frontend"
  from_port                    = var.postgres_port
  to_port                      = var.postgres_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.frontend.id
}

resource "aws_vpc_security_group_ingress_rule" "db_postgres_replication" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL streaming replication between database nodes"
  from_port                    = var.postgres_port
  to_port                      = var.postgres_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}
resource "aws_vpc_security_group_ingress_rule" "db_patroni_peer" {
  security_group_id            = aws_security_group.db.id
  description                  = "Patroni REST API between database nodes"
  from_port                    = 8008
  to_port                      = 8008
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}
resource "aws_vpc_security_group_ingress_rule" "db_from_ha_proxy_postgres" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL connections from HAProxy"
  from_port                    = var.postgres_port
  to_port                      = var.postgres_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ha_proxy.id
}
resource "aws_vpc_security_group_ingress_rule" "db_from_ha_proxy_patroni" {
  security_group_id            = aws_security_group.db.id
  description                  = "Patroni health checks from HAProxy"
  from_port                    = 8008
  to_port                      = 8008
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ha_proxy.id
}
resource "aws_vpc_security_group_ingress_rule" "db_from_ha_proxy_etcd_client" {
  security_group_id            = aws_security_group.db.id
  description                  = "etcd client traffic from HAProxy and etcd host"
  from_port                    = 2379
  to_port                      = 2379
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ha_proxy.id
}

resource "aws_vpc_security_group_ingress_rule" "db_from_ha_proxy_etcd_peer" {
  security_group_id            = aws_security_group.db.id
  description                  = "etcd peer traffic from HAProxy and etcd host"
  from_port                    = 2380
  to_port                      = 2380
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ha_proxy.id
}
resource "aws_vpc_security_group_ingress_rule" "db_from_db_client" {
  security_group_id            = aws_security_group.db.id
  description                  = "etcd client traffic from db instances"
  from_port                    = 2379
  to_port                      = 2379
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_vpc_security_group_ingress_rule" "db_from_db_peer" {
  security_group_id            = aws_security_group.db.id
  description                  = "etcd peer traffic from db instances"
  from_port                    = 2380
  to_port                      = 2380
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}
resource "aws_vpc_security_group_egress_rule" "db_cluster_postgres" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL replication traffic"
  from_port                    = var.postgres_port
  to_port                      = var.postgres_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_vpc_security_group_egress_rule" "db_cluster_patroni" {
  security_group_id            = aws_security_group.db.id
  description                  = "Patroni REST API traffic"
  from_port                    = 8008
  to_port                      = 8008
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}
resource "aws_vpc_security_group_egress_rule" "db_cluster_etcd_client" {
  security_group_id            = aws_security_group.db.id
  description                  = "etcd client communication between database nodes"
  from_port                    = 2379
  to_port                      = 2379
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_vpc_security_group_egress_rule" "db_cluster_etcd_peer" {
  security_group_id            = aws_security_group.db.id
  description                  = "etcd peer communication between database nodes"
  from_port                    = 2380
  to_port                      = 2380
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}
resource "aws_vpc_security_group_egress_rule" "db_to_ha_proxy_etcd_client" {
  security_group_id            = aws_security_group.db.id
  description                  = "etcd client traffic to third member"
  from_port                    = 2379
  to_port                      = 2379
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ha_proxy.id
}

resource "aws_vpc_security_group_egress_rule" "db_to_ha_proxy_etcd_peer" {
  security_group_id            = aws_security_group.db.id
  description                  = "etcd peer traffic to third member"
  from_port                    = 2380
  to_port                      = 2380
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ha_proxy.id
}
resource "aws_vpc_security_group_egress_rule" "db_ssm_rule" {
  security_group_id = aws_security_group.db.id
  description       = "HTTPS traffic to all"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "backend" {
  name        = "security-group${var.subnet_list[1]}-${var.unique_id}"
  description = "Allow Redis access inbound and Postgres outbound"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "backend_redis_rule" {
  security_group_id            = aws_security_group.backend.id
  description                  = "Access to Redis from alb"
  from_port                    = var.redis_port
  to_port                      = var.redis_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.frontend.id
}

resource "aws_vpc_security_group_egress_rule" "backend_postgres_rule" {
  security_group_id            = aws_security_group.backend.id
  description                  = "Traffic to Postgres through HAProxy"
  from_port                    = var.postgres_port
  to_port                      = var.postgres_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ha_proxy.id
}

resource "aws_vpc_security_group_egress_rule" "backend_ssm_rule" {
  security_group_id = aws_security_group.backend.id
  description       = "HTTPS traffic to all"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_iam_role" "ssm_role" {
  name = "ec2-ssm-execution-role-${var.unique_id}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ec2-ssm-instance-profile-${var.unique_id}"
  role = aws_iam_role.ssm_role.name
}

resource "tls_private_key" "ed25519_key" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "private_key" {
  filename        = "${var.ssh_key_path}${var.ssh_key_name}.pem"
  content         = tls_private_key.ed25519_key.private_key_openssh
  file_permission = "0400"
}

resource "aws_key_pair" "ed25519" {
  key_name   = var.ssh_key_name
  public_key = tls_private_key.ed25519_key.public_key_openssh
}

resource "aws_instance" "instances" {
  for_each = {
    for key, subnet in aws_subnet.subnets :
    key => subnet
    if !startswith(subnet.tags["Name"], var.subnet_list[3])
  }
  ami                         = data.aws_ssm_parameter.ec2_image.value
  instance_type               = startswith(each.value.tags.Name, var.subnet_list[0]) ? var.frontend_instance_type : startswith(each.value.tags.Name, var.subnet_list[1]) ? var.backend_instance_type : var.db_instance_type
  vpc_security_group_ids      = [startswith(each.value.tags.Name, var.subnet_list[0]) ? aws_security_group.frontend.id : startswith(each.value.tags.Name, var.subnet_list[1]) ? aws_security_group.backend.id : aws_security_group.db.id]
  subnet_id                   = each.value.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  key_name                    = var.ssh_key_name
  depends_on                  = [aws_route_table_association.private_rt_assoc]
  root_block_device {
    volume_size = startswith(each.value.tags.Name, var.subnet_list[0]) ? var.frontend_instance_ebs : startswith(each.value.tags.Name, var.subnet_list[1]) ? var.backend_instance_ebs : var.db_instance_ebs
    volume_type = "gp3"
    encrypted   = true
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "${startswith(each.value.tags.Name, var.subnet_list[0]) ? var.subnet_list[0] : startswith(each.value.tags.Name, var.subnet_list[1]) ? var.subnet_list[1] : var.subnet_list[2]}-ec2-${each.value.availability_zone}-${var.unique_id}"
  }
}

resource "aws_lb_target_group_attachment" "tg_attach_vote" {
  for_each         = { for key, val in aws_instance.instances : key => val if startswith(val.tags.Name, var.subnet_list[0]) }
  target_group_arn = aws_lb_target_group.alb_target_vote.arn
  target_id        = each.value.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "tg_attach_result" {
  for_each         = { for key, val in aws_instance.instances : key => val if startswith(val.tags.Name, var.subnet_list[0]) }
  target_group_arn = aws_lb_target_group.alb_target_result.arn
  target_id        = each.value.id
  port             = 8080
}

resource "local_file" "ansible_inventory" {
  filename = "../${path.module}/ansible/inventory.ini"
  content = templatefile("${path.module}/templates/inventory.tftpl", {
    instances = {
      for k, v in aws_instance.instances : k => {
        private_ip        = v.private_ip
        availability_zone = v.availability_zone
        tags              = v.tags
        id                = v.id
      }
    }
    sub = var.subnet_list
    ha_proxy = {
      private_ip        = aws_instance.ha_proxy.private_ip
      availability_zone = aws_instance.ha_proxy.availability_zone
      id                = aws_instance.ha_proxy.id
    }
    etcd_database_members = local.etcd_database_members
  })
}