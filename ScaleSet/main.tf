#Azure Provider
provider "azurerm" {
  features {}
}

#VNET
resource "azurerm_virtual_network" "terraformProject" {
  name                = "Tnetwork"
  resource_group_name = azurerm_resource_group.terraformProject.name
  location            = azurerm_resource_group.terraformProject.location
  address_space       = ["10.0.0.0/16"]
}

#Subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.terraformProject.name
  virtual_network_name = azurerm_virtual_network.Tnetwork.name
  address_prefixes     = ["10.0.2.0/24"]
}

#VM
resource "azurerm_linux_virtual_machine_scale_set" "terraformProject" {
  name                = "example-vmss"
  resource_group_name = azurerm_resource_group.terraformProject.name
  location            = azurerm_resource_group.terraformProject.location
  sku                 = "Standard_F2"
  instances           = 1
  admin_username      = "adminuser"

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "example"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.internal.id
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "terraformProject" {
  name                = "myAutoscaleSetting"
  resource_group_name = azurerm_resource_group.terraformProject.name
  location            = azurerm_resource_group.terraformProject.location
  target_resource_id  = azurerm_virtual_machine_scale_set.terraformProject.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 1
      minimum = 0
      maximum = 3
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.terraformProject.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.terraformProject.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }  

    recurrence {
      timezone = "GMT Standard Time"
      days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      hours = [var.in]
      minutes = [var.inmins]
    }
  }
  profile {
    name = "Downscale"

    capacity {
      default = 0
      minimum = 0
      maximum = 0
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.terraformProject.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 0
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    recurrence {
      #frequency = "Week"
      timezone = "GMT Standard Time"
      days     = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      hours    = [var.out]
      minutes  = [var.outmins]
    }
  }
}