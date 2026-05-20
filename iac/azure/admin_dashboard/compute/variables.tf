# ─────────────────────────────────────────────────────────────────────────────
# compute/variables.tf
#
# Networking values (resource group, location, VNet/subnet/NSG names) are read
# automatically from the networking/ stack via terraform_remote_state in main.tf.
# Only VM-specific variables are declared here.
# ─────────────────────────────────────────────────────────────────────────────

variable "vm_hostname" {
  description = "Hostname prefix. The VM will be named <vm_hostname>-vmLinux-0 by the Azure/compute/azurerm module."
  type        = string
  default     = "admin-dashboard"
}

# ── VM size ────────────────────────────────────────────────────────────────────
# Common DC-Series options (confidential compute, Intel SGX):
#   Standard_D2a_v4  — 2 vCPU / 8 GB   (default, balanced)
#   Standard_D4a_v4  — 4 vCPU / 16 GB  (heavier workloads)
#   Standard_D8a_v4  — 8 vCPU / 32 GB  (high performance)
#   Standard_D8a_v4 — 16 vCPU / 64 GB (large scale)
variable "vm_size" {
  description = "Azure VM SKU size. Adjust to control cost vs. performance."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Admin username for the VM."
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Admin password for the VM. Must satisfy Azure complexity requirements (12+ chars, upper, lower, digit, special)."
  type        = string
  default     = "C0mp@ny@dm1n"
  sensitive   = true
}

variable "github_repo_url" {
  description = "GitHub repository URL to clone on first boot (e.g. https://github.com/org/repo.git)."
  default     = "https://github.com/jeffreyhooperjj/CompanyDashboards"
  type        = string
}

variable "github_pat" {
  description = "GitHub Personal Access Token. Used to clone the repo, register the self-hosted runner, and authenticate workflow steps. Required permissions: repo (Full control) + workflow (Update GitHub Action workflows). Generate at https://github.com/settings/tokens"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_branch" {
  description = "Git branch to check out when cloning the repository on first boot. Also stored in /etc/github-runner.env as GITHUB_BRANCH so workflow steps can reference it."
  type        = string
  default     = "prod"
}

variable "domain_name" {
  description = "Fully qualified domain name for the admin dashboard (e.g. admin.datecompany.com). Used for the Let's Encrypt TLS certificate and nginx server_name. DNS must already point to the VM's public IP before applying."
  type        = string
  default     = "admin.datecompany.com"
}

variable "app_port" {
  description = "Host port the Docker Compose app binds to on localhost. Nginx proxies HTTPS traffic to this port. Must not be 80 or 443 (those are owned by nginx). The cloud-init script patches the app's docker-compose.yml port binding to this value automatically."
  type        = number
  default     = 8080
}
