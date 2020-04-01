# Helm3 备忘

## Helm 架构

![](images/helm3-arch.png)

> https://developer.ibm.com/technologies/containers/blogs/kubernetes-helm-3/

### HELM 的目的

Helm 是一个管理 Kubernetes 包 charts 的工具。Helm 可以做以下事情：

+ 从 scratch 创建新的 charts
+ 打包 charts 为归档（tgz）文件
+ 与 chart 仓库进行交互
+ 在已存在的 Kubernetes 集群中安装和卸载 charts
+ 管理已安装 charts 的 release 生命周期

对于 Helm，这里有三个重要的概念：

+ 1、chart 包含创建一个 Kubernetes 应用实例所必要的信息
+ 2、config 包含可以合并到 chart 包创建可发布对象的配置信息
+ 3、release 是 chart 的运行实例，包含指定的配置

### 组件

Helm 是一个由两个不同部分实现的可执行文件：

__The Helm Client__ 是提供终端用户的命令行客户端。客户端负责以下功能：

+ 本地 chart 开发
+ 管理 repositories
+ 管理 releases
+ 对接 Helm library 仓库
    - 发送要安装的 charts
    - 请求升级或者卸载已存在的 releases

__The Helm Library__ 提供了执行所有 Helm 操作的逻辑。它与 Kubernetes API 服务器交互并提供以下功能：

+ 结合 chart 和配置以构建一个 release
+ 在 Kubernetes 中安装 charts，并提供后续的 release 对象
+ 通过与 Kubernetes 交互来升级或者卸载 charts

独立的 Helm library 封装了 Helm 逻辑，以便可以由不同的客户端使用。

### 实现

Helm client 和 library 通过 Go 语言编写。

library 使用 Kubernetes client library 连接 Kubernetes。当前，library 使用 RESET + JSON。它使用 Kubernetes 内部的 Secrets 来存储信息。它不需要自己的数据库

配置文件尽可能以 YAML 编写。

## 快速上手指南

这个指南介绍如何快速上手使用 Helm。

### 前提条件

成功并正确安全的使用 Helm 需要具备如下几个条件：

+ 1、一个 Kubernetes 集群
+ 2、如果有，确定要应用于安装的安全配置
+ 3、安装和配置 Helm

#### 安装 Kubernetes 或者有一个可访问的集群

+ 你必须有一个安装好的 Kubernetes。针对最新版本的 Helm，我们推荐最新稳定版的 Kubernetes，大多数情况下也是第二次新版本
+ 你还需要一个本地 `kubectl` 的配置副本

> 注意：1.6 之前的 Kubernetes 版本对于基于角色的访问控制（RBAC）的支持是受限或者不支持的。

### 安装 Helm

