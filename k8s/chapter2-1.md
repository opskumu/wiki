# 从头开始构建 Kubernetes 集群

## 系统信息

| 节点 | 地址 | 用途 |
| :-- | :-- | :-- |
| master | 192.168.150.129 | Kubernetes master & etcd node |
| node1  | 192.168.150.130 | Kubernetes node & etcd node |
| node2  | 192.168.150.131 | Kubernetes node & etcd node |


```
# cat /etc/centos-release
CentOS Linux release 7.4.1708 (Core)
# uname -r
3.10.0-693.el7.x86_64
```

## 添加 YUM 源

默认的 YUM 源版本相对比较低，我们可以通过添加以下 repo，用来安装较新版本的 `Kubernetes`：

```
[virt7-container-common-candidate]
name=virt7-container-common-candidate
baseurl=https://cbs.centos.org/repos/virt7-container-common-candidate/x86_64/os/
enabled=1
gpgcheck=0
```

> [Installing Docker - CentOS-7](https://wiki.centos.org/Container/Tools)

## 证书创建

本章节 etcd 和 kubernetes 都使用 tls 安装认证，针对非 tls 的这里不再赘述（非 tls 会简单很多）。

CoreOS 官网详细介绍了通过 `cfssl` 工具生成证书，具体可以参考 [Generate self-signed certificates](https://coreos.com/os/docs/latest/generate-self-signed-certificates.html)。

### 下载 `cfssl` 工具

```
mkdir ~/bin
curl -s -L -o ~/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -s -L -o ~/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x ~/bin/{cfssl,cfssljson}
export PATH=$PATH:~/bin
```

### 初始化证书认证

```
mkdir ~/cfssl
cd ~/cfssl
cfssl print-defaults config > ca-config.json
cfssl print-defaults csr > ca-csr.json
```

* `client` 证书被用于客户端通过服务端进行身份认证。如 etcdctl、etcd proxy、fleetctl 或者 docker clients
* `server` 证书是由服务端使用并由客户端验证以获得授权。如 docker server 或者 kube-apiserver
* `peer` 证书用于 etcd cluster members 之间通信

#### 配置 CA 选项

CA 配置文件为 `ca-config.json`，修改如下：

```
{
    "signing": {
        "default": {
            "expiry": "87600h"
        },
        "profiles": {
            "server": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth"
                ]
            },
            "client": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            },
            "peer": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
```

你也可以修改 `ca-csr.json` 证书签名请求（CSR）：

```
{
    "CN": "CA",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "ZheJiang",
            "ST": "HangZhou"
        }
    ]
}
```

通过自定义选项生成 CA：

```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
```

得到如下证书文件：

```
ca-key.pem
ca.csr
ca.pem
```

* `ca-key.pem` 文件要好好保存。通过该文件可以在你的 CA 中创建任何类型的证书。
* `*.csr` 文件本例中暂时不会用到

#### 生成服务端证书

```
cfssl print-defaults csr > server.json
```

修改`server.json`，内容如下：

```
{
    "CN": "server",
    "hosts": [
        "127.0.0.1",
        "192.168.150.129",
        "192.168.150.130",
        "192.168.150.131"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "ZheJiang",
            "ST": "HangZhou"
        }
    ]
}
```

其中 __hosts__ 和 __Common Name (CN)__ 字段比较重要，__hosts__ 字段填写集群节点 IP。

通过命令生成 `server` 证书：

```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server.json | cfssljson -bare server
```

得到如下证书文件：

```
server-key.pem
server.csr
server.pem
```

#### 生成 `peer` 证书

```
cfssl print-defaults csr > member1.json
```

修改内容如下：

```
{
    "CN": "member1",
    "hosts": [
        "192.168.150.129",
        "127.0.0.1"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "ZheJiang",
            "ST": "HangZhou"
        }
    ]
}
```

通过命令生成 `peer` 证书：

```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer member1.json | cfssljson -bare member1
```

得到如下证书文件：

```
member1-key.pem
member1.csr
member1.pem
```

`peer` 证书比较特殊，修改 `CN` 字段名，如 member2、member3，并修改 `hosts` 字段，重复以上操作生成证书。（`hosts` 字段填写对应的集群节点 IP 即可）

#### 生成客户端证书

```
cfssl print-defaults csr > client.json
```

修改 `client.json`：

```
{
    "CN": "client",
    "hosts": [
        ""
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "ZheJiang",
            "ST": "HangZhou"
        }
    ]
}
```

生成 `client` 证书：

```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare client
```

#### 同步证书到节点

修改证书权限：

```
chmod 600 -R ~/cfssl/*
```

* 192.168.150.129 `/etc/etcd/certs/`

```
ca.pem
member1-key.pem
member1.pem
server-key.pem
server.pem
```

* 192.168.150.130 `/etc/etcd/certs/`

```
ca.pem
member2-key.pem
member2.pem
server-key.pem
server.pem
```

* 192.168.150.131 `/etc/etcd/certs/`

```
ca.pem
member3-key.pem
member3.pem
server-key.pem
server.pem
```

## etcd 集群

### 安装 etcd

```
yum install -y etcd         // 三个节点通过 yum 安装 etcd
```

### 修改 etcd 配置

修改各节点 `/etc/etcd/etcd.conf` 配置如下：

* 192.168.150.129

```
# grep -vE '^#|^$' /etc/etcd/etcd.conf
ETCD_NAME=192.168.150.129
ETCD_DATA_DIR="/var/lib/etcd/192.168.150.129.etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.150.129:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.150.129:2379,https://127.0.0.1:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.150.129:2380"
ETCD_INITIAL_CLUSTER="192.168.150.129=https://192.168.150.129:2380,192.168.150.130=https://192.168.150.130:2380,168.150.131=https://192.168.150.131:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.150.129:2379"
ETCD_CERT_FILE="/etc/etcd/certs/server.pem"
ETCD_KEY_FILE="/etc/etcd/certs/server-key.pem"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/etc/etcd/certs/ca.pem"
ETCD_PEER_CERT_FILE="/etc/etcd/certs/member1.pem"
ETCD_PEER_KEY_FILE="/etc/etcd/certs/member1-key.pem"
ETCD_PEER_CLIENT_CERT_AUTH="true"
ETCD_PEER_TRUSTED_CA_FILE="/etc/etcd/certs/ca.pem"
```

* 192.168.150.130

```
# grep -vE '^#|^$' /etc/etcd/etcd.conf
ETCD_NAME=192.168.150.130
ETCD_DATA_DIR="/var/lib/etcd/192.168.150.130.etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.150.130:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.150.130:2379,https://127.0.0.1:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.150.130:2380"
ETCD_INITIAL_CLUSTER="192.168.150.129=https://192.168.150.129:2380,192.168.150.130=https://192.168.150.130:2380,168.150.131=https://192.168.150.131:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.150.130:2379"
ETCD_CERT_FILE="/etc/etcd/certs/server.pem"
ETCD_KEY_FILE="/etc/etcd/certs/server-key.pem"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/etc/etcd/certs/ca.pem"
ETCD_PEER_CERT_FILE="/etc/etcd/certs/member2.pem"
ETCD_PEER_KEY_FILE="/etc/etcd/certs/member2-key.pem"
ETCD_PEER_CLIENT_CERT_AUTH="true"
ETCD_PEER_TRUSTED_CA_FILE="/etc/etcd/certs/ca.pem"
```

* 192.168.150.131

```
ETCD_NAME=192.168.150.131
ETCD_DATA_DIR="/var/lib/etcd/192.168.150.131.etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.150.131:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.150.131:2379,https://127.0.0.1:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.150.131:2380"
ETCD_INITIAL_CLUSTER="192.168.150.129=https://192.168.150.129:2380,192.168.150.130=https://192.168.150.130:2380,192.168.150.131=https://192.168.150.131:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.150.131:2379"
ETCD_CERT_FILE="/etc/etcd/certs/server.pem"
ETCD_KEY_FILE="/etc/etcd/certs/server-key.pem"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/etc/etcd/certs/ca.pem"
ETCD_PEER_CERT_FILE="/etc/etcd/certs/member3.pem"
ETCD_PEER_KEY_FILE="/etc/etcd/certs/member3-key.pem"
ETCD_PEER_CLIENT_CERT_AUTH="true"
ETCD_PEER_TRUSTED_CA_FILE="/etc/etcd/certs/ca.pem"
```

### 启动 etcd

```
systemctl enable etcd
systemctl start etcd
```

客户端通过 `client` 证书验证集群状态

```
# ETCDCTL_ENDPOINT=https://192.168.150.129:2379,https://192.168.150.130:2379,https://192.168.150.131:2379 etcdctl --cert-file=/root/cfssl/client.pem --key-file=/root/cfssl/client-key.pem  --ca-file=/etc/etcd/certs/ca.pem  cluster-health
member 304bc49cfdaa154f is healthy: got healthy result from https://192.168.150.130:2379
member b11bce7cadfd39e8 is healthy: got healthy result from https://192.168.150.129:2379
member e4f0cdb23f2f804e is healthy: got healthy result from https://192.168.150.131:2379
cluster is healthy
# ETCDCTL_ENDPOINT=https://192.168.150.129:2379,https://192.168.150.130:2379,https://192.168.150.131:2379 etcdctl --cert-file=/root/cfssl/client.pem --key-file=/root/cfssl/client-key.pem  --ca-file=/etc/etcd/certs/ca.pem  member list
304bc49cfdaa154f: name=192.168.150.130 peerURLs=https://192.168.150.130:2380 clientURLs=https://192.168.150.130:2379 isLeader=false
b11bce7cadfd39e8: name=192.168.150.129 peerURLs=https://192.168.150.129:2380 clientURLs=https://192.168.150.129:2379 isLeader=true
e4f0cdb23f2f804e: name=192.168.150.131 peerURLs=https://192.168.150.131:2380 clientURLs=https://192.168.150.131:2379 isLeader=false
```

## Docker & Flannel

### Docker


#### Docker 配置

`/usr/lib/systemd/system/docker.service`

```
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.com
After=network.target docker-containerd.service
Wants=docker-storage-setup.service
Requires=docker-containerd.service rhel-push-plugin.socket

[Service]
Type=notify
EnvironmentFile=-/etc/sysconfig/docker
EnvironmentFile=-/etc/sysconfig/docker-storage
EnvironmentFile=-/etc/sysconfig/docker-network
Environment=GOTRACEBACK=crash
ExecStart=/usr/bin/dockerd-current \
          --add-runtime oci=/usr/libexec/docker/docker-runc-current \
          --default-runtime=oci \
          --authorization-plugin=rhel-push-plugin \
          --containerd /run/containerd.sock \
          --exec-opt native.cgroupdriver=systemd \
          --userland-proxy-path=/usr/libexec/docker/docker-proxy-current \
          --init-path=/usr/libexec/docker/docker-init-current \
          --seccomp-profile=/etc/docker/seccomp.json \
          $OPTIONS \
          $DOCKER_STORAGE_OPTIONS \
          $DOCKER_NETWORK_OPTIONS \
          $ADD_REGISTRY \
          $BLOCK_REGISTRY \
          $INSECURE_REGISTRY \
          $REGISTRIES
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
TimeoutStartSec=0
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
```

```
systemctl daemon-reload
```

`/etc/sysconfig/docker`

```
# /etc/sysconfig/docker

# Modify these options if you want to change the way the docker daemon runs
OPTIONS=''
if [ -z "${DOCKER_CERT_PATH}" ]; then
    DOCKER_CERT_PATH=/etc/docker
fi

# Do not add registries in this file anymore. Use /etc/containers/registries.conf
# from the atomic-registries package.
#

# On an SELinux system, if you remove the --selinux-enabled option, you
# also need to turn on the docker_transition_unconfined boolean.
# setsebool -P docker_transition_unconfined 1

# Location used for temporary files, such as those created by
# docker load and build operations. Default is /var/lib/docker/tmp
# Can be overriden by setting the following environment variable.
# DOCKER_TMPDIR=/var/tmp

# Controls the /etc/cron.daily/docker-logrotate cron job status.
# To disable, uncomment the line below.
# LOGROTATE=false
#

# docker-latest daemon can be used by starting the docker-latest unitfile.
# To use docker-latest client, uncomment below line
#DOCKERBINARY=/usr/bin/docker-latest
```

`/etc/docker/daemon.json`

```
{
    "storage-driver": "overlay2",
    "log-opts": {
        "max-size": "200m",
        "max-file": "5"
    },
    "log-level": "warn",
    "registry-mirrors": [
        "https://registry.docker-cn.com",
        "http://hub-mirror.c.163.com"
    ]
}
```

### Flannel

```
ETCDCTL_ENDPOINT=https://192.168.150.129:2379,https://192.168.150.130,https://192.168.150.131 etcdctl --cert-file=/root/cfssl/client.pem --key-file=/root/cfssl/client-key.pem  --ca-file=/etc/etcd/certs/ca.pem  mk /atomic.io/network/config '{"Network":"172.17.0.0/16", "SubnetLen": 25,"Backend": {"Type": "host-gw"}}'
```

`/etc/sysconfig/flanneld`

```
# Flanneld configuration options

# etcd url location.  Point this to the server where etcd runs
FLANNEL_ETCD_ENDPOINTS="https://192.168.150.129:2379,https://192.168.150.130:2379,https://192.168.150.131:2379"

# etcd config key.  This is the configuration key that flannel queries
# For address range assignment
FLANNEL_ETCD_PREFIX="/atomic.io/network"

# Any additional options that you want to pass
FLANNEL_OPTIONS="-etcd-cafile=/srv/kubernetes/ca.pem -etcd-certfile=/srv/kubernetes/client.pem -etcd-keyfile=/srv/kubernetes/client-key.pem"
```

### 启动 Flannel & Docker

```
systemctl start flanneld
systemctl enable flanneld
systemctl start docker
systemctl enable docker
```

```
[root@node1 ~]# ifconfig docker0
docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 10.244.16.129  netmask 255.255.255.128  broadcast 0.0.0.0
        ether 02:42:f3:6a:61:10  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

```
[root@node2 ~]# ifconfig docker0
docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 10.244.30.129  netmask 255.255.255.128  broadcast 0.0.0.0
        ether 02:42:4d:06:a9:28  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

[root@node2 ~]#
```

测试连通：

```
[root@node2 ~]# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.150.2   0.0.0.0         UG    100    0        0 ens33
10.244.16.128   192.168.150.130 255.255.255.128 UG    0      0        0 ens33
10.244.30.128   0.0.0.0         255.255.255.128 U     0      0        0 docker0
192.168.150.0   0.0.0.0         255.255.255.0   U     100    0        0 ens33
[root@node2 ~]# ping -c 1 10.244.16.129
PING 10.244.16.129 (10.244.16.129) 56(84) bytes of data.
64 bytes from 10.244.16.129: icmp_seq=1 ttl=64 time=0.425 ms

--- 10.244.16.129 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.425/0.425/0.425/0.000 ms
```


## Kubernetes 集群

### Kubernetes Master

```
yum install -y kubernetes --disablerepo=extras
```

同步证书，此处为了方便直接使用上文中生成的证书文件，你也可以单独再生成一份专用于 `Kubernetes`：

```
# chown kube:kube -R /srv/kubernetes
# ls -l /srv/kubernetes/*
-rw------- 1 kube kube 1257 Dec 10 14:40 /srv/kubernetes/ca.pem
-rw------- 1 kube kube 1679 Dec 10 14:41 /srv/kubernetes/server-key.pem
-rw------- 1 kube kube 1334 Dec 10 14:41 /srv/kubernetes/server.pem
```

`/etc/kubernetes/config`

```
###
# kubernetes system config
#
# The following values are used to configure various aspects of all
# kubernetes services, including
#
#   kube-apiserver.service
#   kube-controller-manager.service
#   kube-scheduler.service
#   kubelet.service
#   kube-proxy.service
# logging to stderr means we get it in the systemd journal
KUBE_LOGTOSTDERR="--logtostderr=true"

# journal message level, 0 is debug
KUBE_LOG_LEVEL="--v=0"

# Should this cluster be allowed to run privileged docker containers
KUBE_ALLOW_PRIV="--allow-privileged=true"

# How the controller-manager, scheduler, and proxy find the apiserver
KUBE_MASTER="--master=http://127.0.0.1:8080"
```

`/etc/kubernetes/apiserver`

```
###
# kubernetes system config
#
# The following values are used to configure the kube-apiserver
#

# The address on the local server to listen to.
KUBE_API_ADDRESS="--insecure-bind-address=127.0.0.1"

# The port on the local server to listen on.
# KUBE_API_PORT="--port=8080"

# Port minions listen on
# KUBELET_PORT="--kubelet-port=10250"

# Comma separated list of nodes in the etcd cluster
KUBE_ETCD_SERVERS="--etcd-servers=https://192.168.150.129:2379,https://192.168.150.130:2379,https://192.168.150.131:2379"

# Address range to use for services
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"

# default admission control policies
KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota"

# Add your own!
KUBE_API_ARGS="--max-requests-inflight=2000 --client-ca-file=/srv/kubernetes/ca.pem --tls-cert-file=/srv/kubernetes/server.pem --tls-private-key-file=/srv/kubernetes/server-key.pem --etcd-cafile=/srv/kubernetes/ca.pem --etcd-certfile=/srv/kubernetes/client.pem --etcd-keyfile=/srv/kubernetes/client-key.pem"
```

`/etc/kubernetes/controller-manager`

```
###
# The following values are used to configure the kubernetes controller-manager

# defaults from config and apiserver should be adequate

# Add your own!
KUBE_CONTROLLER_MANAGER_ARGS="--root-ca-file=/srv/kubernetes/ca.pem --service-account-private-key-file=/srv/kubernetes/server-key.pem --pod-eviction-timeout=120s"
```

`/etc/kubernetes/scheduler`

```
###
# kubernetes scheduler config

# default config should be adequate

# Add your own!
KUBE_SCHEDULER_ARGS=""
```

```
systemctl start kube-apiserver
systemctl start kube-controller-manager
systemctl start kube-scheduler
systemctl enable kube-apiserver
systemctl enable kube-controller-manager
systemctl enable kube-scheduler
```

```
# kubectl cluster-info
Kubernetes master is running at http://localhost:8080

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

### Kubernetes Nodes

```
yum install -y kubernetes --disablerepo=extras
```

同步证书：

```
# ls -l /srv/kubernetes/*
-rw------- 1 root root 1257 Dec 10 14:40 /srv/kubernetes/ca.pem
-rw------- 1 root root 1679 Dec 10 14:41 /srv/kubernetes/client-key.pem
-rw------- 1 root root 1334 Dec 10 14:41 /srv/kubernetes/client.pem
```


`/var/lib/kubelet/.kubeconfig`

```
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /srv/kubernetes/ca.pem
    server: https://192.168.150.129:6443
  name: k8s
users:
- name: kubelet
  user:
    client-certificate: /srv/kubernetes/client.pem
    client-key: /srv/kubernetes/client-key.pem
contexts:
- context:
    cluster: k8s
    user: kubelet
```


`/etc/kubernetes/config`

```
###
# kubernetes system config
#
# The following values are used to configure various aspects of all
# kubernetes services, including
#
#   kube-apiserver.service
#   kube-controller-manager.service
#   kube-scheduler.service
#   kubelet.service
#   kube-proxy.service
# logging to stderr means we get it in the systemd journal
KUBE_LOGTOSTDERR="--logtostderr=true"

# journal message level, 0 is debug
KUBE_LOG_LEVEL="--v=0"

# Should this cluster be allowed to run privileged docker containers
KUBE_ALLOW_PRIV="--allow-privileged=true"

# How the controller-manager, scheduler, and proxy find the apiserver
KUBE_MASTER="--master=https://192.168.150.129:6443"
```

`/etc/kubernetes/kubelet`

```
###
# kubernetes kubelet (minion) config

# The address for the info server to serve on (set to 0.0.0.0 or "" for all interfaces)
KUBELET_ADDRESS="--address=0.0.0.0"

# The port for the info server to serve on
# KUBELET_PORT="--port=10250"

# location of the kubeconfig
KUBELET_API_SERVER="--kubeconfig=/var/lib/kubelet/.kubeconfig"

# You may leave this blank to use the actual hostname
KUBELET_HOSTNAME="--hostname-override=192.168.150.130"

# Add your own!
KUBELET_ARGS="--cgroup-driver=systemd --fail-swap-on=false --image-gc-high-threshold=95 --image-gc-low-threshold=80 --serialize-image-pulls=false --max-pods=30 --container-runtime=docker --cloud-provider=''"
```

> `--pod-infra-container-image=<此处修改为私有 repo 地址>/pause-amd64:3.0`

`/etc/kubernetes/proxy`

```
###
# kubernetes proxy config

# default config should be adequate

# Add your own!
KUBE_PROXY_ARGS="--kubeconfig=/var/lib/kubelet/.kubeconfig"
```

### 启动节点服务

```
systemctl start kubelet
systemctl enable kubelet
systemctl start kube-proxy
systemctl enable kube-proxy
```

Master 上查询当前节点，显示两个节点均已注册：

```
[root@master ~]# kubectl get nodes
NAME              STATUS    ROLES     AGE       VERSION
192.168.150.130   Ready     <none>    1h        v1.8.1
192.168.150.131   Ready     <none>    1h        v1.8.1
```

```
[root@master ~]# cat test-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  containers:
    - name: busybox
      image: busybox:latest
      args: [sh, -c, 'sleep 9999999999']
[root@master ~]# kubectl create -f test-pod.yaml
[root@master ~]# kubectl get pods -o wide
NAME      READY     STATUS    RESTARTS   AGE       IP              NODE
busybox   1/1       Running   0          1m        10.244.30.130   192.168.150.131
```

### KubeDNS


### KubeDashboard
