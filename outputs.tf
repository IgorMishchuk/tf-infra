# output "amiId-eu-west-1" {
#   value = data.aws_ssm_parameter.linuxAmi.value
# }

# output "amiId-eu-west-3" {
#   value = data.aws_ssm_parameter.linuxAmiWorker.value
# }

# output "Jenkins-Main-Node-Public-IP" {
#   value = join(":", [aws_instance.jenkins-master.public_ip, "8080"])
# }

# output "Jenkins-Main-Node-Private-IP" {
#   value = aws_instance.jenkins-master.private_ip
# }

# output "Jenkins-Worker-TF-Public-IPs" {
#   value = {
#     for instance in aws_instance.jenkins-worker-tf :
#     instance.id => instance.public_ip
#   }
# }

# output "Jenkins-Worker-TF-Private-IPs" {
#   value = {
#     for instance in aws_instance.jenkins-worker-tf :
#     instance.id => instance.private_ip
#   }
# }

# output "Jenkins-Worker-Docker-Public-IPs" {
#   value = {
#     for instance in aws_instance.jenkins-worker-docker :
#     instance.id => instance.public_ip
#   }
# }

# output "Jenkins-Worker-Docker-Private-IPs" {
#   value = {
#     for instance in aws_instance.jenkins-worker-docker :
#     instance.id => instance.private_ip
#   }
# }

output "subnets" {
  value = module.vpc_main.public_subnets
}

output "sgs" {
  value = join(",", [module.main-sgs-mgmt.this_security_group_id, module.main-sgs-workers.this_security_group_id])
}