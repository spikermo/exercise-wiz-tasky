/*************************************************
*                    STORAGE                     *
*************************************************/

# Create an S3 bucket for MongoDB backups
resource "aws_s3_bucket" "mongodb_backups" {
  depends_on = [
    aws_iam_role_policy_attachment.attach_s3_access_policy,
    aws_iam_role_policy_attachment.attach_s3_put_object_policy
  ]

  bucket = local.full_bucket_name

  tags = {
    Name = "MongoDB Backups"
  }

# Allow the bucket to be destroyed
  lifecycle {
    prevent_destroy = false
  }
}

# Configure the S3 bucket as a static website
resource "aws_s3_bucket_website_configuration" "website_bucket" {
  depends_on = [aws_s3_bucket_public_access_block.mongodb_backups]
  
  bucket = aws_s3_bucket.mongodb_backups.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Enable public access block for the S3 bucket
resource "aws_s3_bucket_public_access_block" "mongodb_backups" {
  depends_on = [aws_s3_bucket.mongodb_backups]

  bucket = aws_s3_bucket.mongodb_backups.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Create a bucket policy to allow access to the S3 bucket
resource "aws_s3_bucket_policy" "mongodb_backups_policy" {
  depends_on = [aws_s3_bucket.mongodb_backups]

  bucket = aws_s3_bucket.mongodb_backups.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ],
        Resource = [
          "arn:aws:s3:::${local.full_bucket_name}",
          "arn:aws:s3:::${local.full_bucket_name}/*"
        ]
      }
    ]
  })
}