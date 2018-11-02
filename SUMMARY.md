# SUMMARY

* [说明](README.md)

---

* Docker
    * [理论概述](moby/chapter1.md)
    * [安装入门](moby/chapter2.md)
    * [配置说明](moby/chapter3.md)
    * [基础命令](moby/chapter4.md)
    * [镜像构建](moby/chapter5.md)

---

* Kubernetes
    * [架构概览](k8s/arch.md)
    * [基础术语](k8s/concepts.md)
    * 工作负载
        * [Deployments](k8s/concepts-deployments.md)
        * [StatefulSets](k8s/concepts-statefulsets.md)
    * 存储
        * [Persistent Volumes](k8s/concepts-pv.md)
    * [集群构建](k8s/install.md)
        * [从头开始构建 Kubernetes 集群](k8s/install-manual.md)
    * 组件
        * Kubelet
            * [Kubelet 配置说明](k8s/cfg-kubelet.md)
        * 网络
            * [Calico BGP 网络](k8s/calico.md)
            * [Kubelet CNI 源码解析](k8s/src-kubelet-cni.md)
    * 译文
      * [Google 大规模集群管理器 Borg](k8s/borg.md)
