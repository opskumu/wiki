# 使用 Helm

这份指南介绍在 Kubernetes 集群中使用 Helm 管理包的基础知识。假设你已经安装了 Helm client。

如果你仅对运行一些快捷命令感兴趣，那么可以从 [Quickstart Guide](https://helm.sh/docs/intro/quickstart/) 开始入手。这个章节覆盖了 Helm 命令的细节，并解释如何使用 Helm。

## 三大概念

`Chart` 是 Helm 的包。它包含了在 Kubernetes 集群中运行一个应用、工具或者服务的所有资源的必要定义。好比 Homebrew 的 formula，Apt 的 apkg ，或者 Yum 的 RPM 文件。

`Repository` 是存放收集和共享 charts 的地方。好比 Perl 的 [CPAN archive](https://www.cpan.org/) 或者 Fedora 的 [Package Database](https://admin.fedoraproject.org/pkgdb/)，只是它是针对 Kubernetes 的包。

`Release` 是 chart 运行在 Kubernetes 集群的对应实例。一个 chart 可以在一个相同的集群俺逐行多次。每次安装都创建一个新的 release。以 MySQL chart 为例，如果你想在集群中运行两个数据库，你可以安装这个 chart 两次。每次安装对应一个 release，每个 release 都有对应的名称。

伴随这几个概念，我们现在可以这样解释 Helm：

> Helm 安装 charts 到 Kubernetes 中，每次安装创建一个新的 release。如果要找新的 charts，你可以通过搜索 Helm chart repositories。

## 'HELM SEARCH': 搜索 CHARTS

Helm 拥有强大的搜索命名，它可以搜索两种不同类型的源：

+ `helm search hub` 搜索 [the Helm Hub](https://hub.helm.sh/)，其中包括来自数十个不同 helm charts repositories
+ `helm search repo` 搜索本地 helm client 添加过的 repositories。该搜索是通过本地数据库完成的，不需要访问公网连接。

你可以通过运行 `helm search hub` 发现公共可用的 charts：

```
$ helm search hub wordpress
URL                                               	CHART VERSION	APP VERSION	DESCRIPTION
https://hub.helm.sh/charts/bitnami/wordpress      	7.6.7        	5.2.4      	Web publishing platform for building blogs and ...
https://hub.helm.sh/charts/presslabs/wordpress-...	v0.6.3       	v0.6.3     	Presslabs WordPress Operator Helm Chart
https://hub.helm.sh/charts/presslabs/wordpress-...	v0.7.1       	v0.7.1     	A Helm chart for deploying a WordPress site on ...
```

以上列出了在 Helm Hub 上所有 `wordpress` charts。

在没有过滤的情况下，`helm search hub` 会展示所有可用的 charts。

使用 `helm search repo`，你可以在已经添加过的 repositories 中找到 charts 的名称：

```
$ helm repo add brigade https://brigadecore.github.io/charts
"brigade" has been added to your repositories
$ helm search repo brigade
NAME                        	CHART VERSION	APP VERSION	DESCRIPTION
brigade/brigade             	1.3.2        	v1.2.1     	Brigade provides event-driven scripting of Kube...
brigade/brigade-github-app  	0.4.1        	v0.2.1     	The Brigade GitHub App, an advanced gateway for...
brigade/brigade-github-oauth	0.2.0        	v0.20.0    	The legacy OAuth GitHub Gateway for Brigade
brigade/brigade-k8s-gateway 	0.1.0        	           	A Helm chart for Kubernetes
brigade/brigade-project     	1.0.0        	v1.0.0     	Create a Brigade project
brigade/kashti              	0.4.0        	v0.4.0     	A Helm chart for Kubernetes
```

Helm 搜索使用模糊字匹配算法，因此你可以输入单词或者短语的一部分：

```
$ helm search repo kash
NAME          	CHART VERSION	APP VERSION	DESCRIPTION
brigade/kashti	0.4.0        	v0.4.0     	A Helm chart for Kubernetes
```

搜索是一种发现可用包的好方法，当你寻找到想要安装的包后，你可以使用 `helm install` 来安装它。

## 'HELM INSTALL'：安装一个包

使用 `helm install` 命令来安装一个新包。简单来说，它包含两个参数：你选择的 release 名称和你需要安装 chart 的名称。

```
$ helm install happy-panda stable/mariadb
```

当前 `mariadb` chart 已经安装了。注意安装一个 chart 创建了一个新的 `release` object。release 名称是 `happy-panda`。（如果你想让 Helm 生成随机名称，删除自定义名并添加 `--generate-name` 选项。）

在安装过程中，`helm` 客户端会打印出有用的信息，包括什么资源被创建了，release 的状态信息，以及一些需要你介入的附加配置项。

Helm 不会等所有的资源都运行后才推出。许多 charts 需要超过 600M 大小的镜像，并且需要很长时间才能安装到集群。

为了跟踪 release 的状态，或者重新读取配置信息，你可以使用 `helm status`:

```
$ helm status happy-panda
Last Deployed: Wed Sep 28 12:32:28 2016
Namespace: default
Status: DEPLOYED
...
```

以上展示了你的 release 当前的状态。

### 安装前自定义 Chart

刚刚安装的方式，只是使用 chart 的默认选项。很多时候，你需要自定义 chart 为你的首选配置。

可以通过 `helm show values` 查看一个 chart 的配置项：

```
$ helm show values stable/mariadb
```

你可以覆盖 YAML 格式文件中的任意配置，在安装的时候传递到文件中。

```
$ echo '{mariadbUser: user0, mariadbDatabase: user0db}' > config.yaml
$ helm install -f config.yaml stable/mariadb --generate-name
```

上面将会创建一个默认的 MariaDB 用户 `user0`，并把该用户赋权给新创建的 `user0db` 数据库，其他项都是用 chart 的默认值。

这里有两个方式在安装时传递配置数据：

+ `--values` （或者 `-f`）：指定替换的 YAML 文件。可多次指定选项，最右边的文件优先
+ `--set`：命令行上指定替代

如果同时使用，`--set` 值会以更高的优先级合并到 `--values` 中。通过 `--set` 覆盖值将保存在 ConfigMap 中。给定 release `--set` 的值可以通过 `helm get values <release-name>` 查看。`--set` 设置的值可以通过运行 `helm upgrade` 指定 `--reset-values` 来清理。

### `--set` 格式和限制

`--set` 选项采用零个或多个 name/value 对。最简单的用法是： `--set name=value`。相当于 YAML：

```
name: value
```

多个值通过 `,` 分隔，因此 `--set a=b,c=d` 等价于：

```
a: b
c: d
```

复杂的表达式也支持。如，`--set outer.inner=value` 被翻译成：

```
outer:
  inner: value
```

可以通过 `{` 和 `}` 来表示列表。如，`--set name={a, b, c}` 翻译成：

```
name:
  - a
  - b
  - c
```

从 Helm 2.5.0 开始，可以使用数组索引语法访问列表项。如，`--set servers[0].port=80`：

```
servers:
  - port: 80
```

`--set servers[0].port=80,servers[0].host=example` 设置多个值：

```
servers:
  - port: 80
    host: example
```

有时候你需要在 `--set` 上使用特殊的字符。你可以通过 `\` 转义，`--set name=value1\,value2`：

```
name: "value1,value2"
```

同样，你可以转义点序列，这会给使用 `toYaml` 函数解析 annotations，labels 和 node selectors 时带来便利。`--set nodeSelector."kubernetes\.io/role"=master`：

```
nodeSelector:
  kubernetes.io/role: master
```

使用 `--set` 很难表达深层嵌套的数据结构。鼓励 Chart 设计人员在设计 `values.yaml` 文件的时候考虑 `--set` 用法。

### 更多安装的方法

`helm install` 命令可以从多个源安装：

+ chart repository（和上面提到的一样）
+ 本地 chart 归档（`helm install foo foo-0.1.1.tgz`）
+ 解包的 chart 目录（`helm install foopath/to/foo`）
+ 完整的 URL（`helm install foo https://example.com/charts/foo-1.2.3.tgz`）

## 'HELM UPGRADE' 和 'HELM ROLLBACK': 升级和失败恢复 RELEASE

当 chart 的新版本发布了，或者当你想修改你的 release 的时候，你可以使用 `helm upgrade` 命令。

升级针对当前存在的 release 通过你提供的信息升级。因为 Kubernetes charts 可能很大并且复杂，因此 Helm 尝试执行侵入性最小的升级。它将只更新自上一个 release 以来已经变更的内容。

```
$ helm upgrade -f panda.yaml happy-panda stable/mariadb
Fetched stable/mariadb-0.3.0.tgz to /Users/mattbutcher/Code/Go/src/helm.sh/helm/mariadb-0.3.0.tgz
happy-panda has been upgraded. Happy Helming!
Last Deployed: Wed Sep 28 12:47:54 2016
Namespace: default
Status: DEPLOYED
...
```

上面的例子，`happy-panda` release 通过新的 YAML 文件，使用同一个 chart 升级：

```
mariadbUser: user1
```

我们可以使用 `helm get values` 查看新的设置是否生效。

```
$ helm get values happy-panda
mariadbUser: user1
```

`helm get` 命令是集群中获取 release 的非常有用的工具。从上面我们可以看到，它展示了已经部署到集群的 `panda.yaml` 新的值。

现在，如果当一个 release 没有按照计划的方式运行，通过 `helm rollback [RELEASE] [REVISION]` 可以很容易回滚到之前的版本。

```
$ helm rollback happy-panda 1
```

上面回滚我们的 happy-panda 到它的第一个 release 版本。release 版本是一个递增的修订。每一次安装，升级或者回滚发生时，修订号递增 1。第一个修订号总是 1。我们可以通过 `helm history [RELEASE]` 查看某个 release 修订号

## INSTALL/UPGRADE/ROLLBACK 帮助项

这里有几个其他有用的选项，以便当使用 Helm 执行 install/upgrade/rollback 时自定义操作。请注意这不是一个完整的客户端参数。查看所有参数的描述，运行 `helm <command> --help`。

+ `--timeout`：指定等待 Kubernetes 命令完成时间，默认 5m0s
+ `--wait`：等待直到所有的 Pods 处于 Ready 状态，PVCs bound，Deployments 达到最低限度（Desired - maxUnavailable）的 Pods 处于 Ready 状态以及 Service 有一个 IP 地址（并且 Ingress 如果需要 `LoadBalancer`）时，才标记 release 成功。等待的时间受 `--timeout` 值限制。如果超时了，则 release 会被标记为 `FAILED`。注意：在 Deployment `replicas` 设置为 1，滚动更新策略 `maxUnavailable` 没有被设置为 0 时，`--wait` 会返回 ready，因为它已经满足 ready 条件中的最小 Pod 数。
+ `--no-hooks`：跳过执行钩子

## 'HELM UNINSTALL'：卸载一个 RELEASE

通过 `helm uninstall` 命令从集群卸载 release：

```
$ helm uninstall happy-panda
```

这将从集群中移除 release，你可以通过 `helm list` 命令列出当前所有已经部署的 releases：

```
$ helm list
NAME            VERSION UPDATED                         STATUS          CHART
inky-cat        1       Wed Sep 28 12:59:46 2016
```

从上面的输出，你可以看到 `happy-panda` release 已经卸载了。

在之前的 Helm 版本中，当一个 release 已经被删除了，它的删除记录会被保留。Helm3 中，删除 release 也会删除其记录。如果你想保留删除 release 的记录，使用 `helm uninstall --keep-history`。使用 `helm list --uninstalled` 只展示卸载是使用 `--keep-history` 参数的 releases。

`helm list --all` 参数会展示 Helm 保留的所有 release 记录，包括失败的或者删除项（如果 `--keep-history` 指定了）：

```
$  helm list --all
NAME            VERSION UPDATED                         STATUS          CHART
happy-panda     2       Wed Sep 28 12:47:54 2016        UNINSTALLED     mariadb-0.3.0
inky-cat        1       Wed Sep 28 12:59:46 2016        DEPLOYED        alpine-0.1.0
kindred-angelf  2       Tue Sep 27 16:16:10 2016        
```

注意因为当前默认 releases 删除了，针对已卸载的资源是不能再回滚的。

## 'HELM REPO'

Helm3 不再附带默认的 chart 仓库了。`helm repo` 命令集提供添加，列表和移除仓库。

你可以通过 `helm repo list` 查看配置了哪些仓库：

```
$ helm repo list
NAME            URL
stable          https://kubernetes-charts.storage.googleapis.com
mumoshu         https://mumoshu.github.io/charts
```

新的仓库可以通过 `helm repo add` 添加：

```
$ helm repo add dev https://example.com/dev-charts
```

因为 chart 仓库变化比较频繁，可以通过 `helm repo update` 确保 Helm 客户端更新到最新版本。

仓库可以通过 `helm repo remove` 移除。

## 创建你自己的 CHARTS

[Chart Development Guide](https://helm.sh/docs/topics/charts/) 说明了如何开发你自己的 charts。但是你可以通过 `helm create` 命令快速入门：

```
$ helm create deis-workflow
Creating deis-workflow
```

现在在 `./deis-workflow` 有一个 chart。你可以编辑和创建属于你自己的模板。

在编辑 chart 时，可以通过运行 `helm lint` 验证格式是否正确。

当需要打包 chart 以进行分发时，可以运行 `helm package` 命令：

```
$ helm package deis-workflow
deis-workflow-0.1.0.tgz
```

然后现在就可以通过 `helm install` 轻松安装了：

```
$ helm install deis-workflow ./deis-workflow-0.1.0.tgz
...
```

打包的 Charts 可以加载到 chart 仓库。具体参见你的 chart 仓库服务器以学习怎么上传。

注意：`stable` 仓库管理在 [Kubernetes Charts GitHub repository](https://github.com/helm/charts)。这个项目接受 chart 源码，并（审核后）为你打包。


## 结束

这个章节覆盖了 `helm` 客户端基本的使用方式，包括搜索，安装，升级和卸载。它还覆盖了类似 `helm status`，`helm get` 以及 `helm repo` 这样的实用命令。

获取更多的信息，可以通过 `helm help` 获取 Helm 内建的帮助。
