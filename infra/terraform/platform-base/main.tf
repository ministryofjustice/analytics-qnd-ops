terraform {
  backend "s3" {
    bucket               = "terraform.analytics.justice.gov.uk"
    workspace_key_prefix = "platform-base:"
    key                  = "terraform.tfstate"
    region               = "eu-west-1"
  }
}

provider "aws" {
  region  = "${var.region}"
  version = "~> 1.50"
}

module "aws_vpc" {
  source = "../modules/aws_vpc"

  name               = "${terraform.workspace}.${data.terraform_remote_state.global.platform_root_domain}"
  cidr               = "${var.vpc_cidr}"
  availability_zones = "${var.availability_zones}"
}

module "cluster_dns" {
  source = "../modules/cluster_dns"

  env              = "${terraform.workspace}"
  root_zone_name   = "${data.terraform_remote_state.global.platform_dns_zone_name}"
  root_zone_domain = "${data.terraform_remote_state.global.platform_root_domain}"
  root_zone_id     = "${data.terraform_remote_state.global.platform_dns_zone_id}"
}

module "auth0" {
  source = "../modules/auth0"

  env                        = "${terraform.workspace}"
  auth0_api_client_id        = "${var.auth0_api_client_id}"
  auth0_api_client_secret    = "${var.auth0_api_client_secret}"
  auth0_rules                = "${var.auth0_rules}"
  auth0_rules_config         = "${var.auth0_rules_config}"
  auth0_tenant_domain        = "${var.oidc_provider_domain}"
  aws_account_id             = "${var.aws_account_id}"
  github_oauth_client_id     = "${var.github_oauth_client_id}"
  github_oauth_client_secret = "${var.github_oauth_client_secret}"
  github_orgs                = "${var.github_orgs}"
  google_domains             = "${var.google_domains}"
  mfa_disabled_ip_ranges     = "${var.mfa_disabled_ip_ranges}"
  root_domain                = "${data.terraform_remote_state.global.platform_root_domain}"
}

module "federated_identity" {
  source = "../modules/federated_identity"

  env                       = "${terraform.workspace}"
  oidc_provider_url         = "https://${var.oidc_provider_domain}/"
  oidc_client_id            = "${module.auth0.aws_client_id}"
  oidc_provider_thumbprints = ["${var.oidc_provider_thumbprints}"]
  saml_domain               = "${var.idp_saml_domain}"
  saml_signon_url           = "${var.idp_saml_signon_url}"
  saml_logout_url           = "${var.idp_saml_logout_url}"
  saml_x509_cert            = "${var.idp_saml_x509_cert}"
}

module "kops_spec" {
  source = "../modules/kops_spec"

  k8s_version = "${var.k8s_version}"

  kops_state_bucket = "${data.terraform_remote_state.global.kops_bucket_name}"

  vpc_id                            = "${module.aws_vpc.vpc_id}"
  vpc_cidr                          = "${module.aws_vpc.cidr}"
  availability_zones                = ["${var.k8s_availability_zones}"]
  public_subnet_ids                 = ["${slice(module.aws_vpc.dmz_subnet_ids, 0, length(var.k8s_availability_zones))}"]
  public_subnet_cidr_blocks         = ["${slice(module.aws_vpc.dmz_subnet_cidr_blocks, 0, length(var.k8s_availability_zones))}"]
  public_subnet_availability_zones  = ["${slice(module.aws_vpc.dmz_subnet_availability_zones, 0, length(var.k8s_availability_zones))}"]
  private_subnet_ids                = ["${slice(module.aws_vpc.private_subnet_ids, 0, length(var.k8s_availability_zones))}"]
  private_subnet_cidr_blocks        = ["${slice(module.aws_vpc.private_subnet_cidr_blocks, 0, length(var.k8s_availability_zones))}"]
  private_subnet_availability_zones = ["${slice(module.aws_vpc.private_subnet_availability_zones, 0, length(var.k8s_availability_zones))}"]

  cluster_dns_name = "${module.cluster_dns.dns_zone_domain}"
  cluster_dns_zone = "${module.cluster_dns.dns_zone_id}"

  oidc_client_id  = "${module.auth0.aws_client_id}"
  oidc_issuer_url = "https://${var.oidc_provider_domain}/"

  instancegroup_image = "${var.k8s_instancegroup_image}"

  masters_extra_sg_id      = "${module.aws_vpc.extra_master_sg_id}"
  masters_machine_type     = "${var.k8s_masters_machine_type}"
  masters_root_volume_size = "${var.k8s_masters_root_volume_size}"

  nodes_extra_sg_id            = "${module.aws_vpc.extra_node_sg_id}"
  nodes_machine_type           = "${var.k8s_nodes_machine_type}"
  nodes_instancegroup_min_size = "${var.k8s_nodes_instancegroup_min_size}"
  nodes_instancegroup_max_size = "${var.k8s_nodes_instancegroup_max_size}"
  nodes_root_volume_size       = "${var.k8s_nodes_root_volume_size}"

  highmem_nodes_machine_type           = "${var.k8s_highmem_nodes_machine_type}"
  highmem_nodes_instancegroup_min_size = "${var.k8s_highmem_nodes_instancegroup_min_size}"
  highmem_nodes_instancegroup_max_size = "${var.k8s_highmem_nodes_instancegroup_max_size}"
  highmem_nodes_root_volume_size       = "${var.k8s_highmem_nodes_root_volume_size}"

  bastions_extra_sg_id            = "${module.aws_vpc.extra_bastion_sg_id}"
  bastions_machine_type           = "${var.k8s_bastions_machine_type}"
  bastions_instancegroup_min_size = "${var.k8s_bastions_instancegroup_min_size}"
  bastions_instancegroup_max_size = "${var.k8s_bastions_instancegroup_max_size}"
  bastions_root_volume_size       = "${var.k8s_bastions_root_volume_size}"
}
