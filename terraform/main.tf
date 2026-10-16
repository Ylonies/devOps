terraform {
  required_version = ">= 0.13"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_network" "custom_bridge_net" {
  name   = "app_isolated_network"
  driver = "bridge"
}

resource "docker_volume" "nginx_volume" {
  name = "nginx_data_volume"
}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "docker_container" "nginx_custom" {
  name  = "nginx_custom_server"
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.custom_bridge_net.name
  }

  volumes {
    volume_name    = docker_volume.nginx_volume.name
    container_path = "/usr/share/nginx/html"
  }

  ports {
    external = 8888
    internal = 80
  }
}