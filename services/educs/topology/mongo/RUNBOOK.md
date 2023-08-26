# Salvaging a broken MongoDB Cluster

1. Suspend mongo backups by adding `suspend: true` to the [mongo cronjob](./backups-cron.yml).

2. Start by removing the Mongo Statefulset from ArgoCD from [this file](./kustomization.yaml).

3. Commit this file and re-sync argo in the [UI](https://gitops.k8s.cguertin.dev/applications/argocd/educs-topology?view=tree&conditions=false).

4. Manually delete the Mongo Statefulset: `kubectl rm statefulset -n educs mongo`.

5. Manually delete the Mongo PVCs: 

```
❯ kubectl rm pvc -n educs mongo-persistent-storage-mongo-0
persistentvolumeclaim "mongo-persistent-storage-mongo-0" deleted

❯ kubectl rm pvc -n educs mongo-persistent-storage-mongo-1
persistentvolumeclaim "mongo-persistent-storage-mongo-1" deleted

❯ kubectl rm pvc -n educs mongo-persistent-storage-mongo-2
persistentvolumeclaim "mongo-persistent-storage-mongo-2" deleted
```

6. Redeploy the Mongo StatefulSet.

7. Follow Restore procedure in [kustomization.yaml](./kustomization.yaml) in the env variables section. Commit this modified file.

8. Manually restore the MongoDB Database: `kubectl create job --from=cronjob/mongo-backups -n educs restore-mongo-db`.

9. Delete the restore job: `kubectl rm job -n educs restore-mongo-db`

10. Unsuspend the backup cron and undo the [restore procedure](./kustomization.yaml).