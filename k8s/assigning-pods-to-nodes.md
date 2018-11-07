# Assigning Pods to Nodes

* [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/)

通过 Kubernetes 你可以将一个 pod 限制或优先在某些特定节点运行。有几种方式可以达到这个目的，它们都通过 [label selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) 进行选择。通常情况下，这样的约束是不必要的，因为调度程序会自动进行合理的调度（如通过一系列的评分机制将 pods 合理分配到最优节点上，而不会将 pod 分配在没有足够资源的节点上等）。但是在某些情况下，可能需要更多的策略控制，例如，将 pod 调度到 SSD 的计算节点上，或者将两个通信比较频繁的不同服务 pod 调度到同一个可用域。

`labels` 在 K8s 中是一个很重要的概念，作为一个标识，Service、Deployments、Pods 之间的关联都是通过 `label` 来实现的。而每个节点也都拥有 `label`，通过设置 `label` 相关的策略可以使得 pods 关联到对应 `label` 的节点上。

## nodeSelector


## Affinity and anti-affinity
