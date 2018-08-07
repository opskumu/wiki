# SUMMARY

* [说明](README.md)

---

* Docker 手册
    * [概述](moby/chapter1.md)
    * [安装](moby/chapter2.md)
    * [配置说明](moby/chapter3.md)
    * [基础命令](moby/chapter4.md)
    * [镜像构建](moby/chapter5.md)

---

* Kubernetes 手册
    * [概述](k8s/arch.md)
    * [理论](k8s/concepts.md)
        * [StatefulSets](k8s/concepts-statefulsets.md)
        * [Persistent Volumes](k8s/concepts-pv.md)
    * [集群构建](k8s/install.md)
        * [从头开始构建 Kubernetes 集群](k8s/install-manual.md)
    * 组件配置
        * [kubelet](k8s/cfg-kubelet.md)
    * 源码解析
      * [kubelet](k8s/src-kubelet.md)
    * 网络
      * [Calico](k8s/calico.md)
    * 译文
      * [Google 大规模集群管理器 Borg](k8s/borg.md)
