variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}

variable "cdn_url" {
  description = "The URL for the CDN"
  type        = string
}