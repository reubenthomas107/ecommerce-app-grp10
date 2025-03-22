# Create an IAM role for EC2 instances running
resource "aws_iam_role" "ec2_role" {
  name = "ecapp-ec2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Effect    = "Allow"
      Sid       = ""
    }]
  })
}

resource "aws_iam_policy" "ec2_s3_policy" {
  name        = "ecapp-ec2-s3-policy"
  description = "Policy for EC2 instances to access S3 buckets"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "${data.aws_s3_bucket.ecapp_static.arn}"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${data.aws_s3_bucket.ecapp_static.arn}/assets/*",
          "${data.aws_s3_bucket.ecapp_static.arn}/admin_images/*",
          "${data.aws_s3_bucket.ecapp_static.arn}/product_images/*",
          "${data.aws_s3_bucket.ecapp_static.arn}/user_images/*"
        ]
      }
    ]
  })
}


# Attach the SSM policy to the role
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_role.name
}

# Attach the S3 policy to the role
resource "aws_iam_role_policy_attachment" "s3_policy" {
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
  role       = aws_iam_role.ec2_role.name
}