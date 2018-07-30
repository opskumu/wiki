# 持久性卷（Persistent Volumes）

* [Persistent Volumes 官方说明](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

## 介绍

为管理存储，K8s 引入了两个新的资源对象：`PersistentVolume` 和 `PersistentVolumeClaim`。

`PersistentVolume`(PV) 是集群中管理员分配的一块存储。它属于集群中的资源，如同节点是集群中的资源一样。它拥有生命周期，但是独立于那些使用 PV 的 Pod 生命周期。支持 NFS、iSCSI、以及云供应商的存储系统。

`PersistentVolumeClaim`(PVC) 用于用户请求存储资源。它类似 Pod，Pod 消耗节点资源，PVC 消耗 PV 资源。Pods 可以请求特定级别的资源（CPU 和 内存）。PVC 可以请求特定的存储大小和访问模式（如可以一次读写挂载或只读模式）。

## 卷和声明的生命周期

PVs 是集群中的资源，PVCs 是对这些资源的请求，它们遵循以下生命周期：

### 提供

可以通过两种方式配置 PVs：静态或者动态方式。

__静态__

集群管理员创建一定数量的 PVs，它们包括可供集群用户使用实际存储的详细信息。

__动态__

当用户的 `PersistentVolumeClaim` 没有匹配到管理员创建的 PVs 时，集群可能会尝试为 PVC 专门动态配置卷。这种动态提供基于 `StorageClasses`：PVC 必须请求一个 [storage class](https://kubernetes.io/docs/concepts/storage/storage-classes/) 并且管理员必须创建和配置 class 以达到动态提供的目的。

为了开启基于 storage class 的动态存储，集群管理员需要在 API server 上启用 `DefaultStorageClass` [admission controller](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#defaultstorageclass)。确认 `DefaultStorageClass` 在 `--enable-admission-plugins` 逗号分隔的参数列表中。

> **[info] 标注**  
>  在 1.10.x 及以上版本控制选项为 `--enable-admission-plugins`，而 1.9.x 及以下版本为 `--admission-control`。

### 绑定


### 使用
