data "aws_route53_zone" "main" {
  name         = "mattresssubnetavengers24ever.com"  # <-- your actual domain here
  private_zone = false                    # public hosted zone
}




#########################################################################

resource "aws_route53_record" "shinjuku_origin" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "shinjuku-origin.mattresssubnetavengers24ever.com"
  type    = "A"

  alias {
    name                   = aws_lb.shinjuku_alb.dns_name
    zone_id                = aws_lb.shinjuku_alb.zone_id
    evaluate_target_health = false
  }
}


#########################################################################

resource "aws_route53_record" "liberdade_origin" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "liberdade-origin.mattresssubnetavengers24ever.com"
  type    = "A"

  alias {
    name                   = aws_lb.liberdade_alb.dns_name
    zone_id                = aws_lb.liberdade_alb.zone_id
    evaluate_target_health = false
  }
}