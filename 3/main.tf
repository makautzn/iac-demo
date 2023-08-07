resource "azurerm_resource_group" "group" {
  name     = local.resourceGroupName
  location = var.location
  tags = {
    purpose = "demo"
  }
}

resource "azurerm_service_plan" "plan" {
  name                = local.planName
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  os_type             = "Windows"
  sku_name            = "S1"
}

resource "azurerm_windows_web_app" "app" {
  name                = local.webAppName
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {}
}