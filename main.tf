provider "aws" {
  region = "ap-south-1"  # Change to your preferred region
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create Public Subnet (for Bastion Host)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"  # Change to an available zone in your region
  map_public_ip_on_launch = true
}

# Create Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1a"  # Change to an available zone in your region
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Create Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create Security Group for Private Instances
resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Security Group for Bastion Host
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict to your IP for better security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch EC2 Instance for Web Application
resource "aws_instance" "web" {
  ami           = "ami-0f58b397bc5c1f2e8"  # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id
  security_groups = [aws_security_group.private_sg.id]  # Use security group ID instead of name

  key_name = "testmadeep"  # Replace with your key pair name in the region
}

# Launch EC2 Instance for PostgreSQL Database
resource "aws_instance" "db" {
  ami           = "ami-0f58b397bc5c1f2e8"  # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id
  security_groups = [aws_security_group.private_sg.id]  # Use security group ID instead of name

  key_name = "testmadeep"  # Replace with your key pair name in the region

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install postgresql10 -y
              systemctl enable postgresql
              systemctl start postgresql
              sudo -i -u postgres psql -c "CREATE USER webapp WITH PASSWORD 'password';"
              sudo -i -u postgres psql -c "CREATE DATABASE webapp_db OWNER webapp;"
              EOF
}

# Launch EC2 Instance for Bastion Host
resource "aws_instance" "bastion" {
  ami           = "ami-0f58b397bc5c1f2e8"  # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  security_groups = [aws_security_group.bastion_sg.id]  # Use security group ID instead of name

  key_name = "testmadeep"  # Replace with your key pair name in the region
}
