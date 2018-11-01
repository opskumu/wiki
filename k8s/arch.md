> `Kubernetes` (通常称为 K8s) 是用于自动部署、扩展和管理容器化（containerized）应用程序的开源系统。Google 设计并捐赠给 Cloud Native Computing Foundation（CNCF，今属 Linux 基金会）来使用的。它旨在提供 “跨主机集群的自动部署、扩展以及运行应用程序容器的平台”。它支持一系列容器工具, 包括 Docker 等。 -- 摘自维基百科 [Kubernetes](https://zh.wikipedia.org/wiki/Kubernetes) 词条

# Kubernetes 架构

![kubernetes-architecuture](images/architecture.png)

> [Kubernetes Design and Architecture](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/architecture/architecture.md#controller-manager-server)

## 集群控制平面（Cluster control plane）即 Master

Kubernetes 控制平面由一系列组件组成，可以运行在一个单独的主节点上，也可以分布部署以支持高可用集群，或者运行在 Kubernetes 之上。

### API 服务（API Server）

- kube-apiserver

API server 提供 [Kubernetes API](https://kubernetes.io/docs/concepts/overview/kubernetes-api/)。API server 扮演集群网关的角色，它主要处理 REST 操作，验证并更新到 `etcd` 存储。

### 集群状态存储（Cluster state store）

- etcd

`etcd` 是一个分布式 key-value 数据库，Kubernetes 用 `etcd` 作为后端数据存储。集群所有的持久性状态都存储在 `etcd` 实例中。`etcd` 提供了可靠配置数据存储。通过 `watch` 的支持，可以非常快速地通知协调组件变更。

### 控制管理服务（Controller-Manager Server）

- kube-controller-manager

集群内部的管理控制中心，如 Node、Volume、Deployment 、Service 等资源管理，以及空间生命周期，Pod GC、节点 GC 等。

### 调度器（Scheduler）

- kube-scheduler

执行 pod 的相关调度。调度程序监视未调度的 pod，并根据所请求资源的可用性，服务质量要求、亲和性和反亲和性设置以及其它约束，通过 `/binding` pod 子资源 API 绑定到相应节点。

## Kubernetes 节点（The Kubernetes Node）

### Kubelet

Kubelet 是 Kubernetes 中最重要和突出的控制器，它是驱动容器执行层的 Pod 和 Node API 的主要实现者。没有这些 API，Kubernetes 只是一个后端由键值存储支持的面向 CRUD 的 REST 应用程序框架。

Kubelet 决定 Pod 是否可以运行在给定的节点上的最终决策者，不是调度器也或者 DaemonSets。此外，Kubelet 还集成了 [cAdvisor](https://github.com/google/cadvisor) 资源监控 agent。

### 容器运行时（Container runtime）

每一个节点运行一个容器运行时，负责下载镜像和运行容器。Kubelet 不集成容器运行时。作为替代，定义了一个 [Container Runtime Interface](https://github.com/kubernetes/community/blob/master/contributors/devel/container-runtime-interface.md) 控制底层运行时并促进该层的可插拔性。当前支持的有 docker、[rkt](https://github.com/rkt/rkt)、[cri-o](https://github.com/kubernetes-incubator/cri-o)、[frakti](https://github.com/kubernetes/frakti)。

### Kube Proxy

service 的抽象提供了一种在公共访问策略（如负载均衡）下对 pod 进行分组的方式。Service 通过创建 VIP，提供给客户端访问，再透明代理到 Service 中的 pods。每个节点都运行一个 kube-proxy 进程，该进程维护一套 iptables 规则，以捕获对服务 IPs 的访问，并重定向到正确的后端（1.12.x ipvs 正式 GA，性能相对 iptables 有很大的提升）。

## 附加组件和依赖

* [DNS](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/dns) 提供集群内部解析和服务发现
* [Ingress controller](https://github.com/kubernetes/ingress-nginx) 提供内部服务七层代理到外部
* [Kubernetes Metrics Server](https://github.com/kubernetes-incubator/metrics-server) 替换 Heapster 监控
* [Dashboard](https://github.com/kubernetes/dashboard/) Kubernetes GUI

以及包括 [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) 等其它 [add-ons ](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons) 组件。
