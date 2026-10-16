variable "tenant_id" {
  type      = string
  sensitive = true
}

variable "vpn_audience" {
  type      = string
  sensitive = true
}

variable "vm_admin_password" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "acr_name" {
  type = string
}

variable "pg_server_name" {
  type = string
}