# Kubernetes 网络策略

如果你在 IP 地址或者端口级别（OSI 3 层或者 4 层）控制流量，那么你可以考虑对集群中的特定应用程序使用 Kubernetes 网络策略。

网络策略通过 [network plugin](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/) 实现，使用网络策略必须选用支持 `NetworkPolicy` 的网络解决方案，比如 Calico 方案是支持网络策略的。创建 `NetworkPolicy` 资源，但是没有相关的控制器实现，策略本身是不生效的。可以类比 `Ingress` 本身没有 ingress-controller，本身的规则也是无意义的。

默认，pods 之间所有的流量都放行的。网络策略不存在冲突，如果一个或者多个策略选择一个 POd，那么该 Pod 受限于这些策略的 ingress/egress 规则允许的并集。评估顺序本身并不影响策略结果。

## NetworkPolicy 资源

``` yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - ipBlock:
        cidr: 172.17.0.0/16
        except:
        - 172.17.1.0/24
    - namespaceSelector:
        matchLabels:
          project: myproject
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 6379
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/24
    ports:
    - protocol: TCP
      port: 5978
```

+ `podSelector`：每个 NetworkPolicy 包括一个 `podSelector` 用于选择策略所应用的 pods 分组。示例中策略选择器拥有 `role: db` 标签的 pods。空的 `podSelector` 匹配空间下的所有 pods。
s
+ `policyTypes`：每个 NetworkPolicy 包括一个 `policyTypes` 列表，包括 `Ingress`，`Egress` 或两者都有。`policyTypes` 表示是否应用 ingress（入口） 流量到选定 pod 或者从选择的 pods 应用 egress（出口） 流量规则。 如果 NetworkPolicy 上未指定任何 `policyTypes`，则默认情况下始终设置 `Ingress`，如果 NetworkPolicy 具有任何出口规则，则设置 `Egress`。

+ `ingress`：每个 NetworkPolicy 可以包括允许的 `ingress` 规则列表。每个规则允许匹配 `from` 和 `ports` 部分的流量。示例中包含一个规则，表示任何匹配源中都可以访问匹配的 Pod 的 6379 TCP 端口。

+ `egress`：每个 NetworkPolicy 可以包括允许的 egress 规则列表。每个规则允许匹配到 `to` 和 `ports` 部分的流量。示例中包含一个规则，表示匹配的 Pod 可以访问任何在网段 10.0.0.0/24 中的 5978 TCP 端口。

示例规则综合起来表示，隔离 default 空间下标签为 "role=db" 的 pods 的 ingress 和 egress 流量。针对 ingress 流量，default 空间下所有含有 "role=db" 的 pods 的 6379 端口允许 "default" 空间下任何标签为 "role=frontend" 的 pod 访问，允许含有 "project=myproject" 标签的空间下的任何 pod 访问，允许 172.17.0.0/16 网段中除了 172.17.1.0/24 网段的 IP 访问。出口流量则允许 default 空间下含有 "role=db" 的 pod 访问网段为 10.0.0.0/24 端口为 5978 的服务。

## `to` 和 `from` 选择器

+ `podSelector`：在 NetworkPolicy 同一空间下选择 Pods，作为 ingress 源或者 egress 目的地
+ `namespaceSelector`：选择特定空间下的所有 Pods，作为 ingress 源或者 egress 目的地
+ `to` 或者 `from` 下的 `namespaceSelector` 和 `podSelector`： to/from 下的条目，同时指定 `namespaceSelector` 和 `podSelector` 来指定特定的 pods
+ `ipBlock`：选择特定的 IP CIDR 范围来允许 ingress 源或者 egress 目的地。这些应该用于集群外的 IP，因为 Pod IP 并不是固定的
