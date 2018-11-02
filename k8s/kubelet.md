# Kubelet

## 配置项

```
[root@k8s bin]# ./kubelet --version
Kubernetes v1.7.3
[root@k8s bin]# ./kubelet --help
Usage of ./kubelet:
      --address ip        The IP address for the Kubelet to serve on (set to 0.0.0.0 for all interfaces) (default 0.0.0.0)
      --allow-privileged  If true, allow containers to request privileged mode.
      ... ...
```

### 配置说明

#### 基本配置项

| 选项 | 说明  |
| :-- | :--  |
| --address ip | kubelet 监听地址，默认 `0.0.0.0`，表示监听在所有网络接口 |
| --allow-privileged | 如果值为 `true` 则允许容器请求 `privileged` 选项，默认 `false` |
| --cadvisor-port int32 | 指定 cAdvisor 端口， 默认 `4194` |
| --cluster-dns stringSlice | 指定集群 DNS 服务地址列表，通过逗号分隔，用于 Pod 设置项 `dnsPolicy=ClusterFirst` 的容器 DNS 服务器。 |
| --cpu-cfs-quota | 启用 CPU CFS 配额用于容器 CPU 资源限制，默认 `true` |
| --kubeconfig string | kubeconfig 文件路径, 指定如何连接 API server。除非 `--require-kubeconfig` 选项设置了，否则使用 `--api-servers`。 默认 `"/var/lib/kubelet/kubeconfig"` |
| --http-check-frequency duration | http check 时间间隔，默认 `20s` |
| --kube-api-burst int32  | Burst 用于 kubelet 与 apiserver 通信限制，默认 `10` |
| --kube-api-content-type string | 指定发送请求给 apiserver 的通信内容类型，默认 `"application/vnd.kubernetes.protobuf"` |
| --kube-api-qps int32 | QPS 用于 kubelet 与 apiserver 通信限制，默认 `5` |
| --max-pods int32 | 当前 Kubelet 节点上可以运行的最大 pod 数，默认 `110` |
| --max-open-files int | kubelet 进程最大打开文件句柄数, 默认 `1000000` |
| --node-labels mapStringString | <警告：Alpha 特性> 当启动时注册到 apiserver 的标签，标签必须 `key=value` 键值对，以逗号分隔 |
| --pod-infra-container-image string |  pod 中容器共享的 `network/ipc` 命名空间基础组件镜像，默认 `"gcr.io/google_containers/pause-amd64:3.0"` |
| --port int32 | kubelet 监听端口，默认 `10250` |
| --require-kubeconfig | 如果设置为 `true`，则配置不存在 Kubelet 进程会退出, 并且会忽略 `--api-servers` 选项 |
| -read-only-port int32 | kubelet 只读端口，一般用于 metrics 信息获取，设置为 0 表示禁用，默认 `10255` |
| --resolv-conf string | DNS 解析文件指定，默认为 `"/etc/resolv.conf"` |
| --root-dir string | 用于管理 kubelet 文件（volume mounts 等）目录路径，默认 `"/var/lib/kubelet"` |

#### 认证配置项

| 选项 | 说明  |
| :-- | :--  |
| --anonymous-auth | 启用对 kubelet 服务的匿名请求，匿名请求的用户名为 `system:anonymous`，组名为 `system:unauthenticated`，默认为 `true` |
| --authorization-mode string | kubelet 授权方式，可用选项包括 `AlwaysAllow` 和 `Webhook`，`Webhook` 通过 SubjectAccessReview API 确认授权，默认 `"AlwaysAllow"` |
| --bootstrap-kubeconfig string | Path to a kubeconfig file that will be used to get client certificate for kubelet. If the file specified by --kubeconfig does not exist, the bootstrap kubeconfig is used to request a client certificate from the API server. On success, a kubeconfig file referencing the generated client certificate and key is written to the path specified by --kubeconfig. The client certificate and key file will be stored in the directory pointed by --cert-dir. |
| --cert-dir string | TLS certs 证书目录，如果同时指定 `--tls-cert-file` 和 `--tls-private-key-file` 则该参数会被忽略。 默认 `"/var/run/kubernetes"`|
| --client-ca-file string | If set, any request presenting a client certificate signed by one of the authorities in the client-ca-file is authenticated with an identity corresponding to the CommonName of the client certificate. |
| --tls-cert-file string | 包含 x509 证书的文件路径，用于提供 HTTPS 服务，如果未提供 `--tls-cert-file` 和 `--tls-private-key-file`，则会为公用地址生成自签名证书和密钥，并保存到 `--cert-dir` 目录 |
| --tls-private-key-file string | 包含 X509 匹配 `--tls-cert-file` 私钥的文件路径 |

#### 日志配置项

