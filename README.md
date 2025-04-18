# infra

[![CircleCI](https://circleci.com/gh/cguertin14/infra.svg?style=shield)](https://circleci.com/gh/cguertin14/infra)

My infrastructure running on a hybrid arm64/amd64 Kubernetes Cluster.

## Architecture

Two Storage Classes exist:
1. `nfs-client` -> for all the k8s data.
2. `nfs-media-client` -> for all the media data.

![](https://uml.planttext.com/plantuml/png/VLHHJy8m47vUVyM5Tn1Q86gC0J568nAYF9gOibPP7Ars7P0O_xlTsZ4wAY_BxhlhzzrzwswKQQfqlauX4U-A0bNnAj4yrhdY2CMfp1ay2CsLuBgAf-CP_A08HK8o3a_ciNRlpp8tfIwOIifkQ4f5N42Pbef-S9YDN-fWmhzM24MMDaxpp9m6ca7hCL-MaZo3YOFXLG10xm9tUiFpJhVJFSFz5d9Q4ocqakdSgF6YDukkQN6ovuVO3ucXY1ZLT4ap3bp734M_5UsjmHkSMwa-3pXjYFsG-67V3mU5GENUxdpuDZClMQ40O1lZB37Dg4tXcyF49Za6rub84hthsexTjD3EszTk43VnCKGEeC9_Qt6R6UpGIXJL3fJ9yklLFTi3zYDMybSbkBSf1ECmJC9mFmmF2W-h0OEYE2oAmw8uB8eRehM3GKqIrYHXJHBM9FyDMZdWtH0_vL-Knh7zVMbE5o349mXnax3PUO2FdE0ZHtpcGbTh1zhAfCer0vTmlrZCGV7ld6SQMR3CszLZ2kwasbB5zZKkKHOThgH0gPSk6wh-ZEDQDEA2cRtv1m00)

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

## Kubeconfig Setup

### NGINX Setup

First off, make sure the port `8000` is not used on your local machine, and then run the following command:
```bash
$ make start-lb
...
```

### Kubeconfig Server Modifications

Second, you're going to want to edit your `~/.kube/config` file like this:
```yaml
...
server: https://127.0.0.1:8000
...
```

And that's it! Your local setup is now fully functional.

## Start a local cluster

```bash
$ make local-cluster
...
```
