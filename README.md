# `teleport-cluster-terraform`

> [!IMPORTANT]
This code in this repo is deprecated.  Please use the code at https://github.com/gravitational/teleport/tree/master/examples/aws/terraform instead.

This repo contains a reference Terraform module that configures a production-worthy high-availability auto-scaling Teleport Cluster.

This cluster makes use of several AWS technologies, provisioned and configured using Terraform.

This module is very similar functionally to the [ha-autoscale-cluster example](https://github.com/gravitational/teleport/tree/master/examples/aws/terraform/ha-autoscale-cluster) with updates to be used as a Terraform module and support Terraform 1.0+.

## Example module usage

Write this content to `main.tf` in the directory where you want to keep your Terraform configs.

```terraform
# load license from file in local directory
data "local_file" "license" {
    filename = "/Users/gus/Downloads/teleport/license.pem"
}

# alternatively, load the license from a variable and write the file locally
# resource "local_file" "license" {
#   sensitive_content = var.teleport_license
#   filename          = "/tmp/license.pem"
# }

# create license resource (which the module depends on)
resource "local_file" "license" {
    sensitive_content = data.local_file.license.content
    filename = "${path.module}/license.pem"
}

module "teleport-cluster-terraform" {
  # source
  source = "github.com/gravitational/teleport-cluster-terraform"

  # the license file must be created first, because the module needs to load it
  depends_on = [local_file.license]

  # Teleport cluster name to set up
  # This cannot be changed later, so pick something descriptive
  cluster_name = "production-teleport-cluster"

  # SSH key name to provision instances with
  # This must be a key that already exists in the AWS account
  key_name = "ops"

  # AMI ID to use
  # See https://github.com/gravitational/teleport/blob/master/examples/aws/terraform/AMIS.md
  ami_id = "ami-072f618d7d3e05cfc"

  # Account ID which owns the AMIs used to spin up instances
  # You should only need to set this if you're building your own AMIs.
  #ami_owner_account_id = "123456789012"

  # Password for Grafana admin user
  # Grafana is hosted on https://<route53_domain>:8443
  grafana_pass = "this-is-the-grafana-password"

  # Whether to use Amazon-issued certificates via ACM or not
  # This must be set to true for any use of ACM whatsoever, regardless of whether Terraform generates/approves the cert
  use_acm = "true"

  # List of AZs to spawn auth/proxy instances in
  # e.g. ["us-east-1a", "us-east-1d"]
  # This must match the region specified in your provider.tf file
  az_list = ["us-east-1c", "us-east-1d"]

  # CIDR to use in the VPC that the module creates
  # This must be at least a /16
  vpc_cidr = "10.10.0.0/16"

  # Zone name which will host DNS records, e.g. example.com
  # This must already be configured in Route 53
  route53_zone = "teleportdemo.net"

  # Domain name to use for Teleport proxies, e.g. proxy.example.com
  # This will be the domain that Teleport users will connect to via web UI or the tsh client
  route53_domain = "production-teleport-cluster.teleportdemo.net"

  # Optional domain name to use for Teleport proxy NLB alias
  # When using ACM we have one ALB (for port 443 with TLS termination) and one NLB
  # (for all other traffic - 3023/3024/3026 etc)
  # As this NLB is at a different address, we add an alias record in Route 53 so that
  # it can be used by applications which connect to it directly (like kubectl) rather
  # than discovering the NLB's address through the Teleport API (like tsh does)
  # Setting this also exposes port 443 on the alias domain to allow the use of Teleport's
  # PostgreSQL listener for database access (with --insecure due to the lack of TLS cert)
  route53_domain_acm_nlb_alias = "production-teleport-cluster-nlb.teleportdemo.net"

  # Email for Let's Encrypt domain registration
  email = "my@email.address"

  # S3 bucket to create for encrypted Let's Encrypt certificates
  # This is also used for storing the Teleport license that is downloaded to auth servers
  # This cannot be a pre-existing bucket
  s3_bucket_name = "production-teleport-cluster.teleportdemo.net"

  # Path to Teleport Enterprise license file
  license_path = local_file.license.filename

  # Instance type used for auth autoscaling group
  auth_instance_type = "m4.xlarge"

  # Instance type used for proxy autoscaling group
  proxy_instance_type = "m4.xlarge"

  # Instance type used for node autoscaling group
  node_instance_type = "t3.medium"

  # Instance type used for monitor autoscaling group
  monitor_instance_type = "t3.medium"

  # AWS KMS alias used for encryption/decryption, defaults to alias used in SSM
  kms_alias_name = "alias/aws/ssm"

  # DynamoDB autoscaling parameters
  autoscale_write_target = 50
  autoscale_read_target = 50
  autoscale_min_read_capacity = 5
  autoscale_max_read_capacity = 100
  autoscale_min_write_capacity = 5
  autoscale_max_write_capacity = 100

  # Default auth type to use on Teleport cluster
  # Useful when you have SAML or OIDC connectors configured in DynamoDB and want to relaunch instances with a new AMI
  auth_type = "local"
}
```

Once this file is written, run `terraform init -upgrade && terraform plan && terraform apply`

## Prerequisites

We recommend familiarizing yourself with the following resources prior to reviewing our Terraform examples:

- [Teleport Architecture](https://goteleport.com/docs/architecture/overview/)
- [Admin Guide](https://goteleport.com/docs/management/admin/)

In order to spin up AWS resources using these Terraform examples, you need the following software:

- terraform v1.0+ [install docs](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- awscli v1.14+ [install docs](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

## How to get help

If you're having trouble, check out [Teleport discussions](https://github.com/gravitational/teleport/discussions).

## Public Teleport AMI IDs

Please [see the AMIS.md file](https://github.com/gravitational/teleport/blob/master/examples/aws/terraform/AMIS.md) for a list of public Teleport AMI IDs that you can use.
