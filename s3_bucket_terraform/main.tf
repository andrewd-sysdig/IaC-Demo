variable "bucket_name" {
  type = string
  default = "ad-s3-bucket-test123"
}

resource "aws_iam_role" "this" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Took me wayyyyyyy too long to figure this out, wasn't sure how to get * in without type, but AWS means everyone - https://github.com/hashicorp/terraform/issues/14274
# Also then i was missing the /* at teh end of bucket name, sigh...
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [ "s3:GetObject" ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}/*",
    ]
  }
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.bucket_name

  force_destroy       = true # Don't do this at home kids!

  # Bucket policies
  attach_policy                         = true
  policy                                = data.aws_iam_policy_document.bucket_policy.json

  # S3 bucket-level Public Access Block configuration (by default now AWS has made this default as true for S3 bucket-level block public access)
   block_public_acls       = false
   block_public_policy     = false
   ignore_public_acls      = false
   restrict_public_buckets = false

  # S3 Bucket Ownership Controls
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  #expected_bucket_owner = data.aws_caller_identity.current.account_id

  acl = "public-read" # "acl" conflicts with "grant" and "owner"
}


