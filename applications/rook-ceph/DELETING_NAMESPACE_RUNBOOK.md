# Rook Namespace Deletion and Recovery Runbook

Use this runbook when the `rook-ceph` namespace has been deleted and needs to
be restored, or when its restoration leaves the Ceph RGW gateway unavailable.
It covers checking the Velero restore, validating RGW metadata, and recovering
the object store without discarding bucket data. It assumes the Ceph data on the
hosts and in the pools still exists and that a usable pre-deletion Velero backup
is available. This is not a guide for rebuilding a lost Ceph cluster, replacing
destroyed OSD data, or recovering from a missing/corrupt backup; stop and use a
full disaster-recovery procedure for those cases.

The main safety rule is to preserve Ceph pools and bucket data. A namespace
deletion or Kubernetes restore does not mean the RGW data pools should be
deleted or recreated. This runbook covers a lost Kubernetes namespace while
the Ceph data and monitor stores are intact; it does not cover lost disks,
destroyed pools, loss of monitor quorum with no usable backup, or a lost Ceph
FSID/admin identity.

## 1. Restore the namespace with Velero

Find the newest successful `etcd-backups` backup taken before the namespace was
deleted. Do not use a backup created after deletion. Restore only the
`rook-ceph` namespace resources; do not restore all namespaces or PV/PVC
objects as part of this step. This assumes the cluster-scoped Rook CRDs and
operator installation still exist. If they are missing, stop and use the
cluster-wide disaster-recovery procedure. Do not create a new empty namespace
and apply partial resources over it as a substitute for restoring the backup.

Confirm that the restore succeeded and included the namespace and required
resources:

```bash
kubectl -n velero get backups.velero.io
kubectl -n velero get restores.velero.io
velero backup describe <ETCD_BACKUP_NAME> --details --namespace velero
```

The repository's Velero schedule `etcd-backups` runs daily and retains backups
for 14 days. It includes Kubernetes resources across namespaces but excludes
PVs/PVCs. A namespace-only recovery normally needs that etcd/resource backup;
do not restore the persistent-volume backups into an intact Ceph cluster. The
repository's general Velero procedure is in `applications/velero/README.md`.
Use a unique restore name and the actual pre-deletion backup name:

```bash
velero restore create rook-ceph-recovery \
  --from-backup <ETCD_BACKUP_NAME> \
  --include-namespaces rook-ceph \
  --exclude-resources persistentvolumes,persistentvolumeclaims \
  --include-cluster-resources=false \
  --namespace velero --wait
velero restore describe rook-ceph-recovery --namespace velero
velero restore logs rook-ceph-recovery --namespace velero
kubectl -n rook-ceph get pods
kubectl -n rook-ceph get cephcluster,cephobjectstore
```

Use the actual backup name and a unique restore name. Continue only after the
restore has completed and its errors/warnings have been reviewed. If only part
of the namespace was lost, use a narrowly scoped restore rather than restoring
every resource over the working cluster.

If the namespace is still absent afterward, or the restore skipped the
namespace resources, stop and review the Velero restore logs and backup
contents. Confirm the Rook CRDs exist before proceeding; restore the Rook
application from GitOps if its operator or CRDs were also lost. Do not proceed
to mutate Ceph while the Rook API types are unavailable.

Velero restores Kubernetes objects. RGW realm, zonegroup, zone, and period
metadata are stored in Ceph pools and may need separate validation. Do not
repeatedly restore the namespace to fix an RGW metadata mismatch.

## 2. Restore Rook's connection and authentication resources

If MON/OSD pods fail to start, the toolbox cannot connect, or Rook reports
authentication or monitor-connection errors, check that the backup has the
Rook connection ConfigMap and required Ceph Secrets. The Rook operator can
recreate some daemon Secrets, but it cannot safely recreate the cluster's
original admin identity from scratch. Inspect only names, timestamps, and key
names; never print secret values:

```bash
kubectl -n rook-ceph get configmap rook-ceph-mon-endpoints rook-ceph-config
kubectl -n rook-ceph get secrets
kubectl -n rook-ceph get secret rook-ceph-mon -o json | \
  jq -r '{created:.metadata.creationTimestamp, dataKeys:((.data // {}) | keys)}'
kubectl -n rook-ceph get configmap rook-ceph-mon-endpoints -o json | \
  jq -r '.data | {keys:keys, monitors:.data, maxMonId, mapping}'
```

