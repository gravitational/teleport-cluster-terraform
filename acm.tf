// If you already have your own ACM certificate that you'd like to use, set the "use_acm" variable to "true" and then
// import the existing ACM certificate with:
// terraform import aws_acm_certificate.cert <certificate_arn>
// NOTE: using non-Amazon issued certificates in this manner is a bad idea as they cannot be automatically recreated by
// Terraform if they are deleted. In this instance we recommend setting up ACM on the proxy load balancer yourself.

// Define an ACM cert we can use for the proxy
// Add wildcard as a SAN for use with app_service
resource "aws_acm_certificate" "cert" {
  domain_name               = var.route53_domain
  subject_alternative_names = ["*.${var.route53_domain}"]
  validation_method         = "DNS"
  count                     = var.use_acm ? 1 : 0

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  allow_overwrite = true
  zone_id         = data.aws_route53_zone.proxy.zone_id
  count           = var.use_acm ? 1 : 0

  depends_on = [
    aws_acm_certificate.cert
  ]
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
  count                   = var.use_acm ? 1 : 0
}
