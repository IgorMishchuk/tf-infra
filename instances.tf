# Get Linux AMI ID using SSM Parameter endpoint in eu-west-1
data "aws_ssm_parameter" "linuxAmi" {
  provider = aws.region-jenkins
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Get Linux AMI ID using SSM Parameter endpoint in eu-west-3
data "aws_ssm_parameter" "linuxAmiWorker" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Create key-pair for logging into EC2 in eu-west-1
resource "aws_key_pair" "master-key" {
  provider   = aws.region-jenkins
  key_name   = "jenkins"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Create key-pair for logging into EC2 in eu-west-3
resource "aws_key_pair" "worker-key" {
  key_name   = "jenkins"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Create and bootstrap EC2 in eu-west-1
resource "aws_instance" "jenkins-master" {
  provider                    = aws.region-jenkins
  ami                         = data.aws_ssm_parameter.linuxAmi.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.master-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [join(",", [module.main-sgs-mgmt.this_security_group_id, module.main-sgs-workers.this_security_group_id])]
  subnet_id                   = element(module.vpc_main.public_subnets, 0)
  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region-jenkins} --instance-ids ${self.id} \
&& ansible-playbook -v --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/install_jenkins.yml
EOF
  }
  tags = {
    Name = "jenkins_master"
  }
  depends_on = [aws_route.jenkins_internet, module.main-sgs-mgmt]
}

# # Create EC2 in eu-west-3 for Jenkins TF worker
# resource "aws_instance" "jenkins-worker-tf" {
#   provider                    = aws.region-worker
#   count                       = var.tf-workers-count
#   ami                         = data.aws_ssm_parameter.linuxAmiWorker.value
#   instance_type               = var.instance-type
#   key_name                    = aws_key_pair.worker-key.key_name
#   associate_public_ip_address = true
#   vpc_security_group_ids      = [aws_security_group.jenkins-sg-worker-tf.id]
#   subnet_id                   = aws_subnet.subnet_1_tf.id
#   provisioner "remote-exec" {
#     when = destroy
#     inline = [
#       "java -jar /home/ec2-user/jenkins-cli.jar -auth @/home/ec2-user/jenkins_auth -s http://${aws_instance.jenkins-master.private_ip}:8080 -auth @/home/ec2-user/jenkins_auth delete-node ${self.private_ip}"
#     ]
#     connection {
#       type        = "ssh"
#       user        = "ec2-user"
#       private_key = file("~/.ssh/id_rsa")
#       host        = self.public_ip
#     }
#   }

#   provisioner "local-exec" {
#     command = <<EOF
# aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region-worker} --instance-ids ${self.id} \
# && ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name} master_ip=${aws_instance.jenkins-master.private_ip}' ansible_templates/install_worker.yaml
# EOF
#   }
#   tags = {
#     Name = join("_", ["jenkins_worker_tf", count.index + 1])
#   }
#   depends_on = [aws_main_route_table_association.set-worker-default-rt-assoc-tf, aws_instance.jenkins-master]
# }

# # Create EC2 in eu-west-3 for Jenkins docker worker
# resource "aws_instance" "jenkins-worker-docker" {
#   provider                    = aws.region-worker
#   count                       = var.docker-workers-count
#   ami                         = data.aws_ssm_parameter.linuxAmiWorker.value
#   instance_type               = var.instance-type
#   key_name                    = aws_key_pair.worker-key.key_name
#   associate_public_ip_address = true
#   vpc_security_group_ids      = [aws_security_group.jenkins-sg-worker-docker.id]
#   subnet_id                   = aws_subnet.subnet_1_docker.id
#   provisioner "remote-exec" {
#     when = destroy
#     inline = [
#       "java -jar /home/ec2-user/jenkins-cli.jar -auth @/home/ec2-user/jenkins_auth -s http://${aws_instance.jenkins-master.private_ip}:8080 -auth @/home/ec2-user/jenkins_auth delete-node ${self.private_ip}"
#     ]
#     connection {
#       type        = "ssh"
#       user        = "ec2-user"
#       private_key = file("~/.ssh/id_rsa")
#       host        = self.public_ip
#     }
#   }

#   provisioner "local-exec" {
#     command = <<EOF
# aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region-worker} --instance-ids ${self.id} \
# && ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name} master_ip=${aws_instance.jenkins-master.private_ip}' ansible_templates/install_worker.yaml
# EOF
#   }
#   tags = {
#     Name = join("_", ["jenkins_worker_docker", count.index + 1])
#   }
#   depends_on = [aws_main_route_table_association.set-worker-default-rt-assoc-docker, aws_instance.jenkins-master]
# }