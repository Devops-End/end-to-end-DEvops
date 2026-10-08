resource "azurerm_resource_group" "rg" {
  name     = "terraform-rg"
  location = "East US"
}

# vnet 12
resource "azurerm_virtual_network" "vnet" {
  name                = "terraform-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# VM subnet
resource "azurerm_subnet" "subnet" {
  name                 = "terraform-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.0.1.0/24"]
}

# VPN Gateway subnet
resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/27"]
}

# Public IP for VPN Gateway
resource "azurerm_public_ip" "vpn_ip" {
  name                = "terraform-vpn-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# VPN Gateway
resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "terraform-vpn-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "VpnGw1AZ"

  active_active = false
  bgp_enabled   = false

  vpn_client_configuration {
    address_space = ["172.16.0.0/24"]

    vpn_client_protocols = ["OpenVPN"]

    vpn_auth_types = ["AAD"]

    aad_tenant   = "https://login.microsoftonline.com/${var.tenant_id}/"
    aad_audience = var.vpn_audience
    aad_issuer   = "https://sts.windows.net/${var.tenant_id}/"
  }

  ip_configuration {
    name                          = "vpn-gateway-ip"
    public_ip_address_id          = azurerm_public_ip.vpn_ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_subnet.id
  }
}

# NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "terraform-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Attach NSG to VM subnet
resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Allow SSH from VNet
resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "allow-ssh"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name

  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"

  source_address_prefix      = "172.16.0.0/24"
  source_port_range          = "*"
  destination_address_prefix = "*"
  destination_port_range     = "22"
}

# Private NIC
resource "azurerm_network_interface" "nic" {
  name                = "terraform-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Public IP for NAT Gateway ONLY
resource "azurerm_public_ip" "public_ip" {
  name                = "terraform-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  sku               = "Standard"
}

# NAT Gateway
resource "azurerm_nat_gateway" "nat_gateway" {
  name                = "terraform-nat-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name = "Standard"
}

# NAT Gateway -> Public IP
resource "azurerm_nat_gateway_public_ip_association" "nat_public_ip" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.public_ip.id
}

# VM subnet -> NAT Gateway
resource "azurerm_subnet_nat_gateway_association" "subnet_nat" {
  subnet_id      = azurerm_subnet.subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "terraform-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"

  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
