> `Kubernetes` (通常称为 K8s) 是用于自动部署、扩展和管理容器化（containerized）应用程序的开源系统。Google 设计并捐赠给 Cloud Native Computing Foundation（CNCF，今属 Linux 基金会）来使用的。它旨在提供 “跨主机集群的自动部署、扩展以及运行应用程序容器的平台”。它支持一系列容器工具, 包括 Docker 等。 -- 摘自维基百科 [Kubernetes](https://zh.wikipedia.org/wiki/Kubernetes) 词条

# Kubernetes 架构

![kubernetes-architecuture](images/architecture.png)

# Kubernetes 组件

## Master 组件

- kube-apiserver
    - 提供内外交互的接口，唯一和 `etcd` 直接交互的组件
- kube-scheduler
    - 执行 pod 的相关调度
- kube-controller-manager
    - 集群内部的管理控制中心，如 Node、Volume、Deployment 、Service 资源管理等
- etcd
    - `etcd` 是一个分布式 key-value 数据库，`Kubernetes` 用 `etcd` 作为后端数据存储

## Node 组件

- kubelet
    - 管理节点 Pod 生命周期（创建、更新、删除、监控等）
- kube-proxy
    - 实现 Service 的代理以及负载均衡
