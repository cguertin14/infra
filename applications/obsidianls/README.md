# obsidianls

Obsidian LiveSync backend (Apache CouchDB) for syncing personal notes across
devices. Deployed via the official `couchdb` Helm chart, exposed through
Envoy Gateway at `https://obsidianls.cguertin.dev`.

## Initial bootstrap

With `clusterSize: 1`, the CouchDB chart **skips its built-in cluster setup
job**, which means the system databases (`_users`, `_replicator`,
`_global_changes`) are not created automatically. Until they exist, CouchDB
logs continuous `database_does_not_exist` errors and rejects writes that
depend on the auth cache.

After ArgoCD has synced the application and the StatefulSet is `Ready`, run
the LiveSync init script **once** against the public endpoint to:

1. Create the system databases via `_cluster_setup` (`enable_single_node`)
2. Apply LiveSync's recommended CouchDB ini settings (already mirrored in
   `kustomization.yaml`, but the script enforces them at runtime too)

```sh
# 1. Pull admin credentials (generated at deploy time, SOPS-encrypted in
#    secrets/admin.yml).
export username=$(kubectl get secret -n obsidianls obsidianls-couchdb \
  -o jsonpath='{.data.adminUsername}' | base64 -d)
export password=$(kubectl get secret -n obsidianls obsidianls-couchdb \
  -o jsonpath='{.data.adminPassword}' | base64 -d)
export hostname=https://obsidianls.cguertin.dev

# 2. Run the official LiveSync init script.
curl -fsSL https://raw.githubusercontent.com/vrtmrz/obsidian-livesync/main/utils/couchdb/couchdb-init.sh | bash
```

The script is idempotent — re-running it is safe and only re-applies settings.

### Verifying

```sh
# System DBs should now exist.
curl -s -u $username:$password $hostname/_all_dbs | jq

# Health endpoint should be 200.
curl -s -u $username:$password $hostname/_up
```

## Setting up a client (Obsidian LiveSync plugin)

Generate a setup URI to share between devices (vault name + E2EE passphrase
are baked in, so all clients end up identically configured):

```sh
deno run -A \
  https://raw.githubusercontent.com/vrtmrz/obsidian-livesync/main/utils/flyio/generate_setupuri.ts
```

When prompted, supply:

- `hostname`: `https://obsidianls.cguertin.dev`
- `database`: `obsidiannotes` (created on first client connection)
- `username` / `password`: from the admin secret (see bootstrap section)
- `passphrase`: a strong E2EE passphrase (store in your password manager —
  losing it means losing the ability to decrypt notes)

Open the resulting `obsidian://` URI on each device with the LiveSync plugin
installed.

## Files

- `kustomization.yaml` — Helm chart values (CouchDB config, persistence,
  resources, single-node setup)
- `resources/httproute.yml` — public HTTPS route + DirectResponse 404 for
  `/_utils` (Fauxton blocked at the gateway)
- `resources/rate-limit.yml` — BackendTrafficPolicy rate-limiting `/_session`
- `secrets/admin.yml` — SOPS-encrypted Secret with admin credentials
- `secrets-generator.yml` — KSOPS generator hook
