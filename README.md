# infra

[![CircleCI](https://circleci.com/gh/cguertin14/infra.svg?style=shield)](https://circleci.com/gh/cguertin14/infra)

My infrastructure running on a Raspberry Pi Kubernetes Cluster.

## Structure of this repository

The [services/](./services) folder contains subfolders which contain different kinds of web/networking/other services.

## Dependencies

* [Docker](https://docker.io)
* [Terraform](https://terraform.io)
* [Ansible](https://www.ansible.com/)
* [Kubectl](https://kubernetes.io)
* [Kustomize](https://kustomize.io)
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
