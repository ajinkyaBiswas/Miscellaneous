##############################################
# Create gateway vpc endponts - s3, dynamodb #
##############################################
data "aws_vpc_endpoint_service" "s3_gateway" {
  service      = "s3"
  service_type = "Gateway"
}

resource "aws_vpc_endpoint" "s3_gateway_vpc_endpoint" {
  service_name      = data.aws_vpc_endpoint_service.s3_gateway.service_name
  vpc_endpoint_type = "Gateway"

  vpc_id = aws_vpc.primary_vpc.id

  security_group_ids = []
  tags = {
    "Name" = "s3-gateway"
  }
}

data "aws_vpc_endpoint_service" "dynamodb" {
  service      = "dynamodb"
  service_type = "Gateway"
}

resource "aws_vpc_endpoint" "dynamodb_vpc_endpoint" {
  service_name      = data.aws_vpc_endpoint_service.dynamodb.service_name
  vpc_endpoint_type = "Gateway"

  vpc_id = aws_vpc.primary_vpc.id

  security_group_ids = []
  tags = {
    "Name" = "dynamodb"
  }
}
################################################
# Create Interface vpc endponts - S3, SSM, ec2 #
################################################
# S3
data "aws_vpc_endpoint_service" "s3_interface" {
  service      = "s3"
  service_type = "Interface"
}

resource "aws_security_group" "s3_sg" {
  name        = "s3-sg"
  description = "SG for s3"
  vpc_id      = aws_vpc.primary_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.primary_vpc.cidr_block]
    description = "allow S3 access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.primary_vpc.cidr_block]
    description = "allow S3 access"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.primary_vpc.cidr_block]
    description = "allow S3 access"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.primary_vpc.cidr_block]
    description = "allow S3 access"
  }
}

resource "aws_vpc_endpoint" "s3_interface_vpc_endpoint" {
  service_name      = data.aws_vpc_endpoint_service.s3_gateway.service_name
  vpc_endpoint_type = "Interface"

  vpc_id     = aws_vpc.primary_vpc.id
  subnet_ids = [aws_subnet.private_subnet_A.id, aws_subnet.private_subnet_B.id]

  security_group_ids = [aws_security_group.s3_sg.id]
  #   private_dns_enabled = true # Private DNS can't be enabled because the service com.amazonaws.ap-southeast-2.s3 does not provide a private DNS name.
  tags = {
    "Name" = "s3-interface"
  }
}

# SSM
data "aws_vpc_endpoint_service" "ssm" {
  service = "ssm"
}

data "aws_vpc_endpoint_service" "ssmmessage" {
  service = "ssmmessages"
}

resource "aws_security_group" "ssm_sg" {
  name        = "ssm-sg"
  description = "SG for SSM vpce"
  vpc_id      = aws_vpc.primary_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.primary_vpc.cidr_block]
    description = "allow SSM access"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.primary_vpc.cidr_block]
    description = "allow SSM access"
  }
}

resource "aws_vpc_endpoint" "ssm_vpc_endpoint" {
  service_name      = data.aws_vpc_endpoint_service.ssm.service_name
  vpc_endpoint_type = "Interface"

  vpc_id     = aws_vpc.primary_vpc.id
  subnet_ids = [aws_subnet.private_subnet_A.id, aws_subnet.private_subnet_B.id]

  security_group_ids  = [aws_security_group.ssm_sg.id]
  private_dns_enabled = true
  tags = {
    "Name" = "ssm"
  }
}

resource "aws_vpc_endpoint" "ssm_message_vpc_endpoint" {
  service_name      = data.aws_vpc_endpoint_service.ssmmessage.service_name
  vpc_endpoint_type = "Interface"

  vpc_id     = aws_vpc.primary_vpc.id
  subnet_ids = [aws_subnet.private_subnet_A.id, aws_subnet.private_subnet_B.id]

  security_group_ids  = [aws_security_group.ssm_sg.id]
  private_dns_enabled = true
  tags = {
    "Name" = "ssmmessage"
  }
}

# EC2
data "aws_vpc_endpoint_service" "ec2" {
  service = "ec2"
}

data "aws_vpc_endpoint_service" "ec2message" {
  service = "ec2messages"
}

resource "aws_vpc_endpoint" "ec2message_vpc_endpoint" {
  service_name      = data.aws_vpc_endpoint_service.ec2message.service_name
  vpc_endpoint_type = "Interface"

  vpc_id     = aws_vpc.primary_vpc.id
  subnet_ids = [aws_subnet.private_subnet_A.id, aws_subnet.private_subnet_B.id]

  security_group_ids  = [aws_security_group.ssm_sg.id] # reuse ssm_sg
  private_dns_enabled = true
  tags = {
    "Name" = "ec2message"
  }
}

resource "aws_vpc_endpoint" "ec2_vpc_endpoint" {
  service_name      = data.aws_vpc_endpoint_service.ec2.service_name
  vpc_endpoint_type = "Interface"

  vpc_id     = aws_vpc.primary_vpc.id
  subnet_ids = [aws_subnet.private_subnet_A.id, aws_subnet.private_subnet_B.id]

  security_group_ids  = [aws_security_group.ssm_sg.id]
  private_dns_enabled = true
  tags = {
    "Name" = "ec2"
  }
}
