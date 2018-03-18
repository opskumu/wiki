# Kubernetes 资源

## namespaces

同一个 Kubernetes 物理集群支持多个虚拟集群，而这个虚拟集群的概念就是 namespaces。这是官方的介绍，官方的介绍多少有点让人不那么容易理解。简单来说，namespaces 可以认为是一个环境或者项目组的概念，namespaces 下创建操作相应的服务。每个 namespaces 都是逻辑隔离的，针对指定 namespaces 可以做相应的资源（CPU、Memory 等）限制以及用户权限控制（RBAC）。namespaces 名字是全局唯一的。

> __注：__ 针对同一软件的不同版本，官方是不建议启用多个 namespaces 的，而是推荐在同一个 namespaces 下使用 `labels` 去区分标识。不过，这还是得看情况，针对多环境不同版本测试来说，还是采用多个 namespaces 比较好，方便隔离。

Kubernetes 集群创建之后会看到三个初始化 namespaces：

- `default` 默认 namespace
- `kube-system` Kubernetes 系统 namespace
- `kube-public` 用于集群中所有用户都可读的 namespace，是个惯例做法，但是非必须的

## pod

pod 是 Kubernetes 中创建和管理的最小可部署计算单元，一个 pod 是由一个或者多个容器组成（如 Docker 容器），pod 中的容器共享存储/网络。

## ReplicaSet (RS) and ReplicationController (RC)

单个部署 pod，如果 pod 因为一些因素异常退出了，pod 本身是不会自动恢复的。RS 和 RC 则担任管理 pod 状态的角色，RS 和 RC 的机制保证通过它们管理的 pod 保持固定的副本数并持续运行。如果 pod 因异常原退出了，那么 RS 和 RC 会请求创建新的 pod。

## deployments

## replicasets

## jobs

## service

## endpoints

## ingresses

## secret

## configmap
