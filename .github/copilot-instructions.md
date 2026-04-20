# Copilot Instructions for viya4-deployment

## Project Overview
This is an **Ansible-based deployment tool** for SAS Viya 4 platform on Kubernetes (AWS/Azure/GCP). It prepares clusters (ingress, cert-manager, storage classes, NFS), generates kustomize manifests, and deploys SAS Viya into namespaces. It is NOT for version upgrades—only patch updates using the same manifest.

## Architecture
- **Entry point**: `playbooks/playbook.yaml` — single playbook, runs on `localhost`, orchestrates all roles via Ansible tags
- **Roles** (executed in order): `common` → `jump-server` → `baseline` → `multi-tenancy` → `vdm`
  - `common` — loads config (`CONFIG` var), parses Terraform state (`TFSTATE`), sets cloud-specific facts, validates inputs
  - `baseline` — deploys cluster infrastructure (ingress-nginx, cert-manager, NFS CSI, metrics-server, EBS CSI)
  - `vdm` — core SAS Viya deployment: orders CLI, kustomize manifest generation, CAS configuration, storage mounts
  - `jump-server` — configures NFS directories on bastion host
  - `multi-tenancy` — tenant onboarding/offboarding, CAS per-tenant customization
- **Tag system** controls execution: `install`, `uninstall`, `update`, `baseline`, `viya`, `multi-tenancy`, `onboard`, `offboard`
- **Custom lookup plugin**: `roles/common/lookup_plugins/tfstate.py` parses Terraform state files from viya4-iac-* projects

## Key Conventions
- All configuration variables use `V4_CFG_` or `V4MT_` prefixes (see `docs/CONFIG-VARS.md` for full reference)
- Role defaults live in `roles/<role>/defaults/main.y(a)ml`; always define new variables there with sensible defaults
- Cloud provider is set via `PROVIDER: [azure|aws|gcp|custom]` — many conditionals branch on this value
- Jinja2 templates in `roles/vdm/templates/` generate kustomize overlays; files in `roles/vdm/files/` are static resources
- Task files use `# noqa: name[casing]` comments to suppress ansible-lint warnings on role names
- Copyright header required: `# Copyright © 2020-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.` + `# SPDX-License-Identifier: Apache-2.0`

## Running the Playbook
```bash
# Docker (preferred):
docker run --rm -v <config-dir>:/data viya4-deployment --tags "baseline,viya,install"

# Direct Ansible:
ansible-playbook playbooks/playbook.yaml -e CONFIG=/path/to/ansible-vars.yaml --tags "baseline,install"
```
Tags are comma-separated and combined: e.g., `--tags "baseline,install"` runs baseline install tasks only.

## Dependencies
- Python deps: `requirements.txt` (ansible, kubernetes, openshift, docker, dnspython)
- Ansible collections: `requirements.yaml` (ansible.utils, community.docker, kubernetes.core)
- Container tools: kubectl, helm, skopeo, cloud CLIs (aws/az/gcloud) — see `Dockerfile`
- `ansible.cfg` sets `hash_behaviour=merge` — variable dicts are **merged**, not replaced

## File Patterns
- `examples/ansible-vars.yaml` — template for user config; `examples/ansible-vars-iac.yaml` for Terraform integration
- `examples/sitedefault.yaml` — CAS/Consul configuration template
- Task files: YAML in `roles/<role>/tasks/`, included conditionally from main playbook
- Templates use Jinja2 (`.yaml` extension, inside `templates/` dirs)

## When Modifying Code
- New config variables: add to role `defaults/main.y(a)ml` AND document in `docs/CONFIG-VARS.md`
- Respect the tag system — every task block needs appropriate tags for selective execution
- Test with multiple `PROVIDER` values; cloud-specific logic uses `when:` conditionals on provider/tfstate
- The `common` role's `task-validations.yaml` runs with `tags: always` — validation logic goes there
