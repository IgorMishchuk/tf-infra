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