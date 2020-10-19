# Set default profile
variable "profile" {
  default = "default"
}

# Define region for Jenkins worker nodes
variable "region-worker" {
  default = "eu-west-3"
}

# Define region for Jenkins master
variable "region-jenkins" {
  default = "eu-west-1"
}

# How many Jenkins workers to spin up
variable "tf-workers-count" {
  default = 2
}

# How many Jenkins workers to spin up
variable "docker-workers-count" {
  default = 2
}

# Define instance type
variable "instance-type" {
  default = "t2.micro"
}

# Operator's IP
variable "external_ip" {
  default = "213.111.81.135/32"
}

# TF master IP
variable "tf_master_ip" {
  default = "35.180.19.250/32"
}

variable "workers" {
  description = "Map of worker settings to configure"
  default = {
    tf-worker = {
      cidr          = "10.1.0.0/16",
      instance-type = "t2.micro",
      name          = "vpc-tf-worker",
      public_subnet = ["10.1.0.0/24"]
    },
    docker-worker = {
      cidr          = "10.2.0.0/16",
      instance-type = "t2.micro",
      name          = "vpc-docker-worker",
      public_subnet = ["10.2.0.0/24"]
    }
  }
}

variable "jenkins_main_ip" {
  default = "10.0.0.0"
}

variable "sgs" {
  default = {
    ssh = {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      src = "213.111.81.135/32"
    },
    jenkins_main = {
      from_port = 0
      to_port = 0
      protocol = "-1"
      src = "10.0.0.0/24"
    }
  }
}