#Defining multiple providers using "alias" parameter
provider "aws" {
  profile = var.profile
  region  = var.region-jenkins
  alias   = "region-jenkins"
}

provider "aws" {
  profile = var.profile
  region  = var.region-worker
  #alias   = "region-worker"
}