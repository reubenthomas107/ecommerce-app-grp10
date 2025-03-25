data "aws_route53_zone" "ecapp_hosted_zone" {
  name         = "velixor.me"
  private_zone = false
}

resource "aws_route53_record" "app_record" {
  zone_id = data.aws_route53_zone.ecapp_hosted_zone.zone_id
  name    = "ecapp-group10.velixor.me"
  type    = "A"

  alias {
    name                   = aws_lb.ecapp_alb.dns_name
    zone_id                = aws_lb.ecapp_alb.zone_id
    evaluate_target_health = true
  }
}

output "ecapp_dns_name" {
  value = aws_route53_record.app_record.fqdn
}

output "application_ecapp_url" {
  value = "https://${aws_route53_record.app_record.fqdn}"
}