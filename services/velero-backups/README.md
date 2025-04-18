# Backups

This space defines backups taken by [Velero](https://velero.io).

## Current Schedules

* `etcd` backups: every 72 hours / 3 days.
* `Persistent volumes / Persistent volume claims`: every 24 hours / 1 day.

## Restoring backups

### Install the Velero CLI

Read how [here](https://velero.io/docs/latest/basic-install/).

### Restore etcd resources

1. Find the etcd backup you want to restore on S3/on k8s, note its name. (i.e: `velero-etcd-backups-20250418213241`)
2. Run this command (change the timestamp):
```bash
velero restore create velero-etcd-restore-20250418213241 --from-backup velero-etcd-backups-20250418213241 --namespace velero-backups
```

Your k8s resources (except PVs/PVCs) should now be restored.

### Restore volumes

1. Find the volumes backup you want to restore on S3/on k8s, note its name. (i.e: `velero-volumes-backups-20250418213241`)
2. Run this command (change the timestamp):
```bash
velero restore create velero-volumes-restore-20250418213241 --from-backup velero-volumes-backups-20250418213241 --namespace velero-backups
```

Your PVs/PVCs should now be restored.

### In case of empty k8s cluster

If the cluster has been lost, and it is fully empty:

1. Re-deploy this Kustomize stack in the new cluster;
2. Run a similar command to this:
```bash
velero restore create --from-schedule velero-volumes-backups --allow-partially-failed
velero restore create --from-schedule velero-etcd-backups --allow-partially-failed
```

## Useful links

* [Velero Helm Chart](https://github.com/vmware-tanzu/helm-charts/tree/main/charts/velero)
* [Velero AWS Plugin](https://github.com/vmware-tanzu/velero-plugin-for-aws/blob/main/README.md)