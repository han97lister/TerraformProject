provider "azurerm" {
    features {}
}

module "london" {
    source = "./ScaleSet"
    location = "uksouth"
    in = "9"
    inmins = "0"
    out = "17"
    outmins = "0"
    environment = "Development"
}

module "mumbai" {
    source = "./ScaleSet"
    location = "eastasia"
    in = "2"
    inmins = "30"
    out = "10"
    outmins = "30"
    environment = "Production"
}

module "paris" {
    source = "./ScaleSet"
    location = "francecentral"
    in = "10"
    inmins = "0"
    out = "15"
    outmins = "0"
    environment = "Staging"
}