If the original `rook-ceph-mon` Secret, required daemon/admin Secrets, or
`rook-ceph-mon-endpoints`/`rook-ceph-config` ConfigMaps are missing, recreated,
or inconsistent with the trusted backup, restore the originals from that same
backup. Pause the Rook operator first so reconciliation cannot overwrite
recovery state while the restore runs. This replaces credentials and
connection settings; confirm the restore includes the named objects and review
its phase, errors, warnings, progress, and logs before restarting Rook:

```bash
kubectl -n rook-ceph scale deployment rook-ceph-operator --replicas=0
kubectl -n rook-ceph rollout status deployment/rook-ceph-operator --timeout=120s
velero restore create rook-ceph-core-resources-recovery \
  --from-backup <ETCD_BACKUP_NAME> \
  --include-namespaces rook-ceph \
  --include-resources configmaps,secrets \
  --exclude-resources persistentvolumes,persistentvolumeclaims \
  --existing-resource-policy update \
  --include-cluster-resources=false \
  --namespace velero --wait
velero restore describe rook-ceph-core-resources-recovery --namespace velero
velero restore logs rook-ceph-core-resources-recovery --namespace velero
```

Use a backup verified to contain the required resources. Before proceeding,
confirm the restore succeeded and the expected ConfigMaps/Secrets exist. Inspect
only the ConfigMap monitor IDs/endpoints and Secret data key names; do not
display, decode, or copy secret values. Then restart the operator:

```bash
kubectl -n rook-ceph scale deployment rook-ceph-operator --replicas=1
kubectl -n rook-ceph rollout status deployment/rook-ceph-operator --timeout=120s
```

If the monitor endpoint ConfigMap is absent or lists the wrong monitors, stop
and recover it from the saved backup/configuration. Do not guess monitor
addresses, IDs, or mapping data. If the backup does not contain valid
`rook-ceph-mon` credentials or the monitor endpoint data cannot be established,
stop and escalate rather than creating new Ceph credentials or initializing a
new cluster.

If the operator was intentionally scaled to zero, always restore it to its
original replica count after the recovery step. Confirm it is ready before
continuing. Do not leave it stopped between steps unless a later step explicitly
requires that.

The `rook-ceph-mon` Secret carries the cluster FSID and admin identity used by
Rook to connect to Ceph; it is different from daemon keyring Secrets. If that
Secret is missing or untrusted and cannot be restored, do not reconstruct it
from guesses or paste key material into commands/logs. Stop and follow an
approved Ceph credential recovery procedure. This namespace runbook assumes the
Ceph data and monitor stores remain intact.

If no backup contains a usable `rook-ceph-mon` Secret but the original monitor
host data is intact, an authorized Ceph administrator may be able to recover
the same FSID and admin key from that host's Rook data directory, normally
`/var/lib/rook/rook-ceph/rook-ceph.config` and
`/var/lib/rook/rook-ceph/client.admin.keyring`. Treat the key as a secret:
retrieve it only through an approved secure process and update the Secret's
required fields (`fsid`, `ceph-username`, `ceph-secret`, `mon-secret`) without
printing the value or putting it in shell history or command arguments. Verify
the FSID is the surviving cluster's FSID and inspect only the Secret's key
names after repair. If the host data, access, FSID, or admin key cannot be
verified, stop and escalate; do not generate a new cluster identity or key.

## 3. Restore Ceph's internal authentication if daemons cannot connect

Before diagnosing RGW, check that Ceph itself is reachable and its daemons can
authenticate:

```bash
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph -s
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph health detail
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph quorum_status
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd tree
kubectl -n rook-ceph get cephcluster rook-ceph -o yaml
kubectl -n rook-ceph logs deploy/rook-ceph-operator --since=10m
```

Do not proceed with RGW metadata changes until monitor quorum is present and
the expected OSDs are present and `up`/`in`. If Ceph is unavailable, the FSID
does not match the surviving cluster, or OSD/pool data is missing, stop and
use Ceph cluster disaster recovery instead.

Ceph's internal authentication lets monitors, managers, OSDs, and clients
prove their identity when connecting to one another. This repository currently
requires the newer `aes256k` key type in
`applications/rook-ceph/kustomization.yaml`. If restored monitor or OSD keys
still use the older `aes` type, those daemons cannot authenticate: Ceph may
report `RADOS permission denied`, and Rook may be unable to reconcile the
cluster. Use this workaround only when the observed error matches this mismatch.

Temporarily change the Git-managed CephCluster configuration to allow both key
types and explicitly set the daemon key type to `aes`:

```yaml
security:
  cephx:
    allowedCiphers:
      - aes
      - aes256k
    daemon:
      keyType: aes
```

