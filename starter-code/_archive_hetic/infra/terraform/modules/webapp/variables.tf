variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "image" {
  type    = string
  default = "nginx:alpine"
}

variable "port" {
  type    = number
  default = 80
}

variable "replicas" {
  type    = number
  default = 1
}

variable "network_id" {
  type = string
}