# Create VPC in eu-west-1
resource "aws_vpc" "vpc_master" {
  provider             = aws.region-jenkins
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "master-vpc-jenkins"
  }

}

# Create VPC for TF workers in eu-west-3
resource "aws_vpc" "vpc_worker_tf" {
  provider             = aws.region-worker
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "worker-vpc-jenkins-terraform"
  }

}

# Create VPC for Docker workers in eu-west-3
resource "aws_vpc" "vpc_worker_docker" {
  provider             = aws.region-worker
  cidr_block           = "10.2.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "worker-vpc-jenkins-docker"
  }

}

# Initiate Peering connection request from eu-west-1
resource "aws_vpc_peering_connection" "euwest1-euwest3-tf" {
  provider    = aws.region-jenkins
  peer_vpc_id = aws_vpc.vpc_worker_tf.id
  vpc_id      = aws_vpc.vpc_master.id
  #auto_accept = true
  peer_region = var.region-worker

}

# Initiate Peering connection request from eu-west-1
resource "aws_vpc_peering_connection" "euwest1-euwest3-docker" {
  provider    = aws.region-jenkins
  peer_vpc_id = aws_vpc.vpc_worker_docker.id
  vpc_id      = aws_vpc.vpc_master.id
  #auto_accept = true
  peer_region = var.region-worker

}

# Create IGW in eu-west-1
resource "aws_internet_gateway" "igw-jenkins" {
  provider = aws.region-jenkins
  vpc_id   = aws_vpc.vpc_master.id
}

# Create IGW for TF workers in eu-west-3
resource "aws_internet_gateway" "igw-worker-tf" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_worker_tf.id
}

# Create IGW for docker workers in eu-west-3
resource "aws_internet_gateway" "igw-worker-docker" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_worker_docker.id
}

# Accept VPC peering request in eu-west-3 TF from eu-west-1
resource "aws_vpc_peering_connection_accepter" "accept_peering-tf" {
  provider                  = aws.region-worker
  vpc_peering_connection_id = aws_vpc_peering_connection.euwest1-euwest3-tf.id
  auto_accept               = true
}

# Accept VPC peering request in eu-west-3 docker from eu-west-1
resource "aws_vpc_peering_connection_accepter" "accept_peering-docker" {
  provider                  = aws.region-worker
  vpc_peering_connection_id = aws_vpc_peering_connection.euwest1-euwest3-docker.id
  auto_accept               = true
}

# Create route table in eu-west-1
resource "aws_route_table" "internet_route" {
  provider = aws.region-jenkins
  vpc_id   = aws_vpc.vpc_master.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-jenkins.id
  }
  route {
    cidr_block                = "10.1.0.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.euwest1-euwest3-tf.id
  }
  route {
    cidr_block                = "10.2.0.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.euwest1-euwest3-docker.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Master-Region-RT"
  }
}

# Overwrite default route table of VPC(Master) with our route table entries
resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
  provider       = aws.region-jenkins
  vpc_id         = aws_vpc.vpc_master.id
  route_table_id = aws_route_table.internet_route.id
}

# Create subnet # 1 in eu-west-1
resource "aws_subnet" "subnet_1_master" {
  provider   = aws.region-jenkins
  vpc_id     = aws_vpc.vpc_master.id
  cidr_block = "10.0.0.0/24"
}

# Create subnet in eu-west-3 for TF worker
resource "aws_subnet" "subnet_1_tf" {
  provider   = aws.region-worker
  vpc_id     = aws_vpc.vpc_worker_tf.id
  cidr_block = "10.1.0.0/24"
}

# Create subnet in eu-west-3 for docker worker
resource "aws_subnet" "subnet_1_docker" {
  provider   = aws.region-worker
  vpc_id     = aws_vpc.vpc_worker_docker.id
  cidr_block = "10.2.0.0/24"
}

# Create route table in eu-west-3
resource "aws_route_table" "internet_route_tf" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_worker_tf.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-worker-tf.id
  }
  route {
    cidr_block                = "10.0.0.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.euwest1-euwest3-tf.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Worker-Region-RT-TF"
  }
}

# Create route table in eu-west-3
resource "aws_route_table" "internet_route_docker" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_worker_docker.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-worker-docker.id
  }
  route {
    cidr_block                = "10.0.0.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.euwest1-euwest3-docker.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Worker-Region-RT-docker"
  }
}

# Overwrite default route table of VPC(Worker TF) with our route table entries
resource "aws_main_route_table_association" "set-worker-default-rt-assoc-tf" {
  provider       = aws.region-worker
  vpc_id         = aws_vpc.vpc_worker_tf.id
  route_table_id = aws_route_table.internet_route_tf.id
}

# Overwrite default route table of VPC(Worker Docker) with our route table entries
resource "aws_main_route_table_association" "set-worker-default-rt-assoc-docker" {
  provider       = aws.region-worker
  vpc_id         = aws_vpc.vpc_worker_docker.id
  route_table_id = aws_route_table.internet_route_docker.id
}


# Create SG for allowing TCP/8080 from * and TCP/22 from your IP in eu-west-1
resource "aws_security_group" "jenkins-sg" {
  provider    = aws.region-jenkins
  name        = "jenkins-sg"
  description = "Allow TCP/8080 & TCP/22"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description = "allow traffic from our public IP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description = "allow traffic from our public IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description = "allow traffic from eu-west-3"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create SG for allowing TCP/22 from your IP in eu-west-3 to TF worker
resource "aws_security_group" "jenkins-sg-worker-tf" {
  provider    = aws.region-worker
  name        = "jenkins-sg-tf"
  description = "Allow TCP/22"
  vpc_id      = aws_vpc.vpc_worker_tf.id
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description = "Allow traffic from eu-west-1"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create SG for allowing TCP/22 from your IP in eu-west-3 to docker worker
resource "aws_security_group" "jenkins-sg-worker-docker" {
  provider    = aws.region-worker
  name        = "jenkins-sg-docker"
  description = "Allow TCP/22"
  vpc_id      = aws_vpc.vpc_worker_docker.id
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description = "Allow traffic from eu-west-1"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}