terraform {
    required_version = ">= 1.5"
    required_providers {
        docker = {
            source = "kreuzwerker/docker"
            version = "~> 3.0"
        }
    }
}

provider "docker" {}

resource "docker_network" "app_network" {
    name = "devops-network"
}

resource "docker_image" "nginx" {
    name = "nginx:alpine"
    keep_locally = true
}

resource "docker_container" "web" {
    name = "${var.app_name}-${var.environment}"
    image = docker_image.nginx.image_id

    ports {
        internal = 80
        external = 8080
    }

    networks_advanced {
        name = docker_network.app_network.name
    }

    env = [
        "NGINX_HOST=localhost",
        "NGINX_PORT=80"
    ]
}

output "web_url" {
    value = "http://localhost:${docker_container.web.ports[0].external}"
    description = "URL du serveur web"
}

output "container_id" {
    value = docker_container.web.id
}