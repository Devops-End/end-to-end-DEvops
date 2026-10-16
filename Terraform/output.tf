output "pg_fqdn" {
  value = azurerm_postgresql_flexible_server.pg.fqdn
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}