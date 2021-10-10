# Create an Util Box
resource "aws_security_group" "util_sg" {
  name        = "util-sg"
  description = "allow all Access and allow policies"
  vpc_id      = aws_vpc.primary_vpc.id

  ingress {
    description = "allow http - change to my ip during test - https://whatismyipaddress.com/"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.myIP}/32"] # - change to my ip during test - https://whatismyipaddress.com/
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "linux-util" {
  ami                         = "ami-05c029a4b57edda9e"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  iam_instance_profile        = aws_iam_instance_profile.common-instance-profile.id
  security_groups             = [aws_security_group.util_sg.id]
  user_data                   = file("util_user_data.sh")
  associate_public_ip_address = true
  tags = {
    Name             = "Linux2-Util"
    Installed_Tool_1 = "Docker"
  }
}

