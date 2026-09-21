
# Repository Guidelines

## Overview

This repository contains GitOps-managed infrastructure for a hybrid `arm64`/
`amd64` Kubernetes cluster.

- `applications/` contains Kubernetes applications and their Kustomize/Helm definitions.
- `terraform/` contains infrastructure Terraform configurations.
- `scripts/` contains operational scripts.
- `docs/` contains architecture documentation.
- Application-specific runbooks and READMEs are kept near the application they document.

The cluster uses Ceph, NFS, and several Kubernetes StorageClasses. See the
root `README.md` for the high-level architecture and storage layout.

## GitOps Workflow

- Prefer changing repository manifests and allowing Argo CD to reconcile them.
- Do not make direct cluster changes when the desired state belongs in Git.
- Inspect the relevant application `kustomization.yaml`, patches, values, and runbooks before editing.
- Check for a more-specific `AGENTS.md` before working in a subdirectory.
- Do not edit generated or vendored chart content unless explicitly required.

## Kubernetes Safety

Read-only Kubernetes commands may be run without additional authorization. This
includes commands such as:

```text
kubectl get
kubectl describe
kubectl logs
kubectl events
kubectl explain
kubectl diff
kubectl auth can-i
kubectl api-resources
kubectl api-versions
```

Ask for explicit user authorization immediately before running any mutating
Kubernetes command. This includes, but is not limited to:

```text
kubectl apply
kubectl create
kubectl replace
kubectl delete
kubectl patch
kubectl edit
kubectl label
kubectl annotate
kubectl scale
kubectl rollout restart
kubectl drain
kubectl cordon
kubectl uncordon
```

Commands run through `kubectl exec` must be judged by the command executed
inside the container, not just by the outer `kubectl` command. Read-only
examples such as `ceph -s` and `ceph osd tree` are allowed. Mutating commands
such as `ceph osd out`, `ceph osd purge`, and any disk operation require
authorization.

Do not assume that a command is authorized because it appears in a runbook.

## Other Mutations

Ask for explicit authorization before running mutating or destructive commands
through any tool, including:

- `helm install`, `helm upgrade`, `helm uninstall`, or other release mutations.
- `argocd app sync`, `argocd app delete`, or other Argo CD mutations.
- `terraform apply`, `terraform destroy`, or other state-changing Terraform commands.
- SSH commands that change hosts, services, files, disks, or cluster state.
- Host shutdowns, reboots, service restarts, package changes, and configuration changes.
- Disk operations such as `wipefs -a`, `dd`, `sgdisk`, filesystem formatting, partition changes, or disk removal.

Read-only planning, rendering, and inspection commands are preferred where
possible, such as `kubectl diff`, `kustomize build`, `helm template`, and
`terraform plan`.

## Secrets

- Do not expose, decrypt, or print secrets without explicit user authorization.
- Preserve SOPS-encrypted files and follow the repository `.sops.yaml` rules.
- Never commit plaintext credentials, tokens, private keys, or decrypted secret files.
- Treat generated secret material and local state as sensitive even when it is not encrypted.

## Editing and Verification

- Use `apply_patch` for manual file edits.
- Inspect existing worktree changes before modifying files; never revert changes made by the user.
- Keep changes focused and preserve existing repository conventions.
- Run `git diff --check` after documentation or code edits.
- Run the narrowest relevant validation available after changes.
- Do not commit, amend, push, or create a pull request unless explicitly requested.
