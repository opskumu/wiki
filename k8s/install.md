# 集群构建

集群构建的方式有很多，官方提供`kubeadm` 可以很方便的构建，相关文档可以直接看官方提供的 [Using kubeadm to Create a Cluster](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)。

{% hint style="info" %}
`kubeadm` 已经 GA 了，生产环境用户可以选择这种方式部署。不过，还是建议手动部署一遍 Kubernetes 集群，加深对 Kubernetes 整个运维架构的理解，也方便自行定制。
{% endhint %}

本章节会介绍以下两种集群构建方式：

* [从头开始构建一个 Kubernetes 集群](install-manual.md)
* [通过 Ansible 自动构建 Kubernetes 集群 kubespray](https://github.com/kubernetes-sigs/kubespray)
    * 此处 Ansible 自动构建 Kubernetes 集群，给的项目为 kubespray，已经非常成熟，可以借鉴该项目自行定制

另外，如果有本地运行 Kubernetes 的需求，可以直接使用 [Minikube](https://github.com/kubernetes/minikube) 达到快速构建的目的，具体可以参考官方介绍。
