terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.13.0"
    }
  }
}

provider "docker" {}

data "docker_registry_image" "observer" {
  name = "reg.docker.alibaba-inc.com/antman/ob-docker:OB323_OBP324_x86_20220518"
}

resource "docker_image" "observer" {
  name         = data.docker_registry_image.name
  keep_locally = true
  pull_triggers = [data.docker_registry_image.observer.sha256_digest]
}

resource "docker_network" "ob_network" {
  name = "ob_network"
  attachable= true
  driver = host
}

resource "docker_container" "observer" {
  image = docker_image.observer.name
  name  = "terraform-observer"
  attach = true
  privileged = true
  restart = "on-failure"
  max_retry_count = 5
  network{
    name = docker_network.ob_network.name
  }
  
}
