# 卷（Volumes）

* [Volumes 官方说明](https://kubernetes.io/docs/concepts/storage/volumes/)

---

在 Kubernetes 中，容器运行后新增或修改的磁盘文件都是临时的，在容器 Crash 或者更新后，Kubelet 会重新启动新的容器，新的容器将是一个全新干净的环境，原有新增或修改的文件将会丢失。针对这种情况，对于不需要有数据存储的应用是不受影响的，但是如果有数据存储的需求就影响很大，这时候就需要引入 `Volumes` 的概念了，Kubernetes 提供 Volumes 的概念来满足有存储需求的应用。

我们知道 Docker 也有 [Volumes](https://docs.docker.com/storage/volumes/) 的概念，但是相对松散和缺乏管理的。在 Docker 中，卷只是磁盘上或者另外一个容器中的目录。生命周期也不受管理，直到最近才有本地磁盘支持的卷。Docker 现在提供了卷驱动程序，但是功能非常有限（例如，从 Docker 1.7 开始，每个 容器只允许一个卷驱动程序，并且无法将参数传递给卷）。

Kubernetes 卷具有明确的生命周期，和伴随它的 Pod 相同。因此，卷可以比 Pod 中运行的容器周期要长，并且可以在容器重新启动之间保留数据。当 Pod 不存在时，卷也就不复存在了（数据是否保留取决于设定规则）。另外，Kubernetes 支持多种类型的卷，Pod 可以同时使用任意数量的卷。

本质上来说，卷只是一个目录，可以被 Pod 中的容器访问。目录是如何形成的，取决于使用的卷类型。

要使用卷，需要同时指定 `.spec.volumes`（指定卷）字段和 `.spec.containers.volumeMounts`（容器中挂载路径） 字段。

## 支持卷类型

这里列出 Kubernetes 支持的常用卷类型：

### cephfs

### rbd

`cephfs`、`rbd` 是 Ceph 提供的功能，如果使用了相关卷，需要在宿主上安装好对应版本的 `ceph-common`，以支持 kubelet 挂载调用，否则会导致挂载失败。

### configMap

`configMap` 资源提供了一种将配置数据注入 Pod 的方法，存储在 `configMap` 对象中的数据可以在 `configMap` 类型的卷中引用，然后被 Pod 中运行的容器化应用程序使用。通过 `configMap` 可以动态的修改指定的容器中的配置，从而达到在不同环境使用同一镜像不同配置的目的，因此这是一个非常常用的一个卷类型。

{% hint style="info" %}
早期 `configMap` 只能以目录的形式覆盖对应容器中的配置目录，针对单个文件是无法覆盖的，Kubernetes [CHANGELOG-1.3](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.3.md) 开始支持 subPath 特性 [Add subPath to mount a child dir or file of a volumeMount](https://github.com/kubernetes/kubernetes/pull/22575)，通过 [subPath](https://kubernetes.io/docs/concepts/storage/volumes/#using-subpath) 可以挂载子目录或者文件，如此便可以在目标容器配置目录有多个文件的时候只覆盖指定的配置，而不是直接目录覆盖。
不过，要注意的是，subPath 挂载会导致 configMap 更新之后容器中的文件不会实时同步更新。
{% endhint %}

### emptyDir

`emptyDir` 卷在 Pod 关联到节点后初始化创建，Pod 运行在该节点多久就存在多久。一般用于存放临时文件。

{% hint style="info" %}
容器崩溃不会从节点中删除 Pod，因此 `emptyDir` 卷中的数据在容器崩溃中是安全的。
{% endhint %}

默认情况下，`emptyDir` 卷存储支持节点上的任何介质，可能是磁盘、SSD 或者网络存储，这取决于你的环境。不过你可以通过 `emptyDir.medium` 字段来设置为 `Memory`，用来告诉 Kubernetes 挂载 tmpfs。虽然 tmpfs 速度很快，不同于磁盘，tmpfs 会在节点重启后数据被清除，而且使用的内存受限于容器的内存限制。

### glusterfs

同 `cephfs`、`rbd`，如果要使用 `glusterfs`，那么宿主节点需要安装好对应版本的 `glusterfs-libs`、`glusterfs`，以支持 kubelet 挂载调用，否则导致挂载失败。

### hostPath

`hostPath` 卷用于将主机节点的文件或目录挂载到 Pod。`hostPath` 可以挂载主机的特定目录、文件到 Pod 中，但是要注意的一点是，如果是数据存储的需求使用 `hostPath` 需要通过 [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/) 来固定对应节点，否则下次调度到不同节点之后，数据就不存在了。

`hostPath` 有一个 `type` 属性字段，支持以下值：

| 值 | 用途 |
|:-- |:--  |
|    | 空值（默认）用于向后兼容，在挂载 hostPath 卷之前不会执行任何检查 |
| DirectoryOrCreate | 如果给定的路径不存在，则创建一个 0755 权限的空目录，和 Kubelet 拥有相同的属主和属组 |
| Directory | 给定的目录路径必须存在 |
| FileOrCreate | 如果给定的路径不存在，则会创建一个 0644 权限的空文件，和 Kubelet 拥有相同的属主和属组 |
| File | 给定的文件路径必须存在 |
| Socket | 给定的 UNIX socket 路径必须存在 |
| CharDevice | 给定的字符串设备路径必须存在 |
| BlockDevice | 给定的块设备路径必须存在 |

默认在底层宿主上创建的文件或目录只能由 root 写入，因此需要以 root 权限运行进程或者在宿主上修改文件权限以支持写入 `hostPath` 卷。

{% hint style="info" %}
也可以通过 Pod `securityContext.fsGroup` 来修改卷的属组。
{% endhint %}

示例：

```
apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: k8s.gcr.io/test-webserver
    name: test-container
    volumeMounts:
    - mountPath: /test-pd
      name: test-volume
  volumes:
  - name: test-volume
    hostPath:
      # directory location on host
      path: /data
      # this field is optional
      type: Directory
```

### iscsi

### local（FEATURE STATE: Kubernetes v1.10 beta）

`local` 卷表示已挂载的本地存储设备，如磁盘、分区或目录。`local` 卷只能用于静态创建的 PersistentVolume，还不支持动态配置。相对 `hostPath` 卷，可以持久且可移植的方式使用本地卷，并无需像 `hostPath` 一样指定调度节点，系统通过查看 PersistentVolume 上的节点关联性来了解卷的节点约束（这一点来看，其实只是将原先在 Pod 层面的节点指定移到了卷上指定而已，并没有实质性变化）。

但是 `local` 卷仍然受限于节点，如果节点不健康，那么 `local` 卷也会变得不可访问，使用它的 Pod 也将无法运行。使用 `local` 卷的程序必须能够容忍这种降低可用性以及潜在数据丢失的可能性，这具体取决于底层磁盘的持久性特征。以下是使用 `local` 卷和 `nodeAffinity` 的示例 PersistentVolume 规范：

```
apiVersion:   v1
  kind:   PersistentVolume
  metadata:
    name:   example-pv
  spec:
    capacity:
      storage:   100Gi
    # volumeMode field requires BlockVolume Alpha feature gate to be enabled.
    volumeMode:   Filesystem
    accessModes:
    -   ReadWriteOnce
    persistentVolumeReclaimPolicy:   Delete
    storageClassName:   local-storage
    local:
      path:   /mnt/disks/ssd1
    nodeAffinity:
      required:
        nodeSelectorTerms:
        -   matchExpressions:
          -   key:   kubernetes.io/hostname
            operator:   In
            values:
            -   example-node
```

### nfs

### persistentVolumeClaim

### secret

以上列出的笔者觉得比较常用的，有些加了说明，另外还支持 azure、aws 等云厂商的存储，更详细的信息建议参见官方文档 [Types of Volumes](https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes)。
