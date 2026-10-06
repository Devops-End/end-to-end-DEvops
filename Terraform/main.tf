resource "azurerm_resource_group" "rg"{
    name = "terraform-rg"
    location = "East US"
}

resource "azurerm_virtual_network" "vnet"{
    name = "terraform-vnet"
    location = "East US"
    resource_group_name = azurerm_resource_group.rg.name
    address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet"{
    name = "terraform-subnet"
    virtual_network_name = azurerm_virtual_network.vnet.name
    resource_group_name = azurerm_resource_group.rg.name
    address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg"{
    name = "terraform-nsg"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg"{
    subnet_id = azurerm_subnet.subnet.id
    network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_security_rule" "allow_ssh"{
 name = "allow-ssh"
 resource_group_name = azurerm_resource_group.rg.name
 network_security_group_name = azurerm_network_security_group.nsg.name
 priority = 100
 direction = "Inbound"
 access = "Allow"
 protocol = "Tcp"
 source_address_prefix = "VirtualNetwork"
 source_port_range = "*"
 destination_address_prefix = "*"
 destination_port_range = "22"
}

resource "azurerm_network_interface" "nic"{
    name = "terraform-nic"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    ip_configuration{
        name = "internal"
        subnet_id = azurerm_subnet.subnet.id
        private_ip_address_allocation = "Dynamic"
    }
}