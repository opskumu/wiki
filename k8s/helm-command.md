# Helm Commands

## Helm Completion

helm 命令补全，类似 `kubectl completion`

```
source <(helm completion bash)
```

> 建议把以上命令根据实际的 shell 加入到对应的配置文件中永久生效，如 bash 为 `~/.bashrc`，zsh 则为 `~/.zshrc`

## Helm Create

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

## Helm Dependency

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

### Helm Dependency build

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

### Helm Dependency list 

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

### Helm Dependency update

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

## Helm Env

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

## Helm Get

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

## Helm History

获取 release 历史

```
# helm history helm-grafana
REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION
1               Tue Mar  3 15:12:14 2020        deployed        grafana-5.0.4   6.6.2           Install complete
```

## Helm Install

安装一个 chart，官方示例如下：

```
$ helm install -f myvalues.yaml myredis ./redis
$ helm install --set name=prod myredis ./redis
$ helm install --set-string long_int=1234567890 myredis ./redis
$ helm install -f myvalues.yaml -f override.yaml  myredis ./redis
$ helm install --set foo=bar --set foo=newbar  myredis ./redis
```

## Helm Lint

Helm chart lint 命令，验证 chart 格式是否正确。

```
# helm lint
==> Linting .
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

## Helm List

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

## Helm Package

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

## Helm Plugin

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

## Helm Pull

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

## Helm Repo

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

## Helm Rollback

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

## Helm Search

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

## Helm Show

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

## Helm Status

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

## Helm Template

本地渲染模板

通过 helm 自定义选项并输出。

```
# helm template test bitnami/grafana --set-string image.tag=5.0.4       // 修改镜像 tag
```

## Helm Test

针对已部署的 release 运行测试，这些测试在已安装 chart 中定义好了。

## Helm Uninstall

卸载一个 release

```
# helm uninstall helm-grafana
release "helm-grafana" uninstalled
```

## Helm Upgrade

release 升级

```
$ helm upgrade -f myvalues.yaml -f override.yaml redis ./redis
$ helm upgrade --set foo=bar --set foo=newbar redis ./redis
```

## Helm Verify

验证指定的 chart 已签名并且有效

## Helm Version

查看 helm 版本信息

```
# helm version
version.BuildInfo{Version:"v3.1.1", GitCommit:"afe70585407b420d0097d07b21c47dc511525ac8", GitTreeState:"clean", GoVersion:"go1.13.8"}
```
