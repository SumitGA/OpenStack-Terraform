# OpenStack Tenant — Infrastructure as Code

This Terraform configuration recreates, as code, the full tenant that was
originally built by hand: a private network, router, security group, SSH
keypair, a VM, and a floating IP with SSH access.

Everything is named `tf-*` so it lives **alongside** any manually-created
resources without conflicting. The tenant network uses `10.10.0.0/24` (distinct
from a hand-built `10.0.0.0/24`).

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Provider config + all resources |
| `variables.tf` | Configurable inputs (with defaults) |
| `outputs.tf` | Values printed after apply (floating IP, SSH command) |
| `terraform.tfvars` | *(optional, git-ignored)* override any variable here |
| `clouds.yaml` | *(git-ignored)* OpenStack credentials |

## What it builds

```
external-net (existing, referenced)
      │
   tf-router  ──┐
      │         │  SNAT + floating IPs
   tf-net (10.10.0.0/24)
      │
   tf-vm  ── tf-vm-access (SSH+ICMP) ── tf-key ── floating IP
```

## Prerequisites

- Terraform installed
- `clouds.yaml` present (copy from `/etc/kolla/clouds.yaml`), with `auth_url`
  pointing at the internal VIP
- A **cloud image** registered in Glance (e.g. `ubuntu-24.04`) — NOT an
  installer ISO
- Your SSH public key at the path in `var.public_key_path`

## Usage

```bash
terraform init      # one-time: download the provider
terraform plan      # dry run — shows what WOULD happen, changes nothing
terraform apply     # creates everything (asks for confirmation)
terraform destroy   # removes ONLY what this config created
```

After `apply`, the floating IP and SSH command are printed:

```
ssh_command = "ssh ubuntu@192.168.0.xxx"
```

## Safety notes

- `plan` never changes anything — use it freely.
- `apply` and `destroy` only ever affect resources in this config's state.
- Never commit `terraform.tfstate`, `*.tfvars`, or `clouds.yaml` — they hold
  secrets. The `.gitignore` handles this.

