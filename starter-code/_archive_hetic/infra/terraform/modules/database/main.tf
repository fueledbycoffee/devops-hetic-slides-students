terraform {
    required_version = ">= 1.5"
    required_providers {
        docker = {
            source = "kreuzwerker/docker"
            version = "~> 3.0"
        }
    }
}

resource "docker_image" "db" {
  name         = "postgres:16-alpine"
  keep_locally = true
}

resource "docker_container" "db" {
  name  = "${var.app_name}-db-${var.environment}"
  image = docker_image.db.image_id

  env = [
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
  ]

  ports {
    internal = 5432
    external = var.db_port
  }

  networks_advanced {
    name = var.network_id
  }

  volumes {
    host_path      = "/tmp/${var.app_name}-db-${var.environment}"
    container_path = "/var/lib/postgresql/data"
  }
}