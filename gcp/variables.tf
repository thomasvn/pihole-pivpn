variable "gcp_project_id" {
  description = "The ID of the GCP project."
  type        = string
  default     = "thomasvn0"
}

variable "service_account_key_file" {
  description = "Path to the service account JSON key file."
  type        = string
  default     = "~/.gcp/thomasvn-iam.json"
}

variable "ssh_key" {
  description = "Path to your SSH private public key file"
  type        = string
  default     = "~/.ssh/thomas-gcp.pub"
}

variable "source_ranges" {
  description = "List of source IP address ranges"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
