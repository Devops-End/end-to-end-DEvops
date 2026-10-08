terraform{
    backend "azurerm"{
        resource_group_name = "storage_rg"
        storage_account_name = "terraformstorageacct"
        container_name = "terraform-container"
        key = "terraform.tfstate"
}
}