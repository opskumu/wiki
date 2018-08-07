# Calico

> 基于版本为 Calico v2.6.x「当前官方最新版本为 v3.0 [Calico Reference](https://docs.projectcalico.org/v3.0/reference/)」

## calicoctl

`calicoctl` 是 calico 网络命令行管理工具。

### 概览

```
# calicoctl --help
Usage:
  calicoctl [options] <command> [<args>...]

    create    Create a resource by filename or stdin.   
              // 从标准输入或者文件创建资源
    replace   Replace a resource by filename or stdin.  
              // 从标准输入或者文件更新资源
    apply     Apply a resource by filename or stdin.  This creates a resource
              if it does not exist, and replaces a resource if it does exists.
              // 从标准输入或者文件应用资源，如果资源存在则更新「Replace」，不在则创建 「Create」
    delete    Delete a resource identified by file, stdin or resource type and
              name.
              // 从文件、标准输出或者资源类型和名字删除资源
    get       Get a resource identified by file, stdin or resource type and
              name.
              // 通过文件、标准输入或者资源类型和名字获取定义的资源
    config    Manage system-wide and low-level node configuration options.
              // 管理系统层和较低级别的节点配置选项
    ipam      IP address management.
              // IP 地址管理
    node      Calico node management.
              // Calico 节点管理
    version   Display the version of calicoctl.
              // 显示 calicoctl 版本

Options:
  -h --help               Show this screen.
  -l --log-level=<level>  Set the log level (one of panic, fatal, error,
                          warn, info, debug) [default: panic]
                          // 设置日志级别
```

### create

```
# calicoctl create --help
Set the Calico datastore access information in the environment variables or
or supply details in a config file.

Usage:
  calicoctl create --filename=<FILENAME> [--skip-exists] [--config=<CONFIG>]

Examples:
  # Create a policy using the data in policy.yaml.
  # 通过 yaml 文件创建对应资源
  calicoctl create -f ./policy.yaml

  # Create a policy based on the JSON passed into stdin.
  # 通过传递 json 内容到标准输出创建对应资源
  cat policy.json | calicoctl create -f -

Options:
  -h --help                 Show this screen.
  -f --filename=<FILENAME>  Filename to use to create the resource.  If set to
                            "-" loads from stdin.
     --skip-exists          Skip over and treat as successful any attempts to
                            create an entry that already exists.
  -c --config=<CONFIG>      Path to the file containing connection
                            configuration in YAML or JSON format.
                            [default: /etc/calico/calicoctl.cfg]
... ...
Valid resource types are:

  * node
  * bgpPeer
  * hostEndpoint
  * workloadEndpoint
  * ipPool
  * policy
  * profile
... ...
```

> v3.0 中新增了 `-n --namespace=<NS>` 选项

### replace

使用选项同 `create`，`replace` 用于更新，如果资源对象不存在则抛错。

### apply

使用选项同 `create`，`apply` 执行时如果资源不存在则创建该资源对象，如果存在则更新。

### delete

```
# calicoctl delete --help
Set the Calico datastore access information in the environment variables or
or supply details in a config file.

Usage:
  calicoctl delete ([--scope=<SCOPE>] [--node=<NODE>] [--orchestrator=<ORCH>]
                    [--workload=<WORKLOAD>] (<KIND> [<NAME>]) |
                   --filename=<FILE>)
                   [--skip-not-exists] [--config=<CONFIG>]

Examples:
  # Delete a policy using the type and name specified in policy.yaml.
  calicoctl delete -f ./policy.yaml

  # Delete a policy based on the type and name in the YAML passed into stdin.
  cat policy.yaml | calicoctl delete -f -

  # Delete policy with name "foo"
  calicoctl delete policy foo

Options:
  -h --help                 Show this screen.
  -s --skip-not-exists      Skip over and treat as successful, resources that
                            don't exist.
  -f --filename=<FILENAME>  Filename to use to delete the resource.  If set to
                            "-" loads from stdin.
  -n --node=<NODE>          The node (this may be the hostname of the compute
                            server if your installation does not explicitly set
                            the names of each Calico node).
     --orchestrator=<ORCH>  The orchestrator (valid for workload endpoints).
     --workload=<WORKLOAD>  The workload (valid for workload endpoints).
     --scope=<SCOPE>        The scope of the resource type.  One of global,
                            node.  This is only valid for BGP peers and is used
                            to indicate whether the peer is a global peer or
                            node-specific.
  -c --config=<CONFIG>      Path to the file containing connection
                            configuration in YAML or JSON format.
                            [default: /etc/calico/calicoctl.cfg]
... ...
Valid resource types are:

  * node
  * bgpPeer
  * hostEndpoint
  * workloadEndpoint
  * ipPool
  * policy
  * profile
... ...
```

### `get`

```
# List all policy in default output format.
 calicoctl get policy

# List a specific policy in YAML format
calicoctl get -o yaml policy my-policy-1
```

```
-o --output=<OUTPUT FORMAT>  Output format.  One of: yaml, json, ps, wide,
                             custom-columns=..., go-template=...,
                             go-template-file=...   [Default: ps]
```

默认 `get` 命令输出格式为 `ps`

```
$ calicoctl get hostEndpoint
HOSTNAME   NAME        
host1      endpoint1   
myhost     eth0  
```

`wide` 格式输出会更详细，会输出资源的一些附加列

```
$ calicoctl get hostEndpoint --output=wide
HOSTNAME   NAME        INTERFACE   IPS                PROFILES      
host1      endpoint1               1.2.3.4,0:bb::aa   prof1,prof2   
myhost     eth0                                       profile1
```

`custom-columns` 可以自定义输出列

```
$ calicoctl get hostEndpoint --output=custom-columns=NAME,IPS
NAME        IPS                
endpoint1   1.2.3.4,0:bb::aa   
eth0          
```

`yaml`/`json` 以 `yaml` 或者 `json` 格式输出

```
$ calicoctl get hostEndpoint --output=yaml
- apiVersion: v1
  kind: hostEndpoint
  metadata:
    hostname: host1
    labels:
      type: database
    name: endpoint1
  spec:
    expectedIPs:
    - 1.2.3.4
    - 0:bb::aa
... ...
```

如果节点没有运行 etcd，那么需要通过 `ETCD_ENDPOINTS` 指定 etcd 地址，否则将无法操作：

```
ETCD_ENDPOINTS=http://172.16.0.10:2379 calicoctl get bgppeers
```

### `config`

```
# calicoctl config --help
Set the Calico datastore access information in the environment variables or
or supply details in a config file.

Usage:
  calicoctl config set <NAME> <VALUE> [--node=<NODE>]
                                      [--raw=(bgp|felix)]
                                      [--config=<CONFIG>]
  calicoctl config unset <NAME> [--node=<NODE>]
                                [--raw=(bgp|felix)]
                                [--config=<CONFIG>]
  calicoctl config get <NAME> [--node=<NODE>]
                              [--raw=(bgp|felix)]
                              [--config=<CONFIG>]

Examples:
  # Turn off the full BGP node-to-node mesh
  calicoctl config set nodeToNodeMesh off

  # Set global log level to warning
  calicoctl config set logLevel warning

  # Set log level to info for node "node1"
  calicoctl config set logLevel info --node=node1

  # Display the current setting for the nodeToNodeMesh
  calicoctl config get nodeToNodeMesh

Options:
  -n --node=<NODE>      The node name.
     --raw=(bgp|felix)  Apply raw configuration for the specified component.
                        This option should be used with care; the data is not
                        validated and it is possible to configure or remove
                        data that may prevent the component from working as
                        expected.
  -c --config=<CONFIG>  Path to the file containing connection configuration in
                        YAML or JSON format.
                        [default: /etc/calico/calicoctl.cfg]

... ...

 Name            | Scope       | Value                                  |
-----------------+-------------+----------------------------------------+
 logLevel        | global,node | none,debug,info,warning,error,critical |
 nodeToNodeMesh  | global      | on,off                                 |
 asNumber        | global      | 0-4294967295                           |
 ipip            | global      | on,off                                 |
```

目前 `calicoctl config` 只有 `logLevel` 可以单独设置节点，其它如 `nodeToNodeMesh`、`asNumber`、`ipip` 配置的都是全局选项。默认安装之后 `nodeToNodeMesh` 为开启状态，如果需要和内部交换机打通，需要通过如下命令关闭该选项：

```
# calicoctl config get nodeToNodeMesh       // 获取当前 nodeToNodeMesh 值，显示为 on
on
# calicoctl config set nodeToNodeMesh off   // 关闭 nodeToNodeMesh
```

### `ipam`

```
Usage:
  calicoctl ipam <command> [<args>...]

    release      Release a Calico assigned IP address.
    show         Show details of a Calico assigned IP address.

Options:
  -h --help      Show this screen.

Description:
  IP Address Management specific commands for calicoctl.

  See 'calicoctl ipam <command> --help' to read about a specific subcommand.
```

目前 `calicoctl ipam` 的地址管理相对 `v2.0` 以下的版本，功能还是比较弱的，有 `release` 和 `show` 两个命令。

`calico ipam release` 用于从 Calico 清除未被正常回收的地址

```
$ calicoctl ipam release --ip=192.168.1.2
```

`calico ipam show` 用于获取指定 ip 地址使用情况

```
# IP is not assigned to an endpoint
$ calicoctl ipam show --ip=192.168.1.2
IP 192.168.1.2 is not currently assigned

# Basic Docker container has the assigned IP
# 表明该 IP 地址已绑定 Docker 容器
$ calicoctl ipam show --ip=192.168.1.1
No attributes defined for 192.168.1.1
```

### `node`

```
Usage:
  calicoctl node <command> [<args>...]

    status       View the current status of a Calico node.
                 // 获取 Calico 节点当前状态
    diags        Gather a diagnostics bundle for a Calico node.
                 // 收集节点诊断信息
    checksystem  Verify the compute host is able to run a Calico node instance.
                 // 验证系统环境是否可以运行 Calico 节点实例

Options:
  -h --help      Show this screen.

Description:
  Node specific commands for calicoctl.  These commands must be run directly on
  the compute host running the Calico node instance.

  See 'calicoctl node <command> --help' to read about a specific subcommand.

```

```
# calicoctl node --help
Set the Calico datastore access information in the environment variables or
or supply details in a config file.

Usage:
  calicoctl node <command> [<args>...]

    run          Run the Calico node container image.
                // 运行节点容器镜像
    status       View the current status of a Calico node.
                // 获取 Calico 节点当前状态
    diags        Gather a diagnostics bundle for a Calico node.
                // 收集节点诊断信息
    checksystem  Verify the compute host is able to run a Calico node instance.
                // 验证系统环境是否可以运行 Calico 节点实例

Options:
  -h --help      Show this screen.

Description:
  Node specific commands for calicoctl.  These commands must be run directly on
  the compute host running the Calico node instance.

  See 'calicoctl node <command> --help' to read about a specific subcommand.
```

获取 Calico 节点状态信息：

```
$ sudo calicoctl node status
Calico process is running.

IPv4 BGP status
+--------------+-------------------+-------+----------+-------------+
| PEER ADDRESS |     PEER TYPE     | STATE |  SINCE   |    INFO     |
+--------------+-------------------+-------+----------+-------------+
| 172.17.8.102 | node-to-node mesh | up    | 23:30:04 | Established |
+--------------+-------------------+-------+----------+-------------+

IPv6 BGP status
No IPv6 peers found.
```

`calicoctl node run` calico 节点启动参数选项：


```
Usage:
  calicoctl node run [--ip=<IP>] [--ip6=<IP6>] [--as=<AS_NUM>]
                     [--name=<NAME>]
                     [--ip-autodetection-method=<IP_AUTODETECTION_METHOD>]
                     [--ip6-autodetection-method=<IP6_AUTODETECTION_METHOD>]
                     [--log-dir=<LOG_DIR>]
                     [--node-image=<DOCKER_IMAGE_NAME>]
                     [--backend=(bird|gobgp|none)]
                     [--config=<CONFIG>]
                     [--no-default-ippools]
                     [--dryrun]
                     [--init-system]
                     [--disable-docker-networking]
                     [--docker-networking-ifprefix=<IFPREFIX>]
                     [--use-docker-networking-container-labels]

Options:
  -h --help                Show this screen.
     --name=<NAME>         The name of the Calico node.  If this is not
                           supplied it defaults to the host name.
                           // 指定 Calico 节点名，如果没有指定则默认主机名
     --as=<AS_NUM>         Set the AS number for this node.  If omitted, it
                           will use the value configured on the node resource.
                           If there is no configured value and --as option is
                           omitted, the node will inherit the global AS number
                           (see 'calicoctl config' for details).
                           // 设置当前节点的 AS number，如果未指定，默认使用全局 As number
     --ip=<IP>             Set the local IPv4 routing address for this node.
                           If omitted, it will use the value configured on the
                           node resource.  If there is no configured value
                           and the --ip option is omitted, the node will
                           attempt to autodetect an IP address to use.  Use a
                           value of 'autodetect' to always force autodetection
                           of the IP each time the node starts.
                           // 设置当前节点本地 IPv4 路由地址，如果未指定，
                           // 则使用节点资源配置的值，如果也未配置，则自动探测使用地址
     --ip6=<IP6>           Set the local IPv6 routing address for this node.
                           If omitted, it will use the value configured on the
                           node resource.  If there is no configured value
                           and the --ip6 option is omitted, the node will not
                           route IPv6.
                           // 设置当前节点本地 IPv6 路由地址，如果未指定，
                           // 则使用节点资源配置的值，如果也未配置，则不会路由 IPv6
    ... ...
     --log-dir=<LOG_DIR>   The directory containing Calico logs.
                           [default: /var/log/calico]
                           // 指定 Calico 日志存储目录，默认为 /var/log/calico
     --node-image=<DOCKER_IMAGE_NAME>
                           Docker image to use for Calico's per-node container.
                           [default: calico/node:%s]
                           // 指定节点镜像
     --backend=(bird|gobgp|none)
                           Specify which networking backend to use.  When set
                           to "none", Calico node runs in policy only mode.
                           The option to run with gobgp is currently
                           experimental.
                           [default: bird]
                           // 指定网络存储类型，gobgp 当前处于实验性阶段，默认使用 bird
     --dryrun              Output the appropriate command, without starting the
                           container.
                           // 只输出执行命令信息，而不启动容器
     --init-system         Run the appropriate command to use with an init
                           system.
                           // 使用 init system 运行命令
     --no-default-ippools  Do not create default pools upon startup.
                           Default IP pools will be created if this is not set
                           and there are no pre-existing Calico IP pools.
                           // 启动不创建默认的 IP 池
     --disable-docker-networking
                           Disable Docker networking.
                           // 停用容器网络
     --docker-networking-ifprefix=<IFPREFIX>
                           Interface prefix to use for the network interface
                           within the Docker containers that have been networked
                           by the Calico driver.
                           [default: cali]
                           // docker 容器接口前缀，默认 cali
    ... ...
  -c --config=<CONFIG>     Path to the file containing connection
                           configuration in YAML or JSON format.
                           [default: /etc/calico/calicoctl.cfg]
                           // 配置文件路径，默认 /etc/calico/calicoctl.cfg
```

> 注：经测试，此处 `--name` 选项必须为主机名，否则和 bgppeer 的 `node` 字段匹配不上，bgppeer 的 `node` 字段必须为主机名，后续还需进一步测试。

### 资源类型

资源结构概览：

```
apiVersion: v1                      // API 版本号
kind: <type of resource>            // 资源类型
metadata:                           // 元数据
  # Identifying information
  name: <name of resource>
  ...
spec:                               // 资源配置信息
  # Specification of the resource
  ...
```

#### bgpPeer

 * [Calico’s documentation on L3 Topologies](http://docs.projectcalico.org/v2.6/reference/private-cloud/l3-interconnect-fabric)

配置 Calico 集群节点，支持如下别名：`bgppeer`、`bgppeers`、`bgpp`、`bgpps`、`bp`、`bps`

```
apiVersion: v1
kind: bgpPeer
metadata:
  scope: node           // 范围：global/node
  node: rack1-host1     // 节点对应的主机名，如果是 scope 为 global，则此行必须省略
  peerIP: 192.168.1.1   // 当前 peer ip 地址
spec:
  asNumber: 63400       // 当前 peer As Number
```

> v3.0 `apiVersion` 已变更为 `projectcalico.org/v3`

| Field | Description | Accepted Values | Schema |
| ----- | ----------- | --------------- | ------ |
| scope	| Determines the Calico nodes to which this peer applies.|global, node 	| string |
| node 	| Must be specified if scope is node, and must be omitted when scope is global. | The `hostname` of the node to which this peer applies. | string |
| peerIP | The IP address of this peer. | Valid IPv4 or IPv6 address. | string |

> 此处 node 官档标明为主机名，另外实际测试中如果此处指定 calico node 启动时指定的节点名「非主机名」时，跨容器路由会有问题，所以此处必须标注为主机名。

关于 BGP 的一些术语：

> 在 BGP 网络中，所有参与 BGP 进程的路由器都称为 BGP-speaking 路由器（BGP-speaking 可以看成是 BGP 会话的意思）

> 对于活动的 BGP-speaking设备，称为 peer设备，它与其他 BGP-speaking 设备之间有一个活动的 TCP 连接。BGP speaker是指本地 BGP 路由器，而 peer（对等，或者对端）是指任何其他 BGP-speaking 网络设备

> 当 BGP peer 路由器位于不同 AS 中时，它们之间互称对方为外部 peer，当它们位于同一个 AS 中时，则称为内部 peer

> 当在 peer 设备间（也就是相互直接连接的 BGP 路由器之间）建立了 TCP 连接，每个 BGP peer 就会立即与对端交换所有的路由表，也就是完整的 BGP 路由表

#### Host Endpoint Resource (hostEndpoint)

`Host Endpoint` 资源表示运行 Calico 主机关联接口，每个主机的 endpoint 包括针对该接口设置 labels 和 profiles，用以应用相关策略。

```
apiVersion: v1
kind: hostEndpoint
metadata:
  name: eth0
  node: myhost
  labels:
    type: production
spec:
  interfaceName: eth0
  expectedIPs:
  - 192.168.0.1
  - 192.168.0.2
  profiles:
  - profile1
  - profile2
```

#### IP Pool Resource(ipPool)

定义 Calico IP 地址资源池，除了 `ipPool` 还有以下别名：`ippool`、`ippools`、`ipp`、`ipps`、`pool`、`pools`

```
apiVersion: v1
kind: ipPool
metadata:
  cidr: 10.1.0.0/16
spec:
  ipip:
    enabled: false
  nat-outgoing: true
  disabled: false       # 标注为 true 表示不启用该地址池
```

`ipip`：ipip tunneling configuration for this pool. If not specified, ipip tunneling is disabled for this pool. 在公有云平台跨主机通信需要添加这一选项

`nat-outgoing`：When enabled, packets sent from calico networked containers in this pool to destinations outside of this pool will be masqueraded。简单说，使得容器可以访问外网

> 如果直接和内网交换机打通，则去除 `nat-outgoing` 选项，否则容器访问外部网络还是以 nat 方式出去的。

> 如果 ip 池启用了 `ipip`，建议同时也开启 `nat-outgoing`。否则当工作负载和运行 Calico 的主机之间没有 `nat-outgoing` 路由时启用 `ipip` 是不对称的，并且可能导致流量由于 RPF 检查失败而被过滤。

#### Node Resource (node)

定义节点资源，除了 `node`，还可以使用 `nodes`、`no`、`nos`

默认启动 Calico node 实例，会自动创建一个使用主机名的节点资源。

```
apiVersion: v1
kind: node
metadata:
  name: node-hostname
spec:
  bgp:
    asNumber: 64512
    ipv4Address: 10.244.0.1
    ipv6Address: 2001:db8:85a3::8a2e:370:7334
```


获取节点信息：

```
# calicoctl get node  -o wide
NAME                   ASN     IPV4            IPV6
host1                  64511   192.168.1.1
... ...
```

#### Policy Resource(policy) 和 Profile Resource(profile)

关于规则的设置，当前还没有实际使用，具体可参考官网内容 [Policy Resource (policy)](http://docs.projectcalico.org/v2.6/reference/calicoctl/resources/policy) 和 [Profile Resource(profile)](http://docs.projectcalico.org/v2.6/reference/calicoctl/resources/profile)。