| 选项 | 说明  |
| :-- | :--  |
| --alsologtostderr | 日志输出到文件同时输出到 stderr |
| --log-backtrace-at traceLocation | when logging hits line file:N, emit a stack trace (default `:0`) |
| --log-cadvisor-usage | 记录 cadvisor 运行日志 |
| --log-dir string | 如果非空，则输出日志到指定目录 |
| --log-flush-frequency duration | 日志刷新的最大间隔秒数，默认 `5s` |
| --logtostderr | 日志输出到标准错误输出而不是文件，默认值为 `true` |
| --stderrthreshold severity | 超过此阈值的日志将转到 stderr，默认为 `2` |
| -v, --v Level | log level for V logs |

#### Docker 配置项

| 选项 | 说明  |
| :-- | :--  |
| --container-runtime string | 选择容器运行类型，`docker` 和 `rkt` 值可供选择，默认 `"docker"` |
| --docker string | docker endpoint 设置，默认为 `"unix:///var/run/docker.sock"` |
| --docker-disable-shared-pid | 当使用 Docker 1.13.1 或更高版本运行时，容器运行时接口（CRI）针对一个 pod 中的容器间默认为共享 PID 命名空间。通过设置此标志可以达到 pod 间容器 PID 命名空间互相隔离。此功能将在未来的 Kubernetes 版本中被删除 |
| --docker-endpoint string | 同 `--docker`，默认为 `"unix:///var/run/docker.sock"` |
| --docker-exec-handler string | 容器中执行命令 Handler 指定，有 `"native"` 和 `"nsenter"` 可选，默认 `"native"` |
| --docker-only | 除了根信息统计之外，只报告 docker 容器统计数据 |

#### 镜像配置项

| 选项 | 说明  |
| :-- | :--  |
| --image-gc-high-threshold int32 | 当磁盘使用率达到该百分比后会一直运行镜像 GC 机制，默认 `85` |
| --image-gc-low-threshold int32 | 在磁盘使用率没有达到该百分比之前，不触发镜像 GC 机制，默认 `80` |
| --image-pull-progress-deadline duration | 如果指定时间 pull 镜像没有任何进度，则取消 pull，默认 `1m0s` |
| --minimum-image-ttl-duration duration | 在镜像 GC 之前未使用的镜像最小时间值。 例如 `300ms`, `10s` 或者 `2h45m`，默认 `2m0s` |
| --registry-burst int32 |  最高 pull 数限制, 实际值依然受 `registry-qps`限制，不能超过该值，并且只有 `--registry-qps > 0` 才生效，默认 `10` |
| --registry-qps int32 | 如果 > 0, 限制 registry pull QPS 为指定值，如果为 0, 则不限制，默认 `5` |
| --serialize-image-pulls | 一次只 pull 一个镜像。在 docker daemon 版本 < 1.9 或者使用 Aufs 存储驱动的时候不建议修改默认值。具体可以参见 Issue #10959，默认 `true` |

#### 网络配置项

| 选项 | 说明  |
| :-- | :--  |
| --cni-bin-dir string | <警告: Alpha 特性> 指定搜索 CNI plugin binaries 的目录绝对路径，默认 `"/opt/cni/bin"` |
| --cni-conf-dir string | <警告: Alpha 特性> 指定搜索 CNI 配置文件的目录绝对路径，默认 `"/etc/cni/net.d"` |
| --network-plugin string | <警告: Alpha 特性> 指定网络插件名称，如 `"--network-plugin=cni"` 指定使用 `cni` 插件 |
| --network-plugin-mtu int32 | <警告: Alpha 特性> 通过网络插件传值 MTU，覆盖系统默认值。 如果设置为 0 则默认使用 `1460` MTU. |

#### Volume 卷配置项

| 选项 | 说明  |
| :-- | :--  |
| --enable-controller-attach-detach | 启用 `Attach/Detach` controller 管理调度到该节点的 volume 卷 `attachment/detachment` 操作，并且禁用 kubelet 执行任何 `attach/detach` 操作，默认 `true` |
| --keep-terminated-pod-volumes | 在 pod 终止后，将终止的 pod 卷在节点保留，可用于调试卷相关的问题 |
| --volume-plugin-dir string | <警告: Alpha 特性> 指定搜索其他第三方卷插件的目录绝对路径 ，默认 `"/usr/libexec/kubernetes/kubelet-plugins/volume/exec/"` |
| --volume-stats-agg-period duration |  指定 kubelet 所有 pod 统计以及缓存卷磁盘使用率的时间间隔。如果要禁用，设置该值为 0 即可，默认 `1m0s` |

#### cgroup/namespace 配置项

