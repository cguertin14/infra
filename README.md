# infra

My infrastructure running on a hybrid arm64/amd64 Kubernetes Cluster.

## Architecture

Multiple Storage Classes exist:
1. `ceph-block` -> for all the k8s data (RWO);
2. `ceph-bucket` -> for S3-like volumes (RWO);
3. `ceph-filesystem` -> for `RWX` k8s volumes;
4. `nfs-media-client` -> for all the media data.

![](https://img.plantuml.biz/plantuml/png/VPHTJy8m58QlrrznmlqGziKqne0Oer49KIwzAMkLnQtLhWKJut-t-u8LwMwMlSzxjlFHxKmBYOLKUGOfUnCOi4WsgQI9L88Yb6HS4RXdaWf6PQiVPmluGGvo62SKdlGbR-wVkTAXZNZac5pZ3BEaH8Na0hzJMCnU3c9EFpS8EVLhaqmL-cd01GmUrBfAIGkODnXU6G2CpxtXE8g7e-7ep0i6gCarvqmAdYrrDbhMLjESaXGNL6nr0VfPg2dRfgTmdh8qbTyZ_Kg7O8dNEWIeJ0XoVjiqDveVvTXnyK75s9IUANrJ1gOCJHcPScBAkAccqmEuohrgAkrqRE2cjmuhfruFrYMQTGU876ESjL-Ub7FeluBbMPevBok-dudDykoMRxS2knNQhSXkJUnMN7tVtIaVjMRrl1xFx_627Y_iyQ8URzBZnQZpNHoVsodkMRXluO65XnOUMVZ4mdK3-bTebnEuGZlLCe8Bk5kjbY3ebwA5H3Mi_7f1wO1RBdPOa7rCOrH1tSLr8jImgthQF-b_B9fIHlHs_GC0)

## Backups

Backups are created on S3 periodically for both etcd (k8s resources) and persistent volumes (PVCs and PVs).
There is a runbook available [here](./services/velero-backups/README.md) for information on how to restore backups.

## Structure of this repository

The [services/](./services) folder contains subfolders which contain different kinds of web/networking/other services.

## Dependencies

* [Docker](https://docker.io)
* [Terraform](https://terraform.io)
* [Ansible](https://www.ansible.com/)
* [Kubectl](https://kubernetes.io)
* [Kustomize](https://kustomize.io)
* [Kind](https://kind.sigs.k8s.io/)
* [SOPS](https://github.com/mozilla/sops)
* [Kustomize-Sops](https://github.com/viaduct-ai/kustomize-sops)
