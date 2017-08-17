## 集群构建

集群构建的方式有很多，官方提供`kubeadm` 可以很方便的构建，相关文档可以直接看官方提供的 [Using kubeadm to Create a Cluster](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)。现在该工具还处于 alpha 版本，所以生产环境不建议使用这种方式创建，但对于新手使用该工具快速构建一个 Kubernetes 集群还是非常便利的。本章节会介绍以下两种集群构建方式：

* [从头开始构建一个 Kubernetes 集群](chapter2-1.md)
* [通过 Ansible 自动构建 Kubernetes 集群](chapter2-2.md)

另外，如果有本地运行 Kubernetes 的需求，可以直接使用 [Minikube](https://github.com/kubernetes/minikube) 达到快速构建的目的，具体可以参考官方介绍。
