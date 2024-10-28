/*************************************************
*                   MONGO DB                     *
*************************************************/

# create IAM role for MongoDB
resource "aws_iam_role" "mongodb_admin_role" {
  name = "${var.project_prefix}${var.mongodb_suffix}-admin-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Attach AdministratorAccess policy to the MongoDB IAM role
resource "aws_iam_role_policy_attachment" "mongodb_admin_policy" {
  depends_on = [aws_iam_role.mongodb_admin_role]

  role       = aws_iam_role.mongodb_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Create IAM instance profile for MongoDB
resource "aws_iam_instance_profile" "mongodb_instance_profile" {
  depends_on = [aws_iam_role.mongodb_admin_role]

  name = "${var.project_prefix}-MongoDBInstanceProfile"
  role = aws_iam_role.mongodb_admin_role.name
}

/*************************************************
*                  S3 BUCKET                     *
*************************************************/

# Create an S3 access policy for MongoDB backups bucket
resource "aws_iam_policy" "s3_access_policy" {
  name        = "${var.project_prefix}-S3AccessPolicy"
  description = "Policy to allow S3 access"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListAllMyBuckets",
          "s3:ListBucket",
          "s3:GetObject"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach the S3 access policy to the MongoDB IAM role
resource "aws_iam_role_policy_attachment" "attach_s3_access_policy" {
  depends_on = [
    aws_iam_role.mongodb_admin_role,
    aws_iam_policy.s3_access_policy
  ]

  role       = aws_iam_role.mongodb_admin_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Create an S3 put object policy for MongoDB backups bucket
resource "aws_iam_policy" "s3_put_object_policy" {
  depends_on = [local.full_bucket_name]

  name        = "${var.project_prefix}-S3PutObjectPolicy"
  description = "Policy to allow S3 PutObject access"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${local.full_bucket_name}",
          "arn:aws:s3:::${local.full_bucket_name}/*"
        ]
      }
    ]
  })
}

# Attach the S3 put object policy to the MongoDB IAM role
resource "aws_iam_role_policy_attachment" "attach_s3_put_object_policy" {
  depends_on = [
    aws_iam_role.mongodb_admin_role,
    aws_iam_policy.s3_put_object_policy
  ]

  role       = aws_iam_role.mongodb_admin_role.name
  policy_arn = aws_iam_policy.s3_put_object_policy.arn
}