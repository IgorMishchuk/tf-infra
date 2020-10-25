data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc_main" {
  source = "terraform-aws-modules/vpc/aws"
  providers = {
    aws = aws.region-jenkins
  }
  version        = "~> v2.0"
  azs            = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  name           = "vpc-jenkins-master"
  cidr           = var.jenkins_main_cidr
  public_subnets = [cidrsubnet(var.jenkins_main_cidr, 8, 0)]
  tags = {
    Name = "vpc-jenkins-master"
  }

}

module "vpc_workers" {
  source         = "terraform-aws-modules/vpc/aws"
  version        = "~> v2.0"
  for_each       = var.workers
  azs            = data.aws_availability_zones.available.names
  name           = each.value.name
  cidr           = each.value.cidr
  public_subnets = [cidrsubnet(each.value.cidr, 8, 0)]
  tags = {
    Name = each.value.name
  }
}

module "vpc_peering" {
  source  = "cornfeedhobo/vpc-peering/aws"
  version = "~> 2.0.1"
  providers = {
    aws.requester = aws.region-jenkins
    aws.accepter  = aws
  }
  for_each                  = var.workers
  accepter-account_id       = module.vpc_workers[each.key].vpc_owner_id
  accepter-route_table_ids  = list(module.vpc_workers[each.key].vpc_main_route_table_id)
  accepter-vpc_cidr_blocks  = list(module.vpc_workers[each.key].vpc_cidr_block)
  accepter-vpc_id           = module.vpc_workers[each.key].vpc_id
  requester-route_table_ids = list(module.vpc_main.vpc_main_route_table_id)
  requester-vpc_cidr_blocks = list(module.vpc_main.vpc_cidr_block)
  requester-vpc_id          = module.vpc_main.vpc_id
  tags = {
    Name = join("-", ["peering", each.value.name])
  }
}

resource "aws_route" "jenkins_internet" {
  provider               = aws.region-jenkins
  route_table_id         = module.vpc_main.vpc_main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.vpc_main.igw_id
}

resource "aws_route" "workers_internet" {
  for_each               = var.workers
  route_table_id         = module.vpc_workers[each.key].vpc_main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.vpc_workers[each.key].igw_id
}

module "worker-sgs" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "~> 3.0"
  for_each            = var.workers
  vpc_id              = module.vpc_workers[each.key].vpc_id
  name                = "worker-sgs"
  ingress_cidr_blocks = [var.external_ip]
  ingress_rules       = ["ssh-tcp"]
  ingress_with_self   = [{ rule = "all-all" }]
  egress_rules        = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port    = 0
      to_port      = 0
      protocol     = "tcp"
      cidr_blocks  = cidrsubnet(var.jenkins_main_cidr, 8, 0)
      descriptions = "Allow connections from Jenkins main"
    }
  ]
}

module "main-sgs-mgmt" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"
  providers = {
    aws = aws.region-jenkins
  }
  vpc_id              = module.vpc_main.vpc_id
  name                = "main-sgs-mgmt"
  ingress_cidr_blocks = [var.external_ip, var.tf_master_ip]
  ingress_rules       = ["ssh-tcp", "http-80-tcp", "http-8080-tcp"]
  ingress_with_self   = [{ rule = "all-all" }]
  egress_rules        = ["all-all"]

}

module "main-sgs-workers" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"
  providers = {
    aws = aws.region-jenkins
  }
  name   = "main-sgs-workers"
  vpc_id = module.vpc_main.vpc_id
  ingress_cidr_blocks = [
    for worker in var.workers :
    join(",", [cidrsubnet(worker.cidr, 8, 0)])
  ]
  ingress_rules = ["all-all"]
}