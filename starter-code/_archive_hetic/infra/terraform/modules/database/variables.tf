variable "app_name" { type = string }
variable "environment" { type = string }
variable "network_id" { type = string }
variable "db_name" {
  type    = string
  default = "appdb"
}
variable "db_user" {
  type    = string
  default = "appuser"
}
variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_port" {
  type    = number
  default = 5432
}