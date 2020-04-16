# 快速上手指南

这个指南介绍如何快速上手使用 Helm。

## 前提条件

成功并正确安全的使用 Helm 需要具备如下几个条件：

+ 1、一个 Kubernetes 集群
+ 2、如果有，确定要应用于安装的安全配置
+ 3、安装和配置 Helm

### 安装 Kubernetes 或者有一个可访问的集群

+ 你必须有一个安装好的 Kubernetes。针对最新版本的 Helm，我们推荐最新稳定版的 Kubernetes，大多数情况下也是第二次新版本
+ 你还需要一个本地 `kubectl` 的配置副本

> 注意：1.6 之前的 Kubernetes 版本对于基于角色的访问控制（RBAC）的支持是受限或者不支持的。

## 安装 Helm

下载 Helm 客户端的二进制版本。你可以通过类似 `homebrew`（macOS 下包管理工具） 的工具，或者[官方版本页](https://github.com/helm/helm/releases)查看。

更详细的信息，或者选项，参见 [安装指南](https://helm.sh/docs/intro/install/)。

> 本身 Helm 的客户端就是一个二进制，安装来说不存在任何难度，不同系统安装不同的二进制版本即可。

## 初始化一个 Helm chart repository

安装好 Helm 之后，你可以添加一个 chart repository。从官方 Helm 稳定 charts 是一个好的开始：

```
$ helm repo add stable https://kubernetes-charts.storage.googleapis.com/
```

当你安装之后，你可以列出你可以安装的 charts：

```
$ helm search repo stable
NAME                                    CHART VERSION   APP VERSION                     DESCRIPTION
stable/acs-engine-autoscaler            2.2.2           2.1.1                           DEPRECATED Scales worker nodes within agent pools
stable/aerospike                        0.2.8           v4.5.0.5                        A Helm chart for Aerospike in Kubernetes
stable/airflow                          4.1.0           1.10.4                          Airflow is a platform to programmatically autho...
stable/ambassador                       4.1.0           0.81.0                          A Helm chart for Datawire Ambassador
# ... and many more
```

## 安装示例 Chart

你可以运行 `helm install` 命令安装一个 chart。Helm 有几种方式发现和安装一个 chart，但是最简单的是使用官方稳定的 charts。

```
$ helm repo update              # Make sure we get the latest list of charts
$ helm install stable/mysql --generate-name
Released smiling-penguin
```

在上面的例子中，`stable/mysql` chart 发布了，新版本的名称是 `smiling-penguin`。

通过运行 `helm show chart stable/mysql` 可以简单的了解 MySQL chart 的功能。或者运行 `helm show all stable/mysql` 获取该 chart 更多的信息。

当你安装一个 chart，一个新的版本就被创建了。一个 chart 可以在相同的集群安装多次。每一个都是可以被独立管理和更新的。

`helm install` 是具备很多功能的强大命令。获取更多的帮助可以查看 [Using Helm Guide](https://helm.sh/docs/intro/using_helm/)。

## 了解有关发布（RELEASES）的信息

通过 Helm 很容易看到发布了什么：

```
$ helm ls
NAME             VERSION   UPDATED                   STATUS    CHART
smiling-penguin  1         Wed Sep 28 12:59:46 2016  DEPLOYED  mysql-0.1.0
```

`helm list` 函数展示所有部署的发布列表。

## 卸载一个 RELEASE

使用 `helm uninstall` 卸载一个 release：

```
$ helm uninstall smiling-penguin
Removed smiling-penguin
```

这将从 Kubernetes 中卸载 `smiling-penguin`，这将删除所有与这个发布相关的资源和历史记录。

如果 `--keep-history` 选项开启，release 历史将会保存。你可以获取这个 release 相关的信息：

```
$ helm status smiling-penguin
Status: UNINSTALLED
...
```

因为 Helm 可以跟踪你的发布，即使在删除之后，你可以审计集群的历史，甚至取消删除 release（通过 `helm rollback`）。

## 查看帮助文档

使用 `helm help` 或者相关命令和 `-h` 选项组合可以获取更多可用的 Helm 命令：

```
$ helm get -h
```
