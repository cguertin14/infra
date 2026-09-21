# Dead OSD Replacement Guide

This is the manual replacement procedure used for the host-based OSDs in this
cluster. Replace the placeholders before running commands. Do not work on two
OSDs at the same time unless the cluster has enough capacity and redundancy.

## 1. Identify the OSD and disk

From the Ceph toolbox, identify the OSD, host, and current state:

```bash
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph -s
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd tree
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd metadata <OSD_ID>
```

On the affected host, confirm the physical disk using its model and serial.
Do not rely only on `/dev/sdX`, since device names can change:

```bash
lsblk -d -o NAME,PATH,MODEL,SERIAL,SIZE,TYPE
ls -l /dev/disk/by-id/
```

Write down the physical HDD/SSD serial number (`S/N`). Use it to identify the
correct drive during the shutdown and physical replacement steps.

## 2. Evacuate the OSD

Mark the OSD out and wait for Ceph to move its data:

```bash
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd out <OSD_ID>
watch -n 10 'kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph -s'
```

Continue only when recovery is complete: all PGs are `active+clean` and there
are no misplaced objects, degraded PGs, or backfill operations.

## 3. Replace the physical disk

After confirming the OSD is out and recovery is complete:

1. Drain the affected host, i.e.:
```bash
kubectl drain nvidiaserver --ignore-daemonsets --delete-emptydir-data
```
2. Shut down the affected host.
3. Replace the failed disk.
4. Boot the host and confirm the replacement disk:

```bash
lsblk -o NAME,PATH,MODEL,SERIAL,SIZE,TYPE,FSTYPE,MOUNTPOINTS
```

## 4. Remove the old OSD

Purge the old OSD from Ceph, then remove any stale Kubernetes deployment:

```bash
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  ceph osd purge <OSD_ID> --yes-i-really-mean-it

kubectl delete deployment -n rook-ceph rook-ceph-osd-<OSD_ID>
```

The deployment command may return `NotFound`; that is fine. Verify that no old
workload remains:

```bash
kubectl -n rook-ceph get deployments,pods -o wide | grep -E 'osd|prepare'
```

## 5. Clear disk signatures (optional, recommended)

Do this when it is unclear whether the replacement disk is empty or when it
was previously used by Ceph or another system. First identify the disk and
inspect it read-only:

```bash
lsblk -o NAME,PATH,MODEL,SERIAL,SIZE,TYPE,FSTYPE,MOUNTPOINTS /dev/<device>
sudo wipefs -n /dev/<device>
```

After verifying the model, serial, and device path, and confirming that the
disk contains no data to preserve:

```bash
sudo wipefs -a /dev/<device>
sudo wipefs -n /dev/<device>
```

`wipefs -a` is destructive. Never run it against the boot disk or an active
OSD. Do not format the disk manually; Rook will prepare it.

## 6. Re-run OSD discovery

Rook creates the prepare Job. Inspect the existing Job and its logs:

```bash
kubectl -n rook-ceph get jobs,pods -o wide | grep -E 'prepare|osd'
kubectl -n rook-ceph logs job/rook-ceph-osd-prepare-<node>
```

If the Job is stale or skipped the replacement disk, delete it so Rook can
recreate it:

```bash
kubectl -n rook-ceph delete job rook-ceph-osd-prepare-<node>
```

Delete the Rook operator pod to trigger a fresh reconciliation. Kubernetes will
recreate the operator pod and Rook will recreate the prepare Job:

```bash
kubectl -n rook-ceph delete pod -l app=rook-ceph-operator
kubectl -n rook-ceph get jobs,pods -o wide -w
```

## 7. Verify the replacement

Find the new OSD and confirm that it is on the expected host and replacement
disk:

```bash
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd tree
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd metadata <NEW_OSD_ID>
```

The replacement may receive a new OSD ID, especially after purging the old
OSD or when the replacement disk has a different capacity.

Monitor recovery until the cluster is healthy again:

```bash
watch -n 10 'kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph -s'
```

The final state should be `HEALTH_OK`, all OSDs `up` and `in`, all PGs
`active+clean`, and zero misplaced or degraded objects.

When an OSD is constantly flipping between up and down (daily) on Prometheus, that means it's time to replace it.
