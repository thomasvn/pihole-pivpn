terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
}

output "ssh" {
  value = "ssh -i '~/.ssh/thomas-azure.pem' ubuntu@${azurerm_linux_virtual_machine.pi-hole.public_ip_address}"
  description = "Command to ssh into the box"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "pi-hole-resourcegroup" {
  name     = "pi-hole-resourcegroup"
  location = "westus3"
}

resource "azurerm_virtual_network" "pi-hole-network" {
  name                = "pi-hole-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.pi-hole-resourcegroup.location
  resource_group_name = azurerm_resource_group.pi-hole-resourcegroup.name
}

resource "azurerm_subnet" "pi-hole-subnet" {
  name                 = "pi-hole-subnet"
  resource_group_name  = azurerm_resource_group.pi-hole-resourcegroup.name
  virtual_network_name = azurerm_virtual_network.pi-hole-network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "pi-hole-sg" {
  name                = "pi-hole-sg"
  location            = azurerm_resource_group.pi-hole-resourcegroup.location
  resource_group_name = azurerm_resource_group.pi-hole-resourcegroup.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "OpenVPN"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "UDP"
    source_port_range          = "*"
    destination_port_range     = "1194"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Egress"
    priority                   = 2001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "pi-hole-sga" {
  subnet_id                 = azurerm_subnet.pi-hole-subnet.id
  network_security_group_id = azurerm_network_security_group.pi-hole-sg.id
}

resource "azurerm_public_ip" "pi-hole-ip" {
  name                = "pi-hole-ip"
  location            = azurerm_resource_group.pi-hole-resourcegroup.location
  resource_group_name = azurerm_resource_group.pi-hole-resourcegroup.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "pi-hole-nic" {
  name                = "pi-hole-nic"
  location            = azurerm_resource_group.pi-hole-resourcegroup.location
  resource_group_name = azurerm_resource_group.pi-hole-resourcegroup.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.pi-hole-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pi-hole-ip.id
  }
}

resource "azurerm_linux_virtual_machine" "pi-hole" {
  name                            = "pi-hole"
  resource_group_name             = azurerm_resource_group.pi-hole-resourcegroup.name
  location                        = azurerm_resource_group.pi-hole-resourcegroup.location
  size                            = "Standard_B1ls" # 1vCPU, 0.5GB RAM, westus3 $3.80/month
  admin_username                  = "ubuntu"
  network_interface_ids           = [azurerm_network_interface.pi-hole-nic.id]
  disable_password_authentication = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  # source_image_reference {
  #   publisher = "Canonical"
  #   offer     = "0001-com-ubuntu-server-jammy"
  #   sku       = "22_04-lts-gen2"
  #   version   = "latest"
  # }

  computer_name   = "pi-hole-vm"

  # SPOT NOT SUPPORTED FOR THIS INSTANCE TYPE
  # priority        = "Spot"
  # eviction_policy = "Deallocate"

  admin_ssh_key {
    username   = "ubuntu"
    public_key = file("~/.ssh/thomas-azure.pub")
  }

  tags = {
    environment = "test"
  }
}
