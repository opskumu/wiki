# 从头开始构建 Kubernetes 集群

| 节点 | 地址 | 用途 |
| :-- | :-- | :-- |
| master | 192.168.150.129 | Kubernetes master & etcd node |
| node1  | 192.168.150.130 | Kubernetes node & etcd node |
| node2  | 192.168.150.131 | Kubernetes node & etcd node |

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

### etcd 集群

#### 安装 etcd

```
yum install -y etcd         // 三个节点通过 yum 安装 etcd
```

#### 修改 etcd 配置

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

#### 启动 etcd

```
systemctl enable etcd
systemctl start etcd
```

客户端通过 `client` 证书验证集群状态

```
# ETCDCTL_ENDPOINT=https://192.168.150.129:2379,https://192.168.150.130,https://192.168.150.131 etcdctl --cert-file=/root/cfssl/client.pem --key-file=/root/cfssl/client-key.pem  --ca-file=/etc/etcd/certs/ca.pem  cluster-health
member 304bc49cfdaa154f is healthy: got healthy result from https://192.168.150.130:2379
member b11bce7cadfd39e8 is healthy: got healthy result from https://192.168.150.129:2379
member e4f0cdb23f2f804e is healthy: got healthy result from https://192.168.150.131:2379
cluster is healthy
# ETCDCTL_ENDPOINT=https://192.168.150.129:2379,https://192.168.150.130,https://192.168.150.131 etcdctl --cert-file=/root/cfssl/client.pem --key-file=/root/cfssl/client-key.pem  --ca-file=/etc/etcd/certs/ca.pem  member list
304bc49cfdaa154f: name=192.168.150.130 peerURLs=https://192.168.150.130:2380 clientURLs=https://192.168.150.130:2379 isLeader=false
b11bce7cadfd39e8: name=192.168.150.129 peerURLs=https://192.168.150.129:2380 clientURLs=https://192.168.150.129:2379 isLeader=true
e4f0cdb23f2f804e: name=192.168.150.131 peerURLs=https://192.168.150.131:2380 clientURLs=https://192.168.150.131:2379 isLeader=false
```

### Kubernetes 集群

```
yum install -y kubernetes --disablerepo=extras
```
