## Kubernetes 架构

![kubernetes-architecuture](images/architecture.png)

## Kubernetes 组件

### Master 组件

- kube-apiserver
- kube-scheduler
- kube-controller-manager
- etcd
  - `etcd` 作为 Kubernetes 的存储服务，所有集群的数据都存储在 `etcd` 中

### Node 组件

- kubelet
- kube-proxy
