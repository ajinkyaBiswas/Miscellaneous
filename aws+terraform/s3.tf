# Create a s3 bucket...with lifecycle policy
resource "aws_kms_key" "buckey_key" {
  deletion_window_in_days = 7
  tags = {
    name = "s3-bucket-key"
  }
}

resource "aws_s3_bucket" "main_bucket" {
  bucket_prefix = "main-bucket"
  acl           = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.buckey_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "log"
    enabled = true

    prefix = "log/"

    tags = {
      rule      = "log"
      autoclean = "true"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA" # or "ONEZONE_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }

  lifecycle_rule {
    id      = "tmp"
    prefix  = "tmp/"
    enabled = true

    expiration {
      date = "2016-01-12"
    }
  }
}

#####################################################################################################
#              Create a replication bucket                                                          #
#              Share bucket content with other accounts   in same region + us-east-1 region         #
#####################################################################################################
variable "destination_account_numbers" {
  type        = list
  description = "list of account numbers i want to share this bucket with"
  default     = ["392220576650", "718770453195", "968246515281"]
}

locals {
  allowed_principals = "${formatlist("arn:aws:iam::%s:root", var.destination_account_numbers)}"
}

resource "aws_s3_bucket" "source_bucket" {
  bucket_prefix = "source-bucket"
  acl           = "private"
  force_destroy = true
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  versioning {
    enabled = true
  }
  tags = {
    name = "source-bucket"
  }

  replication_configuration {
    role = aws_iam_role.s3_replication_role.arn
    rules {
      id     = "replicate-us-east"
      status = "Enabled"
      destination {
        bucket        = aws_s3_bucket.destination_bucket.arn
        storage_class = "STANDARD"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "source_bucket_policy" {
  bucket = aws_s3_bucket.source_bucket.id
  policy = <<POLICY
{
  "Id": "Cross Account Access Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Cross Account Access Policy",
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:Put*"
      ],
      "Effect": "Allow",
      "Resource": [
          "${aws_s3_bucket.source_bucket.arn}",
          "${aws_s3_bucket.source_bucket.arn}/*"
      ],
      "Principal": {
        "AWS": ${jsonencode(local.allowed_principals)}
      }
    }
  ]
}
POLICY
}

provider "aws" {
  alias  = "us-east"
  region = "us-east-1"
}

resource "aws_s3_bucket" "destination_bucket" {
  provider      = aws.us-east
  bucket_prefix = "destination-bucket"
  acl           = "private"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  versioning {
    enabled = true
  }
  tags = {
    name = "destination-bucket"
  }
}

resource "aws_s3_bucket_policy" "destination_bucket_policy" {
  provider = aws.us-east
  bucket   = aws_s3_bucket.destination_bucket.id
  policy   = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "Cross Account Access Policy",
  "Statement": [
    {
      "Sid": "Cross Account Access Policy",
      "Effect": "Allow",
      "Principal": {
          "AWS": ${jsonencode(local.allowed_principals)}
      },
      "Action": [
          "s3:Get*",
          "s3.List*",
          "s3.Put*"
      ],
      "Resource": [
          "${aws_s3_bucket.destination_bucket.arn}",
          "${aws_s3_bucket.destination_bucket.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role" "s3_replication_role" {
  name               = "s3_replication_role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
          "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY  
}

resource "aws_iam_policy" "bucket_replication_policy" {
  name   = "iam_role_policy_s3_replication"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource":[
          "arn:aws:s3:::${aws_s3_bucket.source_bucket.id}"
      ]
    },
    {
      "Action": [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource":[
          "arn:aws:s3:::${aws_s3_bucket.source_bucket.id}/*"
      ]
    },
    {
      "Action": [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
      ],
      "Effect": "Allow",
      "Resource": [
          "arn:aws:s3:::${aws_s3_bucket.destination_bucket.id}/*"
      ]
    }
  ]
}
POLICY  
}

resource "aws_iam_role_policy_attachment" "replication_role_policy_attachment" {
  role       = aws_iam_role.s3_replication_role.name
  policy_arn = aws_iam_policy.bucket_replication_policy.arn
}