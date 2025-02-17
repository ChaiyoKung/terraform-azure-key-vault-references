variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID"
}

variable "my_secret" {
  type        = string
  description = "The secret to store in the Key Vault"
  sensitive   = true
}
