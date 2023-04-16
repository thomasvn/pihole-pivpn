provider "aws" {
  profile = "home"  # REPLACE WITH YOUR OWN ~/.aws/config PROFILE, OR DELETE THIS LINE 
  region = "us-west-1"
}

output "instance_public_ip" {
  value       = aws_spot_instance_request.spot_request.public_ip
  description = "AWS EC2 Instance Public IP"
}

output "ssh" {
  value = "ssh -i '~/.ssh/thomas-aws.pem' ubuntu@${aws_spot_instance_request.spot_request.public_ip}"
  description = "Command to ssh into the box"
}

variable "instance_type" {
  description = "The instance type for the Spot Instance Request, either 't4g.micro' or 't4g.small'"
  default     = "t4g.micro"
}

resource "aws_security_group" "pihole_ports" {
  name        = "pihole_ports"
  description = "Allow inbound traffic on ports 22 and 1194"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ports"
  }
}

resource "aws_spot_instance_request" "spot_request" {
  wait_for_fulfillment = true
  instance_type        = var.instance_type
  ami                  = "ami-0c75abbbe8bd81092" # Ubuntu Server 20.04 LTS (HVM)

  vpc_security_group_ids = [aws_security_group.pihole_ports.id]

  key_name = "thomas-aws"  # REPLACE WITH YOUR OWN KEY PAIR

  spot_type = "one-time"

  tags = {
    Name = var.instance_type
  }
}

