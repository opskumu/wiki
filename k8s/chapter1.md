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
    - 集群内部的管理控制中心，如 Node、Volume、Deployment 、Service 等资源管理
- etcd
    - `etcd` 是一个分布式 key-value 数据库，`Kubernetes` 用 `etcd` 作为后端数据存储

## Node 组件

- kubelet
    - 管理节点 Pod 生命周期（创建、更新、删除、监控等）
- kube-proxy
    - 实现 Service 的代理以及负载均衡

# 基本术语

## namespaces

同一个 Kubernetes 物理集群支持多个虚拟集群，而这个虚拟集群的概念就是 namespaces。这是官方的介绍，官方的介绍多少有点让人不那么容易理解。简单来说，namespaces 可以认为是一个环境或者项目组的概念，每个 namespaces 都是逻辑隔离的，针对指定 namespaces 可以做相应的资源（CPU、Memory 等）限制以及用户权限控制（RBAC）。namespaces 名字是全局唯一的。

> __注：__ 针对同一软件的不同版本，官方是不建议启用多个 namespaces 的，而是推荐在同一个 namespaces 下使用 `labels` 去区分标识。不过，这还是得看情况，针对多环境不同版本测试来说，还是采用多个 namespaces 比较好，方便隔离。

Kubernetes 集群创建之后会看到三个初始化 namespaces：

- `default` 默认 namespace
- `kube-system` Kubernetes 系统 namespace
- `kube-public` 用于集群所有用户可读的 namespace，是个惯例做法，但是非必须的

## pod

## replicationcontrollers

## deployments

## replicasets

## jobs

## service

## endpoints

## ingresses

## secret

## configmap
