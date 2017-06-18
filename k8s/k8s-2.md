## 集群构建

集群构建的方式有很多，官方提供的 `kubeadm`，相关文档可以直接看官方提供的 [Using kubeadm to Create a Cluster](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)。现在该工具还处于 alpha 版本，所以生产环境不建议使用这种方式创建，但对于新手使用该工具快速构建一个 Kubernetes 集群还是非常便利的。本章节先介绍如何从头开始构建一个 Kubernetes 集群，然后介绍如何通过 Ansible 自动构建 Kubernetes 集群。 
