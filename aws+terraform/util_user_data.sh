#!/bin/bash
 
echo "**********************"
echo "Installing SSM Agent"
echo "**********************"
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl start amazon-ssm-agent
 
echo "**********************"
echo "Installing AWS CLI"
echo "**********************"
yum install python3-pip.noarch -y
echo "export PATH=/root/.local/bin:$PATH" >> /root/.bash_profile
source /root/.bash_profile
pip3 install awscli --upgrade --user
aws configure set s3.signature_version s3v4

# install docker
yum update -y
amazon-linux-extras install -y docker
service docker start
usermod -a -G docker ssm-user
