# admin-dashboard — Azure Infrastructure

Three independent Terraform stacks that must be applied **in order** on first deploy.
Each stack has its own state file, so they can be planned, applied, and destroyed independently after that.

```
admin_dashboard/
├── networking/          # Stack 1 — Resource Group · VNet · NSG (ports 22 + 80)
├── compute/             # Stack 2 — Linux VM · static public IP · cloud-init
└── compute_controls/    # Stack 3 — Azure Automation scheduled start / stop
```

---

## Prerequisites

| Tool | Version |
|---|---|
| Terraform | ≥ 1.3 |
| Azure CLI (`az`) | any recent |
| SSH key pair | `~/.ssh/id_rsa` + `~/.ssh/id_rsa.pub` |

Authenticate with Azure before running any stack:

```bash
az login
az account set --subscription "<your-subscription-id>"
```

---

## Full deploy (all three stacks)

Run these commands from the `admin_dashboard/` directory.

```bash
# ── 1. Networking ──────────────────────────────────────────────────────────────
cd networking
terraform init
terraform apply \
  -var="resource_group_name=admin-dashboard-rg" \
  -var="location=East US"

# Capture outputs for the next stacks
SUBNET_ID=$(terraform output -raw subnet_id)
NSG_ID=$(terraform output -raw nsg_id)
RG=$(terraform output -raw resource_group_name)
LOCATION=$(terraform output -raw location)

# ── 2. Compute ─────────────────────────────────────────────────────────────────
cd ../compute
terraform init
terraform apply \
  -var="resource_group_name=$RG" \
  -var="location=$LOCATION" \
  -var="subnet_id=$SUBNET_ID" \
  -var="nsg_id=$NSG_ID" \
  -var="ssh_public_key_value=$(cat ~/.ssh/id_rsa.pub)" \
  -var="github_repo_url=https://github.com/org/repo.git" \
  -var="github_branch=main" \
  -var="github_pat=ghp_yourTokenHere" \
  -var="vm_size=Standard_B2s"

VM_NAME=$(terraform output -raw vm_name)

# ── 3. Compute Controls ─────────────────────────────────────────────────────────
cd ../compute_controls
terraform init
terraform apply \
  -var="resource_group_name=$RG" \
  -var="location=$LOCATION" \
  -var="vm_name=$VM_NAME"
```

After apply, the compute stack prints:

```
ssh_command   = "ssh azureuser@<public-ip>"
http_url      = "http://<public-ip>"
vm_public_fqdn = "admin-dashboard-pip.eastus.cloudapp.azure.com"
```

---

## Partial runs

### networking/ only

```bash
cd networking
terraform init
terraform apply \
  -var="resource_group_name=admin-dashboard-rg" \
  -var="location=East US"
```

Use this to update the VNet CIDR, NSG rules, or recreate the resource group without touching the VM.

---

### compute/ only

Run after `networking/` has been applied at least once.

```bash
cd compute

# Pull the required IDs from the networking state
SUBNET_ID=$(cd ../networking && terraform output -raw subnet_id)
NSG_ID=$(cd ../networking && terraform output -raw nsg_id)
RG=$(cd ../networking && terraform output -raw resource_group_name)
LOCATION=$(cd ../networking && terraform output -raw location)

terraform init
terraform apply \
  -var="resource_group_name=$RG" \
  -var="location=$LOCATION" \
  -var="subnet_id=$SUBNET_ID" \
  -var="nsg_id=$NSG_ID" \
  -var="ssh_public_key_value=$(cat ~/.ssh/id_rsa.pub)" \
  -var="github_repo_url=https://github.com/org/repo.git" \
  -var="github_branch=main" \
  -var="github_pat=ghp_yourTokenHere" \
  -var="vm_size=Standard_B2s"
```

Use this to resize the VM, swap the GitHub repo/branch, or rotate the PAT without touching networking.

#### VM size options

| SKU | vCPU | RAM | Notes |
|---|---|---|---|
| `Standard_B1s` | 1 | 1 GB | Cheapest — light dev only |
| `Standard_B2s` | 2 | 4 GB | **Default** — balanced |
| `Standard_B4ms` | 4 | 16 GB | Heavier workloads |
| `Standard_D2s_v3` | 2 | 8 GB | General purpose |
| `Standard_D4s_v3` | 4 | 16 GB | General purpose, faster |

---

### compute_controls/ only

Run after `compute/` has been applied at least once.

```bash
cd compute_controls

RG=$(cd ../networking && terraform output -raw resource_group_name)
LOCATION=$(cd ../networking && terraform output -raw location)
VM_NAME=$(cd ../compute && terraform output -raw vm_name)

terraform init
terraform apply \
  -var="resource_group_name=$RG" \
  -var="location=$LOCATION" \
  -var="vm_name=$VM_NAME"
```

Use this to change the start/stop times without touching the VM itself.

> **Schedules** (`timezone = America/New_York` — handles EST ↔ EDT automatically):
> - **Start** — 11:00 AM Eastern, every day
> - **Stop**  — 11:59 PM Eastern, every day

---

## Tear-down order

Destroy in **reverse** order so dependencies are respected:

```bash
# 1. Remove schedules first
cd compute_controls && terraform destroy

# 2. Remove the VM
cd ../compute && terraform destroy

# 3. Remove networking + resource group last
cd ../networking && terraform destroy
```

---

## GitHub Actions runner

The `compute/` cloud-init installs a self-hosted runner on first boot.

| Item | Value |
|---|---|
| Runner name | `admin-dashboard-vm` |
| Labels | `admin-dashboard`, `linux`, `docker` |
| Runs as | `github-runner` system user |
| Service | `systemctl status "actions.runner.*"` |
| Env file | `/etc/github-runner.env` |

Environment variables available to every workflow step and shell script:

```bash
GITHUB_REPO_URL=https://github.com/org/repo.git
GITHUB_BRANCH=main
GITHUB_TOKEN=ghp_...
```

Reference in a workflow:

```yaml
jobs:
  deploy:
    runs-on: [self-hosted, admin-dashboard]
    steps:
      - run: docker compose up -d
```

---

## Outputs reference

### networking/

| Output | Description | Used by |
|---|---|---|
| `resource_group_name` | RG name | compute, compute_controls |
| `location` | Azure region | compute, compute_controls |
| `subnet_id` | Subnet ID | compute |
| `nsg_id` | NSG ID | compute |
| `vnet_id` | VNet ID | — |
| `vnet_name` | VNet name | — |

### compute/

| Output | Description | Used by |
|---|---|---|
| `vm_name` | Full VM name | compute_controls |
| `vm_public_ip` | Static public IP | — |
| `vm_public_fqdn` | DNS FQDN | — |
| `ssh_command` | Ready-to-paste SSH command | — |
| `http_url` | `http://<ip>` | — |

### compute_controls/

| Output | Description |
|---|---|
| `automation_account_name` | Automation account name |
| `start_schedule_name` | Daily 11:00 AM ET schedule |
| `stop_schedule_name` | Daily 11:59 PM ET schedule |
