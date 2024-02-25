terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.44.1"
    }
    sops = {
      source = "carlpett/sops"
      version = "1.0.0"
    }
  }

  backend "s3" {
    bucket = "flynnt-tfstate"
    key    = "flynnt-agent-install/tfstate"
    region = "eu-central-1"
  }
}

data "sops_file" "secrets" {
  source_file = "secrets.enc.yaml"
}

variable "flynnt_cluster" {
  type = string
  description = "The cluster name that will be used for tests"
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = data.sops_file.secrets.data["hcloud_token"]
}

data "local_file" "flynnt_script" {
  filename = "${path.cwd}/flynnt"
}

data "hcloud_ssh_key" "flynnt_key" {
  name = "flynntkey"
}

resource "hcloud_server" "ubuntu_22_04" {
  name        = "test-ubuntu-22"
  image       = "ubuntu-22.04"
  server_type = "cx21"
  location    = "nbg1"

  ssh_keys = [data.hcloud_ssh_key.flynnt_key.name]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  labels = {
    project = "flynnt-agent-install"
  }

  user_data = <<-EOF
    #cloud-config
    runcmd:
    - echo -n '${data.local_file.flynnt_script.content_base64}' | base64 -d > /usr/local/bin/flynnt
    - chmod +x /usr/local/bin/flynnt
    - API_KEY=${data.sops_file.secrets.data["flynnt_token"]} flynnt install -c ${var.flynnt_cluster} -n test-ubuntu-22
  EOF
}

resource "hcloud_server" "ubuntu_20_04" {
  name        = "test-ubuntu-20"
  image       = "ubuntu-20.04"
  server_type = "cx21"
  location    = "nbg1"

  ssh_keys = [data.hcloud_ssh_key.flynnt_key.name]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  labels = {
    project = "flynnt-agent-install"
  }

  user_data = <<-EOF
    #cloud-config
    runcmd:
    - echo -n '${data.local_file.flynnt_script.content_base64}' | base64 -d > /usr/local/bin/flynnt
    - chmod +x /usr/local/bin/flynnt
    - API_KEY=${data.sops_file.secrets.data["flynnt_token"]} flynnt install -c ${var.flynnt_cluster} -n test-ubuntu-20
  EOF
}

resource "hcloud_server" "debian_12" {
  name        = "test-debian-12"
  image       = "debian-12"
  server_type = "cx21"
  location    = "nbg1"

  ssh_keys = [data.hcloud_ssh_key.flynnt_key.name]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  labels = {
    project = "flynnt-agent-install"
  }

  user_data = <<-EOF
    #cloud-config
    runcmd:
    - echo -n '${data.local_file.flynnt_script.content_base64}' | base64 -d > /usr/local/bin/flynnt
    - chmod +x /usr/local/bin/flynnt
    - API_KEY=${data.sops_file.secrets.data["flynnt_token"]} flynnt install -c ${var.flynnt_cluster} -n test-debian-12
  EOF
}

