# infra

[![CircleCI](https://circleci.com/gh/cguertin14/infra.svg?style=shield)](https://circleci.com/gh/cguertin14/infra)

My infrastructure running on a Raspberry Pi Kubernetes Cluster.

## Architecture

Two Storage Classes exist:
1. `nfs-client` -> for all the k8s data.
2. `nfs-media-client` -> for all the media data.

![](https://www.planttext.com/api/plantuml/png/RLDTJy8m57rUVyKDxqFMWb5Z38Wn6f4GvD6NibObRctiHtWm_dUxjeCD-hBid7jspkrTxrGRgeojAzY93qM1gl9hPtXfhE88bPMq39w5uKfmq-B5R0c_A4EPa8p3gtlKyNqjhPD6i92KtTEAYhAXj96AVd9OpjuGoe9HMLdjz40r35xireTm3VD8mxi0WE8Q3ulBg-5eEBh0um6AxdCfZ9BLoldpffl0rhJvikX3t8V4MMIC6hgbcWCt9KFPNslxuFWJpxrKtntF074VaZuSz-4a1CJc8BVvNSoD3PvJf4CrumeJoPdZkYT7sR5XNmpZRPDkFNSuG8h6QPgawN6QdZIteJrBCXIdGt4w5AT3yKdeSLZ9J9BE9EbCaiuafvdkJxOB0Rbo5Ry0S0DFcyqA5F-nN1iKI5yFI-44ZrBjgM87JInuKNTP4j9UsVVJNebpBPfomTn6_mC0)

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