下载 Helm 客户端的二进制版本。你可以通过类似 `homebrew`（macOS 下包管理工具） 的工具，或者[官方版本页](https://github.com/helm/helm/releases)查看。

更详细的信息，或者选项，参见 [安装指南](https://helm.sh/docs/intro/install/)。

> 本身 Helm 的客户端就是一个二进制，安装来说不存在任何难度，不同系统安装不同的二进制版本即可。

### 初始化一个 Helm chart repository

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

### 安装示例 Chart

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

### 了解有关发布（RELEASES）的信息

通过 Helm 很容易看到发布了什么：

```
$ helm ls
NAME             VERSION   UPDATED                   STATUS    CHART
smiling-penguin  1         Wed Sep 28 12:59:46 2016  DEPLOYED  mysql-0.1.0
```

`helm list` 函数展示所有部署的发布列表。

### 卸载一个 RELEASE

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

### 查看帮助文档

使用 `helm help` 或者相关命令和 `-h` 选项组合可以获取更多可用的 Helm 命令：

```
$ helm get -h
```

## 使用 Helm

这份指南介绍在 Kubernetes 集群中使用 Helm 管理包的基础知识。假设你已经安装了 Helm client。

如果你仅对运行一些快捷命令感兴趣，那么可以从 [Quickstart Guide](https://helm.sh/docs/intro/quickstart/) 开始入手。这个章节覆盖了 Helm 命令的细节，并解释如何使用 Helm。

### 三大概念

`Chart` 是 Helm 的包。它包含了在 Kubernetes 集群中运行一个应用、工具或者服务的所有资源的必要定义。好比 Homebrew 的 formula，Apt 的 apkg ，或者 Yum 的 RPM 文件。

`Repository` 是存放收集和共享 charts 的地方。好比 Perl 的 [CPAN archive](https://www.cpan.org/) 或者 Fedora 的 [Package Database](https://admin.fedoraproject.org/pkgdb/)，只是它是针对 Kubernetes 的包。

`Release` 是 chart 运行在 Kubernetes 集群的对应实例。一个 chart 可以在一个相同的集群俺逐行多次。每次安装都创建一个新的 release。以 MySQL chart 为例，如果你想在集群中运行两个数据库，你可以安装这个 chart 两次。每次安装对应一个 release，每个 release 都有对应的名称。

伴随这几个概念，我们现在可以这样解释 Helm：

> Helm 安装 charts 到 Kubernetes 中，每次安装创建一个新的 release。如果要找新的 charts，你可以通过搜索 Helm chart repositories。

### 'HELM SEARCH': 搜索 CHARTS

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

### 'HELM INSTALL'：安装一个包

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

#### 安装前自定义 Chart

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

#### `--set` 格式和限制

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

#### 更多安装的方法

`helm install` 命令可以从多个源安装：

+ chart repository（和上面提到的一样）
+ 本地 chart 归档（`helm install foo foo-0.1.1.tgz`）
+ 解包的 chart 目录（`helm install foopath/to/foo`）
+ 完整的 URL（`helm install foo https://example.com/charts/foo-1.2.3.tgz`）

### 'HELM UPGRADE' 和 'HELM ROLLBACK': 升级和失败恢复 RELEASE

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

### INSTALL/UPGRADE/ROLLBACK 帮助项

这里有几个其他有用的选项，以便当使用 Helm 执行 install/upgrade/rollback 时自定义操作。请注意这不是一个完整的客户端参数。查看所有参数的描述，运行 `helm <command> --help`。

+ `--timeout`：指定等待 Kubernetes 命令完成时间，默认 5m0s
+ `--wait`：等待直到所有的 Pods 处于 Ready 状态，PVCs bound，Deployments 达到最低限度（Desired - maxUnavailable）的 Pods 处于 Ready 状态以及 Service 有一个 IP 地址（并且 Ingress 如果需要 `LoadBalancer`）时，才标记 release 成功。等待的时间受 `--timeout` 值限制。如果超时了，则 release 会被标记为 `FAILED`。注意：在 Deployment `replicas` 设置为 1，滚动更新策略 `maxUnavailable` 没有被设置为 0 时，`--wait` 会返回 ready，因为它已经满足 ready 条件中的最小 Pod 数。
+ `--no-hooks`：跳过执行钩子

### 'HELM UNINSTALL'：卸载一个 RELEASE

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

### 'HELM REPO'

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

### 创建你自己的 CHARTS

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


### 结束

这个章节覆盖了 `helm` 客户端基本的使用方式，包括搜索，安装，升级和卸载。它还覆盖了类似 `helm status`，`helm get` 以及 `helm repo` 这样的实用命令。

获取更多的信息，可以通过 `helm help` 获取 Helm 内建的帮助。

## Helm Commands

### Helm Completion

helm 命令补全，类似 `kubectl completion`

```
source <(helm completion bash)
```

> 建议把以上命令根据实际的 shell 加入到对应的配置文件中永久生效，如 bash 为 `~/.bashrc`，zsh 则为 `~/.zshrc`

### Helm Create

根据给定的名字创建一个新的 chart

```
# helm create test
Creating test
# tree -aF test
test
├── charts/                         // 可选，用于存放当前 Chart 依赖的其它 Chart 的说明文件
├── Chart.yaml                      // 用于描述 Chart 的元数据信息
├── .helmignore                     // Helm charts 打包时要忽略的信息，类似 .gitignore 和 .dockerignore
├── templates/                      // 可选，模板文件目录
│   ├── deployment.yaml
│   ├── _helpers.tpl
│   ├── ingress.yaml
│   ├── NOTES.txt
│   ├── serviceaccount.yaml
│   ├── service.yaml
│   └── tests/                      // 测试文件
│       └── test-connection.yaml
└── values.yaml                     // 模板默认值

3 directories, 10 files
```

### Helm Dependency

管理 chart 依赖

例如，这个 Chart.yaml 声明了两个依赖：

```
# Chart.yaml
dependencies:
- name: nginx
  version: "1.2.3"
  repository: "https://example.com/charts"
- name: memcached
  version: "3.2.1"
  repository: "https://another.example.com/charts"
```

也可以通过 `file://` 方式指定本地地址

```
# Chart.yaml
dependencies:
- name: nginx
  version: "1.2.3"
  repository: "file://../dependency_chart/nginx"
```

#### Helm Dependency build

基于 Chart.lock 文件重新构建 charts/ 目录，选择一个 chart 目录执行命令：

```
# helm dependency build
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "incubator" chart repository
...Successfully got an update from the "stable" chart repository
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 1 charts
Downloading nginx from repo https://charts.bitnami.com/bitnami
Deleting outdated charts
```

> 如果没有 Chart.lock 文件，该命令会同 `helm dependency update` 一样创建此文件

```
# cat  Chart.lock
dependencies:
- name: nginx
  repository: https://charts.bitnami.com/bitnami
  version: 5.1.7
digest: sha256:3c3b4389ddb5d3ff6ef489d49713a369ec9d8474d04a8591f4be9ee78a122bc9
generated: "2020-03-05T15:30:02.76679778+08:00"
```

> 如果 Chart.yaml 变更了，Chart.lock 文件没有更新，则 `helm dependency build` 命令会执行失败，需要先执行 update 操作

```
# helm dependency build
Error: the lock file (Chart.lock) is out of sync with the dependencies file (Chart.yaml). Please update the dependencies
```

#### Helm Dependency list 

列出给定 chart 的依赖信息：

```
# helm dependency list
NAME    VERSION REPOSITORY                              STATUS
nginx   5.1.7   https://charts.bitnami.com/bitnami      ok
# rm -f charts/nginx-5.1.7.tgz
# helm dependency list
NAME    VERSION REPOSITORY                              STATUS
nginx   5.1.7   https://charts.bitnami.com/bitnami      missing
```

#### Helm Dependency update

基于 Chart.yaml 内容更新 charts/

```
# helm dependency update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "incubator" chart repository
...Successfully got an update from the "stable" chart repository
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 2 charts
Downloading nginx from repo https://charts.bitnami.com/bitnami
Downloading mysql from repo https://charts.bitnami.com/bitnami
Deleting outdated charts
# cat Chart.lock                // update 命令会同步更新 Chart.lock
dependencies:
- name: nginx
  repository: https://charts.bitnami.com/bitnami
  version: 5.1.7
- name: mysql
  repository: https://charts.bitnami.com/bitnami
  version: 6.9.2
digest: sha256:8a9ccbc57ff8e49cd5d788b736a0daeba182afe714721d1e5d17f13384935a6a
generated: "2020-03-05T15:44:24.017928459+08:00"
```

### Helm Env

打印出 Helm 所有在使用的环境变量

```
# helm env
HELM_BIN="helm"
HELM_DEBUG="false"
HELM_KUBECONTEXT=""
HELM_NAMESPACE="default"
HELM_PLUGINS="/root/.local/share/helm/plugins"
HELM_REGISTRY_CONFIG="/root/.config/helm/registry.json"
HELM_REPOSITORY_CACHE="/root/.cache/helm/repository"
HELM_REPOSITORY_CONFIG="/root/.config/helm/repositories.yaml"
```

### Helm Get

获取 release 扩展信息

```
# helm get -h

This command consists of multiple subcommands which can be used to
get extended information about the release, including:

- The values used to generate the release
- The generated manifest file
- The notes provided by the chart of the release
- The hooks associated with the release

Usage:
  helm get [command]

Available Commands:
  all         download all information for a named release  // 所有的信息
  hooks       download all hooks for a named release        // hooks 相关
  manifest    download the manifest for a named release     // 主要是 K8s 资源信息，Deployment、ConfigMap 等等
  notes       download the notes for a named release        // 注解
  values      download the values file for a named release  // 变量内容
```

```
# helm get hooks helm-grafana
---
# Source: grafana/templates/tests/test.yaml
apiVersion: v1
kind: Pod
metadata:
  name: helm-grafana-test
  labels:
    helm.sh/chart: grafana-5.0.4
    app.kubernetes.io/name: grafana
    app.kubernetes.io/instance: helm-grafana
    app.kubernetes.io/version: "6.6.2"
    app.kubernetes.io/managed-by: Helm
  annotations:
    "helm.sh/hook": test-success
  namespace: default
spec:
  serviceAccountName: helm-grafana-test
  containers:
    - name: helm-grafana-test
      image: "bats/bats:v1.1.0"
      command: ["/opt/bats/bin/bats", "-t", "/tests/run.sh"]
      volumeMounts:
        - mountPath: /tests
          name: tests
          readOnly: true
  volumes:
  - name: tests
    configMap:
      name: helm-grafana-test
  restartPolicy: Never
```

### Helm History

获取 release 历史

```
# helm history helm-grafana
REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION
1               Tue Mar  3 15:12:14 2020        deployed        grafana-5.0.4   6.6.2           Install complete
```

### Helm Install

安装一个 chart，官方示例如下：

```
$ helm install -f myvalues.yaml myredis ./redis
$ helm install --set name=prod myredis ./redis
$ helm install --set-string long_int=1234567890 myredis ./redis
$ helm install -f myvalues.yaml -f override.yaml  myredis ./redis
$ helm install --set foo=bar --set foo=newbar  myredis ./redis
```

### Helm Lint

Helm chart lint 命令，验证 chart 格式是否正确。

```
# helm lint
==> Linting .
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

### Helm List

releases 列表

默认只列出已经部署或者失败的 release，`--uninstalled` 和 `--all` 选项可以列出更多，还可以采用 `--uninstalled --failed` 组合模式。通过 `--filter` 还可以支持搜索正则。

```
$ helm list --filter 'ara[a-z]+'
NAME                UPDATED                     CHART
maudlin-arachnid    Mon May  9 16:07:08 2016    alpine-0.1.0
```

```
# helm list -h
...
Usage:
  helm list [flags]

Aliases:
  list, ls

Flags:
  -a, --all              show all releases without any filter applied
  -A, --all-namespaces   list releases across all namespaces
  -d, --date             sort by release date
      --deployed         show deployed releases. If no other is specified, this will be automatically enabled
      --failed           show failed releases
  -f, --filter string    a regular expression (Perl compatible). Any releases that match the expression will be included in the results
  -h, --help             help for list
  -m, --max int          maximum number of releases to fetch (default 256) // 设置 0 并不会显示所有的，会使用服务器的默认值，该值可能高于 256
      --offset int       next release name in the list, used to offset from start value
  -o, --output format    prints the output in the specified format. Allowed values: table, json, yaml (default table)
      --pending          show pending releases
  -r, --reverse          reverse the sort order
  -q, --short            output short (quiet) listing format
      --superseded       show superseded releases
      --uninstalled      show uninstalled releases (if 'helm uninstall --keep-history' was used)
      --uninstalling     show releases that are currently being uninstalled
...
```

### Helm Package

把一个 chart 目录归档

```
# helm package test/
Successfully packaged chart and saved it to: /root/shuihan/test-0.1.0.tgz
```

```
# helm package -h
...
Usage:
  helm package [CHART_PATH] [...] [flags]

Flags:
      --app-version string   set the appVersion on the chart to this version
  -u, --dependency-update    update dependencies from "Chart.yaml" to dir "charts/" before packaging
  -d, --destination string   location to write the chart. (default ".")
  -h, --help                 help for package
      --key string           name of the key to use when signing. Used if --sign is true
      --keyring string       location of a public keyring (default "/root/.gnupg/pubring.gpg")
      --sign                 use a PGP private key to sign this package
      --version string       set the version on the chart to this semver version
...
```

### Helm Plugin

安装、列表或者卸载 Helm plugins

```
# helm plugin -h

Manage client-side Helm plugins.

Usage:
  helm plugin [command]

Available Commands:
  install     install one or more Helm plugins
  list        list installed Helm plugins
  uninstall   uninstall one or more Helm plugins
  update      update one or more Helm plugins

Flags:
  -h, --help   help for plugin
...
```

### Helm Pull

从仓库下载一个 chart 并（可选）解包在本地目录下。

```
# helm pull bitnami/nginx
```

```
# helm pull -h
...
Usage:
  helm pull [chart URL | repo/chartname] [...] [flags]

Aliases:
  pull, fetch

Flags:
      --ca-file string       verify certificates of HTTPS-enabled servers using this CA bundle
      --cert-file string     identify HTTPS client using this SSL certificate file
  -d, --destination string   location to write the chart. If this and tardir are specified, tardir is appended to this (default ".")
      --devel                use development versions, too. Equivalent to version '>0.0.0-0'. If --version is set, this is ignored.
  -h, --help                 help for pull
      --key-file string      identify HTTPS client using this SSL key file
      --keyring string       location of public keys used for verification (default "/root/.gnupg/pubring.gpg")
      --password string      chart repository password where to locate the requested chart
      --prov                 fetch the provenance file, but don't perform verification
      --repo string          chart repository url where to locate the requested chart
      --untar                if set to true, will untar the chart after downloading it
      --untardir string      if untar is specified, this flag specifies the name of the directory into which the chart is expanded (default ".")
      --username string      chart repository username where to locate the requested chart
      --verify               verify the package before installing it
      --version string       specify the exact chart version to install. If this is not specified, the latest version is installed
...
```

### Helm Repo

添加、列表、移除、更新以及索引 chart 仓库

```
# helm repo -h

This command consists of multiple subcommands to interact with chart repositories.

It can be used to add, remove, list, and index chart repositories.

Usage:
  helm repo [command]

Available Commands:
  add         add a chart repository
  index       generate an index file given a directory containing packaged charts
  list        list chart repositories
  remove      remove a chart repository
  update      update information of available charts locally from chart repositories
...
```

```
# helm repo list
NAME            URL
incubator       http://storage.googleapis.com/kubernetes-charts-incubator
bitnami         https://charts.bitnami.com/bitnami
# helm repo remove bitnami
"bitnami" has been removed from your repositories
# helm repo add bitnami https://charts.bitnami.com/bitnami
"bitnami" has been added to your repositories
# helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "stable" chart repository
...Successfully got an update from the "incubator" chart repository
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈ Happy Helming!⎈
```

`helm repo index` 用于给 chart 仓库目录生成 `index.yaml` 文件索引。

```
# helm repo index -h

Read the current directory and generate an index file based on the charts found.

This tool is used for creating an 'index.yaml' file for a chart repository. To
set an absolute URL to the charts, use '--url' flag.

To merge the generated index with an existing index file, use the '--merge'
flag. In this case, the charts found in the current directory will be merged
into the existing index, with local charts taking priority over existing charts.

Usage:
  helm repo index [DIR] [flags]

Flags:
  -h, --help           help for index
      --merge string   merge the generated index into the given index
      --url string     url of chart repository
```

### Helm Rollback

release 版本回滚

```
# helm rollback -h

This command rolls back a release to a previous revision.

The first argument of the rollback command is the name of a release, and the
second is a revision (version) number. If this argument is omitted, it will
roll back to the previous release.

To see revision numbers, run 'helm history RELEASE'.

Usage:
  helm rollback <RELEASE> [REVISION] [flags]

Flags:
      --cleanup-on-fail    allow deletion of new resources created in this rollback when rollback fails
      --dry-run            simulate a rollback
      --force              force resource update through delete/recreate if needed
  -h, --help               help for rollback
      --no-hooks           prevent hooks from running during rollback
      --recreate-pods      performs pods restart for the resource if applicable
      --timeout duration   time to wait for any individual Kubernetes operation (like Jobs for hooks) (default 5m0s)
      --wait               if set, will wait until all Pods, PVCs, Services, and minimum number of Pods of a Deployment, StatefulSet, or ReplicaSet are in a ready state before marking the release as successful. It will wait for as long as --timeout
```

### Helm Search

charts 搜索

```
# helm search

Search provides the ability to search for Helm charts in the various places
they can be stored including the Helm Hub and repositories you have added. Use
search subcommands to search different locations for charts.

Usage:
  helm search [command]

Available Commands:
  hub         search for charts in the Helm Hub or an instance of Monocular // https://hub.helm.sh/
  repo        search repositories for a keyword in charts
```

### Helm Show

展示 chart 信息

```
# helm show

This command consists of multiple subcommands to display information about a chart

Usage:
  helm show [command]

Aliases:
  show, inspect

Available Commands:
  all         shows all information of the chart
  chart       shows the chart's definition
  readme      shows the chart's README
  values      shows the chart's values
```

### Helm Status

显示 release 状态信息

```
# helm status helm-grafana
NAME: helm-grafana
LAST DEPLOYED: Tue Mar  3 15:12:14 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
1. Get your 'admin' user password by running:

   kubectl get secret --namespace default helm-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

2. The Grafana server can be accessed via port 80 on the following DNS name from within your cluster:

   helm-grafana.default.svc.cluster.local

   Get the Grafana URL to visit by running these commands in the same shell:

     export POD_NAME=$(kubectl get pods --namespace default -l "app=grafana,release=helm-grafana" -o jsonpath="{.items[0].metadata.name}")
     kubectl --namespace default port-forward $POD_NAME 3000

3. Login with the password from step 1 and the username: admin
#################################################################################
######   WARNING: Persistence is disabled!!! You will lose your data when   #####
######            the Grafana pod is terminated.                            #####
#################################################################################
```

### Helm Template

本地渲染模板

通过 helm 自定义选项并输出。

```
# helm template test bitnami/grafana --set-string image.tag=5.0.4       // 修改镜像 tag
```

### Helm Test

针对已部署的 release 运行测试，这些测试在已安装 chart 中定义好了。

### Helm Uninstall

卸载一个 release

```
# helm uninstall helm-grafana
release "helm-grafana" uninstalled
```

### Helm Upgrade

release 升级

```
$ helm upgrade -f myvalues.yaml -f override.yaml redis ./redis
$ helm upgrade --set foo=bar --set foo=newbar redis ./redis
```

### Helm Verify

验证指定的 chart 已签名并且有效

### Helm Version

查看 helm 版本信息

```
# helm version
version.BuildInfo{Version:"v3.1.1", GitCommit:"afe70585407b420d0097d07b21c47dc511525ac8", GitTreeState:"clean", GoVersion:"go1.13.8"}
```
