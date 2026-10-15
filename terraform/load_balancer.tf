resource "aws_security_group" "alb" {
  name        = "alb-${var.unique_id}"
  description = "Allow https,http access"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from anywhere"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPs from anywhere"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_all_traffic_rule" {
  security_group_id = aws_security_group.alb.id
  description       = "traffic to anywhere"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_lb" "alb" {
  name               = "alb-${var.unique_id}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for k, v in aws_subnet.subnets : v.id if startswith(v.tags.Name, var.subnet_list[3])]
  depends_on         = [aws_subnet.subnets]
}

resource "aws_lb_target_group" "alb_target_vote" {
  name     = "target-vote-${var.unique_id}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    enabled = true
  }
}

resource "aws_lb_target_group" "alb_target_result" {
  name     = "target-result-${var.unique_id}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    enabled = true
  }
}

resource "aws_lb_listener" "https_redirect" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.cert-validation.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "vote_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_vote.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_lb_listener_rule" "result_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_result.arn
  }

  condition {
    path_pattern {
      values = ["/result", "/result/*"]
    }
  }
}

resource "aws_route53_record" "alb_record" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.app_url
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}