| 选项 | 说明  |
| :-- | :--  |
| --cgroup-driver string | kubelet 操作主机 cgroups 驱动选择，`cgroupfs` 和 `systemd` 值可供选择，默认 `"cgroupfs"`。__CentOS 7 设置为 `"systemd"`__ |
| --cgroup-root string | 针对 pod 可选项 root cgroup，默认 `''`，表示使用容器运行时的默认值 |
| --cgroups-per-qos | Enable creation of QoS cgroup hierarchy, if true top level QoS and pod cgroups are created. 默认 `true` |
| --host-ipc-sources stringSlice | 指定允许使用主机 ipc namespace pod 列表，默认 `[*]`，逗号分隔 |
| --host-network-sources stringSlice | 指定允许使用 host network 的 pod，默认 `[*]`，逗号分隔 |
| --host-pid-sources stringSlice |指定允许使用主机 pid namespace pod 列表，默认 `[*]`，逗号分隔 |
| --kube-reserved-cgroup string | Absolute name of the top level cgroup that is used to manage kubernetes components for which compute resources were reserved via '--kube-reserved' flag. Ex. '/kube-reserved'. 默认 `''` |
| --kubelet-cgroups string | Optional absolute name of cgroups to create and run the Kubelet in. |
| --runtime-cgroups string | Optional absolute name of cgroups to create and run the runtime in. |
| --system-cgroups / | Optional absolute name of cgroups in which to place all non-kernel processes that are not already inside a cgroup under /. Empty for no container. Rolling back the flag requires a reboot. |
| --system-reserved-cgroup string | Absolute name of the top level cgroup that is used to manage non-kubernetes components for which compute resources were reserved via '--system-reserved' flag. Ex. '/system-reserved'.  默认 `''` |

> **[info] 标注**  
> cgroup 相关选项有些笔者没有深入相关调研，建议使用默认值即可

#### event 配置项

| 选项 | 说明  |
| :-- | :--  |
| --event-burst int32 | Maximum size of a bursty event records, temporarily allows event records to burst to this number, while still not exceeding event-qps. Only used if --event-qps > 0 (default 10) |
| --event-qps int32 | If > 0, limit event creations per second to this value. If 0, unlimited. (default 5) |
| --event-storage-age-limit string | Max length of time for which to store events (per type). Value is a comma separated list of key values, where the keys are event types (e.g.: creation, oom) or "default" and the value is a duration. Default is applied to all non-specified event types (default "default=0") |
| --event-storage-event-limit string | Max number of events to store (per type). Value is a comma separated list of key values, where the keys are event types (e.g.: creation, oom) or "default" and the value is an integer. Default is applied to all non-specified event types (default "default=0") |

> **[info] 标注**  
> event 配置项笔者也没有进行相关设置，建议使用默认值即可

#### Pod `eviction` 配置项

| 选项 | 说明  |
| :-- | :--  |
| --eviction-soft string | pod eviction 阈值软限制（例如 `"memory.available<1.5Gi"`），如果超过 grace period 则会触发 pod 驱逐机制 |
| --eviction-soft-grace-period string | 设置 eviction grace periods（例如 `"memory.available=1m30s"`），对应达到 pod eviction 软阈值时，触发 pod eviction 所需要等待的时间 |
| --eviction-max-pod-grace-period int32 | 当达到 pod eviction 软阈值的时候，terminating pods 最长允许的 grace period (in seconds)。如果为负数, 则取决于 pod 实际指定的值。默认全局的一个 grace period 为 `30s` 详见 [Termination of Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod/#termination-of-pods) |
| --eviction-hard string | pod eviction 阈值硬限制（例如  `"memory.available<1Gi"`），如果达到该值则会触发 `pod eviction`，默认为 `"memory.available<100Mi"` |
| --eviction-minimum-reclaim string | 最小回收值设置，（例如 `"imagefs.available=2Gi"`），表示当 kubelet 资源处于压力状态下执行 pod eviction 时回收的最小资源量 |
| --eviction-pressure-transition-period duration | 在转移 eviction pressure 条件前，kubelet 需要等待的时间，默认 `5m0s`) |

关于 kubelet eviction 策略可参考：

* [Eviction Policy](https://kubernetes.io/docs/tasks/administer-cluster/out-of-resource/#eviction-policy)
* [Learn how kubelet eviction policies impact cluster rebalancing](https://blog.kublr.com/learn-how-kubelet-eviction-policies-impact-cluster-rebalancing-2e976ebc53ea)

### 推荐配置项

__/etc/kubernetes/kubelet__

```
###
# kubernetes kubelet config

# The address for the info server to serve on (set to 0.0.0.0 or "" for all interfaces)
KUBELET_ADDRESS="--address=0.0.0.0"

# The port for the info server to serve on
KUBELET_PORT="--port=10250"

# You may leave this blank to use the actual hostname 根据实际需求填写，默认主机名
KUBELET_HOSTNAME="--hostname-override=<hostname>"

# location of the api-server 根据实际需求填写，后续该配置会被废弃，--kubeconfig 替换
KUBELET_API_SERVER="--api-servers=http://<apiserver>:8080"

# pod infrastructure container 建议把 pause 组件 push 到私有内部镜像
KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=<private_registry>/google_containers/pause-amd64:3.0"

# Add your own! --cluster-dns 根据实际选项填写
KUBELET_ARGS="--cluster-dns=<kubedns-ip> --image-gc-high-threshold=85 --image-gc-low-threshold=70 --serialize-image-pulls=false --cgroup-driver=systemd --fail-swap-on=false --max-pods=50 --container-runtime=docker --cloud-provider="""
```
