resource "aws_cloudfront_origin_access_identity" "oaid" {
  comment = "Origin Access Identity for S3"
}

#Importing S3 bucket information 
data "aws_s3_bucket" "ecapp_static" {
  bucket = "ecapp-webapp-bucket"
}

resource "aws_s3_bucket_policy" "asset_access_policy" {
  bucket = data.aws_s3_bucket.ecapp_static.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oaid.iam_arn
        }
        Action    = "s3:GetObject"
        Resource  = ["${data.aws_s3_bucket.ecapp_static.arn}/assets/*",
                     "${data.aws_s3_bucket.ecapp_static.arn}/admin_images/*",
                     "${data.aws_s3_bucket.ecapp_static.arn}/product_images/*"]
      }
    ]
  })
  
#   lifecycle {
#     prevent_destroy = true
#   }
  
}

resource "aws_s3_bucket_public_access_block" "ecapp_bucket" {
  bucket = data.aws_s3_bucket.ecapp_static.id
  # Block public access settings
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

#   lifecycle {
#     prevent_destroy = true
#   }
}


resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = data.aws_s3_bucket.ecapp_static.bucket_regional_domain_name
    origin_id   = "ecapp-s3-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oaid.cloudfront_access_identity_path
    }
  }

  comment             = "ECAPP CDN for Serving Static Assets"
  enabled             = true
  is_ipv6_enabled     = true

  default_cache_behavior {
    target_origin_id       = "ecapp-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" #Using Managed-CachingOptimized Policy
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    
  }

  price_class = "PriceClass_100"   #PriceClass_All

  restrictions {
    geo_restriction {
      restriction_type = "whitelist" #none
      locations        = ["US", "CA", "GB"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

output "ecapp_cdn_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "ecapp_cdn_url" {
  description = "URL to access static assets via CDN"
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}