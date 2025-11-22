resource "aws_cloudfront_origin_access_identity" "main" {
  count = var.enable_cloudfront ? 1 : 0

  comment = "OAI for ${var.project_name}-${var.environment} static assets"
}

resource "aws_cloudfront_distribution" "main" {
  count = var.enable_cloudfront ? 1 : 0

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name}-${var.environment} static assets CDN"
  default_root_object = var.cloudfront_default_root_object
  price_class         = var.cloudfront_price_class
  aliases             = var.cloudfront_aliases

  origin {
    domain_name = aws_s3_bucket.main["static"].bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.main["static"].id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main[0].cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.main["static"].id}"

    forwarded_values {
      query_string = false
      headers      = var.cloudfront_forward_headers

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.cloudfront_min_ttl
    default_ttl            = var.cloudfront_default_ttl
    max_ttl                = var.cloudfront_max_ttl
    compress               = true
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.cloudfront_custom_cache_behaviors
    content {
      path_pattern     = ordered_cache_behavior.value.path_pattern
      allowed_methods  = ordered_cache_behavior.value.allowed_methods
      cached_methods   = ordered_cache_behavior.value.cached_methods
      target_origin_id = "S3-${aws_s3_bucket.main["static"].id}"

      forwarded_values {
        query_string = ordered_cache_behavior.value.forward_query_string
        headers      = lookup(ordered_cache_behavior.value, "forward_headers", [])

        cookies {
          forward = lookup(ordered_cache_behavior.value, "forward_cookies", "none")
        }
      }

      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = lookup(ordered_cache_behavior.value, "min_ttl", 0)
      default_ttl            = lookup(ordered_cache_behavior.value, "default_ttl", 86400)
      max_ttl                = lookup(ordered_cache_behavior.value, "max_ttl", 31536000)
      compress               = lookup(ordered_cache_behavior.value, "compress", true)
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.cloudfront_geo_restriction_type
      locations        = var.cloudfront_geo_restriction_locations
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.cloudfront_acm_certificate_arn
    ssl_support_method             = var.cloudfront_acm_certificate_arn != null ? "sni-only" : null
    minimum_protocol_version       = var.cloudfront_minimum_protocol_version
    cloudfront_default_certificate = var.cloudfront_acm_certificate_arn == null
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = var.cloudfront_custom_error_response_path
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = var.cloudfront_custom_error_response_path
    error_caching_min_ttl = 300
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-cloudfront"
    }
  )
}
