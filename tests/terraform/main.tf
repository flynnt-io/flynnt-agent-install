terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.69.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
  }

  backend "s3" {
    bucket       = "flynnt-tfstate"
    key          = "flynnt-agent-install/tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

data "sops_file" "secrets" {
  source_file = "secrets.enc.yaml"
}

variable "flynnt_cluster" {
  type        = string
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

resource "hcloud_server" "ubuntu_26_04" {
  name        = "test-ubuntu-26"
  image       = "ubuntu-26.04"
  server_type = "cx23"
  location    = "nbg1"

  ssh_keys = [data.hcloud_ssh_key.flynnt_key.name]

  labels = {
    project = "flynnt-agent-install"
  }

  user_data = <<-EOF
    #cloud-config
    runcmd:
    - echo -n '${data.local_file.flynnt_script.content_base64}' | base64 -d > /usr/local/bin/flynnt
    - chmod +x /usr/local/bin/flynnt
    - API_KEY=${data.sops_file.secrets.data["flynnt_token"]} flynnt install -c ${var.flynnt_cluster} -n test-ubuntu-26
  EOF
}

resource "hcloud_server" "ubuntu_24_04" {
  name        = "test-ubuntu-24"
  image       = "ubuntu-24.04"
  server_type = "cx23"
  location    = "nbg1"

  ssh_keys = [data.hcloud_ssh_key.flynnt_key.name]

  labels = {
    project = "flynnt-agent-install"
  }

  user_data = <<-EOF
    #cloud-config
    runcmd:
    - echo -n '${data.local_file.flynnt_script.content_base64}' | base64 -d > /usr/local/bin/flynnt
    - chmod +x /usr/local/bin/flynnt
    - API_KEY=${data.sops_file.secrets.data["flynnt_token"]} flynnt install -c ${var.flynnt_cluster} -n test-ubuntu-24
  EOF
}

resource "hcloud_server" "debian_13" {
  name        = "test-debian-13"
  image       = "debian-13"
  server_type = "cx23"
  location    = "nbg1"

  ssh_keys = [data.hcloud_ssh_key.flynnt_key.name]

  labels = {
    project = "flynnt-agent-install"
  }

  user_data = <<-EOF
    #cloud-config
    runcmd:
    - echo -n '${data.local_file.flynnt_script.content_base64}' | base64 -d > /usr/local/bin/flynnt
    - chmod +x /usr/local/bin/flynnt
    - API_KEY=${data.sops_file.secrets.data["flynnt_token"]} flynnt install -c ${var.flynnt_cluster} -n test-debian-13
  EOF
}
