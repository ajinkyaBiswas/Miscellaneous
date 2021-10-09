###################################################
# Create Common Policy, Role and instance-profile #
###################################################
data "aws_iam_policy_document" "common_policy" {
  statement {
    effect = "Allow"
    resources = [
      "*"
    ]
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
  }

  statement {
    effect = "Allow"
    resources = [
      "*"
    ]
    actions = [
      "ec2:DescribeInstances",
      "ec2:CreateVolume",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:PutMetricAlarm",
    ]
  }

  statement {
    effect = "Allow"
    resources = [
      "*"
    ]
    actions = [
      "s3:GetEncryptionConfiguration",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectAcl",
    ]
  }

  statement {
    effect = "Allow"
    resources = [
      "*"
    ]
    actions = [
      "kms:Decrypt",
    ]
  }

  statement {
    effect = "Allow"
    resources = [
      "*"
    ]
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
  }

  statement {
    effect = "Allow"
    resources = [
      "*"
    ]
    actions = [
      "cloudwatch:DescribeAlarms",
      "cloudwatch:PutMetricAlarm",
    ]
  }
}

resource "aws_iam_role" "common_role" {
  name = "common-iam-role"

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

resource "aws_iam_role_policy" "common_role_policy" {
  name   = "common-role-policy"
  role   = aws_iam_role.common_role.name
  policy = data.aws_iam_policy_document.common_policy.json
}

resource "aws_iam_role_policy_attachment" "AmazonEC2RoleforSSM-attach" {
  role       = aws_iam_role.common_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore-attach" {
  role       = aws_iam_role.common_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "AmazonS3ReadOnlyAccess-attach" {
  role       = aws_iam_role.common_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "AutoScalingReadOnlyAccess-attach" {
  role       = aws_iam_role.common_role.name
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "AmazonCloudWatchAgent-attach" {
  role       = aws_iam_role.common_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "SecretsManager-attach" {
  role       = aws_iam_role.common_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_instance_profile" "common-instance-profile" {
  name = "common-instance-profile"
  role = aws_iam_role.common_role.name
}