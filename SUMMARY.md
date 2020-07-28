# SUMMARY

* [SUMMARY](SUMMARY.md)

---

## Docker

* [理论概述](moby/chapter1.md)
* [安装入门](moby/chapter2.md)
* [配置说明](moby/chapter3.md)
* [基础命令](moby/chapter4.md)
* [镜像构建](moby/chapter5.md)
* 镜像存储
    * [OverlayFS 存储驱动](moby/docker-overlayfs.md)
    * [Habor 安装和升级标注](moby/harbor.md)
* Compose
    * [Compose 概览](moby/docker-compose-overview.md)
    * [Compose 安装](moby/docker-compose-install.md)
    * [Compose 入门](moby/docker-compose-getting-started.md)
    * [Compose 环境变量](moby/docker-compose-envs.md)
    * [Compose 服务扩展](moby/docker-compose-extends.md)
    * [Compose 网络](moby/docker-compose-network.md)
    * [Compose 生产实践](moby/docker-compose-production.md)
    * [Compose 启动顺序控制](moby/docker-compose-startup-order.md)

## Kubernetes

* [架构概览](k8s/arch.md)
* [基础术语](k8s/concepts.md)
* [集群构建](k8s/install.md)
* [工作负载](k8s/workload.md)
    * [Deployments](k8s/concepts-deployments.md)
    * [StatefulSets](k8s/concepts-statefulsets.md)
    * [Volumes](k8s/concepts-volumes.md)
    * [Persistent Volumes](k8s/concepts-pv.md)
* 集群调度
    * [亲和性和反亲和性](k8s/assigning-pods-to-nodes.md)
    * [污点和容忍机制](k8s/taint-and-toleration.md)
* 集群组件
    * [Kubelet](k8s/kubelet.md)
* 网络方案
    * [Calico BGP 网络（v2.6.x）](k8s/calico.md)
    * [Kubelet CNI 源码解析](k8s/src-kubelet-cni.md)
* client-go
    * [client-go 背后机制](k8s/controller-client-go.md)
* [Helm](k8s/helm.md)
    * [Helm 架构](k8s/helm-arch.md)
    * [Helm 快速上手](k8s/helm-quickstart.md)
    * [Helm 使用](k8s/helm-using.md)
    * [Helm 命令](k8s/helm-command.md)
* [Google 大规模集群管理器 Borg](k8s/borg.md)
