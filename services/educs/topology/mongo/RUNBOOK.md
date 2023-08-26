# Salvaging a broken MongoDB Cluster

1. Suspend mongo backups by adding `suspend: true` to the [mongo cronjob](./backups-cron.yml).

1. Start by removing the Mongo Statefulset from ArgoCD from [this file](./kustomization.yaml).

2. Commit this file and re-sync argo in the [UI](https://gitops.k8s.cguertin.dev/applications/argocd/educs-topology?view=tree&conditions=false).

3. Manually delete the Mongo Statefulset: `kubectl rm statefulset -n educs mongo`.

4. Manually delete the Mongo PVCs: 

```
❯ kubectl rm pvc -n educs mongo-persistent-storage-mongo-0
persistentvolumeclaim "mongo-persistent-storage-mongo-0" deleted

❯ kubectl rm pvc -n educs mongo-persistent-storage-mongo-1
persistentvolumeclaim "mongo-persistent-storage-mongo-1" deleted

❯ kubectl rm pvc -n educs mongo-persistent-storage-mongo-2
persistentvolumeclaim "mongo-persistent-storage-mongo-2" deleted
```