Reconcile that temporary configuration through the repository's GitOps
workflow. If GitOps cannot apply it because Rook cannot authenticate to Ceph,
ask for authorization before applying the same temporary fields directly to
`CephCluster/rook-ceph`. Do not allow Argo CD to overwrite temporary recovery
settings before the daemons recover; keep the temporary config in Git until the
recovery steps below are complete.

For a direct emergency patch only when GitOps cannot reconcile and after
explicit authorization, the equivalent command is:

```bash
kubectl -n rook-ceph patch cephcluster rook-ceph --type=merge \
  -p '{"spec":{"security":{"cephx":{"allowedCiphers":["aes","aes256k"],"daemon":{"keyType":"aes"}}}}}'
```

Keep a record of the original spec so the temporary setting can be removed.
Prefer committing the temporary state to Git and reconciling it; otherwise,
Argo CD may revert the emergency patch before recovery is complete.

Confirm that all monitor pods now include Rook's emergency authentication
argument and that Rook can continue reconciliation:

```bash
kubectl -n rook-ceph get pods -l app=rook-ceph-mon -o json | jq -r '
  .items[] | [.metadata.name,
    ([.spec.containers[].args[]? | select(contains("--mon-auth-emergency-allowed-ciphers"))] | join(" ")),
    ([.status.containerStatuses[]? | select(.name == "mon") | .ready] | first // false)] | @tsv'
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph -s
kubectl -n rook-ceph logs deploy/rook-ceph-operator --since=10m
```

