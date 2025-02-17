data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "example" {
  name     = "rg-tfkvref"
  location = "Southeast Asia"
}

resource "azurerm_key_vault" "example" {
  name                      = "kv-tfkvref"
  resource_group_name       = azurerm_resource_group.example.name
  location                  = azurerm_resource_group.example.location
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  enable_rbac_authorization = true
}

resource "azurerm_role_assignment" "client" {
  scope                = azurerm_key_vault.example.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "example" {
  name         = "my-secret"
  value        = var.my_secret
  key_vault_id = azurerm_key_vault.example.id
  depends_on = [
    azurerm_role_assignment.client
  ]
}

resource "azurerm_user_assigned_identity" "example" {
  name                = "id-tfkvref"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

resource "azurerm_role_assignment" "example" {
  scope                = azurerm_key_vault.example.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.example.principal_id
}

resource "azurerm_service_plan" "example" {
  name                = "asp-tfkvref"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  os_type             = "Windows"
  sku_name            = "F1"
}

resource "azurerm_windows_web_app" "example" {
  name                = "app-tfkvref"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  service_plan_id     = azurerm_service_plan.example.id

  site_config {
    always_on = false // always_on must be explicitly set to false when using Free, F1, D1, or Shared Service Plans.
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.example.id
    ]
  }

  key_vault_reference_identity_id = azurerm_user_assigned_identity.example.id

  app_settings = {
    "MySecret" = "@Microsoft.KeyVault(SecretUri=https://${azurerm_key_vault.example.name}.vault.azure.net/secrets/${azurerm_key_vault_secret.example.name})"
  }
}
