# infra

[![CircleCI](https://circleci.com/gh/cguertin14/infra.svg?style=shield)](https://circleci.com/gh/cguertin14/infra)

My infrastructure running on a Raspberry Pi Kubernetes Cluster.

## Structure of this repository

The [services/](./services) folder contains subfolders which contain different kinds of web/networking/other services.

## Dependencies

* [Terraform](https://terraform.io)
* [Ansible](https://www.ansible.com/)
* [Kubectl](https://kubernetes.io)
* [Kustomize](https://kustomize.io)
* [SOPS](https://github.com/mozilla/sops)
* [Kustomize-Sops](https://github.com/viaduct-ai/kustomize-sops)