Once all monitor pods show the emergency argument and Rook reconciliation is
progressing, edit `applications/rook-ceph/kustomization.yaml` through Git to
remove only the temporary `daemon.keyType: aes` override. Keep
both `aes` and `aes256k` allowed; Rook's v1.20.7 recovery guidance recommends
leaving this compatibility setting in place after the workaround. Confirm
monitors, managers, and OSDs are up and the monitors have quorum. Do not
restrict `allowedCiphers` to `aes256k` unless a separately planned key
migration has verified all affected daemon and client keys support it. See
[Rook v1.20.7's key rotation guide](https://raw.githubusercontent.com/rook/rook/v1.20.7/Documentation/Storage-Configuration/Advanced/cephx-key-rotation.md)
before planning that migration.

After the metadata and gateway recovery, verify Ceph is healthy, all OSDs are
`up`/`in`, monitors have quorum, and Rook no longer needs the temporary daemon
key-type override.

Treat any output from Ceph auth-key inspection as secret material. Do not paste
key dumps into tickets, chat, or this runbook.

## 4. Stabilize and inspect RGW

Use the Rook toolbox for read-only inspection:

```bash
kubectl -n rook-ceph get pods -o wide
kubectl -n rook-ceph get cephobjectstore ceph-objectstore -o yaml
kubectl -n rook-ceph logs deploy/rook-ceph-operator --since=30m --all-containers=true
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph -s
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- radosgw-admin realm list
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- radosgw-admin realm get --rgw-realm=ceph-objectstore
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- radosgw-admin period get-current --rgw-realm=ceph-objectstore
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- radosgw-admin period get --staging --rgw-realm=ceph-objectstore
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- radosgw-admin zonegroup list
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- radosgw-admin zone list
```

Before changing metadata, record the full realm, current period, and staging
period output somewhere secure and durable. These contain the IDs and settings
needed to restore the metadata accurately. Do not print or copy Kubernetes
Secrets, keys, or keyrings into the runbook.

If zonegroup or zone metadata still loads, save its JSON in a restricted,
temporary location before editing it. Zone JSON can contain a system key, so
protect it like a credential and never paste it into logs, tickets, or chat:

```bash
umask 077
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin zonegroup get --rgw-realm=ceph-objectstore \
  --rgw-zonegroup=ceph-objectstore --format=json > /secure/path/zonegroup.json
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin zone get --rgw-realm=ceph-objectstore \
  --rgw-zonegroup=ceph-objectstore --rgw-zone=ceph-objectstore \
  --format=json > /secure/path/zone.json
```

If a `get` command fails because the metadata is missing, save the current and
staging period JSON instead; do not treat a failed lookup as empty or replace
the file with guessed values.

The backup of Kubernetes resources does not itself provide a copy of the RGW
zone configuration held in Ceph. If zone metadata can be read, save the full
zone JSON as well as the period. If it cannot be read, use the saved period and
the CephObjectStore configuration as references; if these do not establish an
exact pool layout, stop rather than guessing.

Check the zonegroup and zone directly as well as their lists; a name can appear
in a list even when the metadata record needed to load it is missing:

```bash
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin zonegroup get --rgw-realm=ceph-objectstore --rgw-zonegroup=ceph-objectstore
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin zone get --rgw-realm=ceph-objectstore \
  --rgw-zonegroup=ceph-objectstore --rgw-zone=ceph-objectstore
```

Do not delete the `CephObjectStore`, realm, pools, or `.rgw.root` objects as a
shortcut. The current period provides the authoritative zone IDs and pool
layout.

## 5. Restore missing zonegroup and zone metadata

The repair must use the IDs and settings from the saved current period. Do not
invent replacement IDs or copy settings from the default zone: the default
zone is a separate configuration. Preserve the realm and zonegroup IDs, master
zonegroup and zone IDs, endpoint, placement target, enabled features, and the
zone's configured pool names.

Restore the zonegroup record with `radosgw-admin zonegroup set`, using the
saved period's zonegroup JSON as input. Preserve the realm ID, zonegroup ID,
master settings, endpoint, placement target, and feature settings. For example,
extract it from the current period to a protected temporary file:

```bash
umask 077
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin period get --period=<CURRENT_PERIOD_ID> --format=json | \
  jq '.period_map.zonegroups[] | select(.name == "ceph-objectstore")' \
  > /secure/path/ceph-objectstore-zonegroup.json
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin zonegroup set --rgw-realm=ceph-objectstore \
  --rgw-zonegroup=ceph-objectstore \
  --infile=/secure/path/ceph-objectstore-zonegroup.json
```

The current period does not contain the zone's internal pool configuration.
If the zone metadata still loads, save the zone JSON to a protected file before
editing it. If the zone is missing, recover the previous zone JSON from a
Ceph metadata backup. Only reconstruct it from the `CephObjectStore` pool
specs and known zone pool names if those are exact; otherwise stop rather than
guessing. When the saved zone JSON is available, restore it with `zone set`:

```bash
umask 077
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin zone get --rgw-realm=ceph-objectstore \
  --rgw-zonegroup=ceph-objectstore --rgw-zone=ceph-objectstore \
  --format=json > /secure/path/ceph-objectstore-zone.json
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin zone set --rgw-realm=ceph-objectstore \
  --rgw-zone=ceph-objectstore --infile=/secure/path/ceph-objectstore-zone.json
```

Do not run `zone create` with a fresh ID when the saved period contains the
original zone ID. The Rook reconciler may first create a fresh ID; in that case
correct it with the saved zone JSON before attempting the period commit.

If Rook creates the zone with a new ID, do not commit that staging period
blindly. The existing current period may reject a master zone ID that it does
not contain. Restore the zone's original ID and pool paths from the saved
period and zone configuration first. Use the exact pool names from the saved
zone configuration, and do not change bucket placement as part of a metadata
repair.

The current period contains the zone's public identity and endpoint, but not
its internal pool configuration. If `radosgw-admin zone get` fails and no saved
zone JSON is available, do not guess those fields. Recover the zone JSON from
an available Ceph metadata backup, or reconstruct it only when the
CephObjectStore pool specs and previous configuration establish the exact
pool names. For this cluster's default, non-shared-pool configuration, the
zone pool paths were:

```text
domain_root       ceph-objectstore.rgw.meta:root
control_pool      ceph-objectstore.rgw.control
dedup_pool        ceph-objectstore.rgw.dedup
gc_pool           ceph-objectstore.rgw.log:gc
lc_pool           ceph-objectstore.rgw.log:lc
log_pool          ceph-objectstore.rgw.log
intent_log_pool   ceph-objectstore.rgw.log:intent
usage_log_pool    ceph-objectstore.rgw.log:usage
roles_pool        ceph-objectstore.rgw.meta:roles
reshard_pool      ceph-objectstore.rgw.log:reshard
user_keys_pool    ceph-objectstore.rgw.meta:users.keys
user_email_pool   ceph-objectstore.rgw.meta:users.email
user_swift_pool   ceph-objectstore.rgw.meta:users.swift
user_uid_pool     ceph-objectstore.rgw.meta:users.uid
otp_pool          ceph-objectstore.rgw.otp
notif_pool        ceph-objectstore.rgw.log:notif
topics_pool       ceph-objectstore.rgw.meta:topics
account_pool      ceph-objectstore.rgw.meta:account
group_pool        ceph-objectstore.rgw.meta:group
bucket_logging_pool ceph-objectstore.rgw.log:bucket-logging
restore_pool     ceph-objectstore.rgw.log:restore
placement index  ceph-objectstore.rgw.buckets.index
placement data   ceph-objectstore.rgw.buckets.data
placement extra  ceph-objectstore.rgw.buckets.non-ec
```

These names are specific to this store's configuration, not a universal
template. The zone also needs the saved realm ID, zone ID, and zone name. If
any pool name, shared-pool setting, placement, or previous customization is
uncertain, stop and recover the original zone configuration rather than
creating the zone from this list.

Set the restored zonegroup and zone as the realm defaults if required by
`radosgw-admin period commit` for that Ceph version:

```bash
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin zonegroup default --rgw-realm=ceph-objectstore \
  --rgw-zonegroup=ceph-objectstore
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin zone default --rgw-realm=ceph-objectstore \
  --rgw-zone=ceph-objectstore
```

Then commit the staging period with the zonegroup and zone explicitly selected:

```bash
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin period update --commit --rgw-realm=ceph-objectstore \
  --rgw-zonegroup=ceph-objectstore --rgw-zone=ceph-objectstore
```

If commit reports that the staging epoch does not match the predecessor, stop
and inspect both the current and staging periods. Do not use a force-promotion
flag to bypass the check. Reconcile the intended IDs and configuration, then
retry the ordinary commit.

Verify the realm points at the committed period and that the zone and
zonegroup load successfully:

```bash
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin realm get --rgw-realm=ceph-objectstore
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin zonegroup get --rgw-realm=ceph-objectstore \
  --rgw-zonegroup=ceph-objectstore
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin zone get --rgw-realm=ceph-objectstore \
  --rgw-zonegroup=ceph-objectstore --rgw-zone=ceph-objectstore
```

The operator may time out while committing a period, even if it has correctly
repaired the zone metadata. Inspect the current/staging periods before retrying
the normal commit manually. Confirm the metadata repair has not changed bucket
placement or deleted bucket data.

## 6. Check for extra pools created during restoration

An unsuccessful zone recreation can create extra pools before the metadata
repair is complete. Once the zone is healthy, compare the active zone's pool
configuration with the Ceph pool inventory:

```bash
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin zone get --rgw-realm=ceph-objectstore \
  --rgw-zonegroup=ceph-objectstore --rgw-zone=ceph-objectstore
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd pool ls detail
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph df detail
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd pool autoscale-status
```

For any suspected orphan, verify all of the following before considering
removal:

1. The pool is not referenced by the active zone or any other live RGW zone.
2. The pool is not one of the cluster's normal pools or another service's pool.
3. `ceph df detail` reports zero objects and zero stored bytes.
4. A read-only `rados -p <pool> ls` confirms there are no objects.
5. The exact pool name has been reviewed and removal is explicitly authorized.

Never remove a pool just because its name looks unusual. Extra RGW pools may
contain log or metadata objects that are still needed.

If the inventory identifies confirmed-empty orphan pools and cleanup is
necessary to restore Ceph health, remove only the specifically reviewed and
approved pools. Replace `<POOL>` with the exact pool name, repeated as shown by
the command's confirmation syntax:

```bash
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  ceph osd pool rm <POOL> <POOL> --yes-i-really-really-mean-it
```

Pool removal is destructive. Get explicit approval before running any pool
removal command, and recheck pool contents immediately beforehand. Do not
remove pools that contain RGW log or metadata objects.

## 7. Verify recovery

Confirm the object store, gateway, period, and cluster are healthy:

```bash
kubectl -n rook-ceph get cephobjectstore ceph-objectstore
kubectl -n rook-ceph get pods -l app=rook-ceph-rgw -o wide
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph -s
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph health detail
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin realm get --rgw-realm=ceph-objectstore
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  radosgw-admin sync status --rgw-realm=ceph-objectstore --rgw-zone=ceph-objectstore
```

Expected recovery state is `CephObjectStore` `Ready` with the configured
replica count, the RGW pod ready, RGW active, all PGs `active+clean`, and Ceph
`HEALTH_OK`.

## Operational notes

- Prefer restoring the namespace and its desired state through GitOps/backup
  recovery. Avoid manually deleting and recreating the Rook namespace as a
  troubleshooting step.
- Read-only inspection commands can be run directly. Ask for explicit approval
  immediately before mutating Ceph/Kubernetes commands, especially pool
  removal, metadata edits, or period commits.
- Do not delete the `CephObjectStore` to fix an RGW metadata problem. Even when
  `preservePoolsOnDelete` is enabled, deleting the resource can disrupt service
  and trigger additional reconciliation.
- Ceph's balancer moves PG placements; it does not repair missing RGW metadata
  or remove orphan pools.
