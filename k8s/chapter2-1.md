# 从头开始构建 Kubernetes 集群


```
yum install etcd -y
```

下载 `cfssl`

```
mkdir ~/bin
curl -s -L -o ~/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -s -L -o ~/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x ~/bin/{cfssl,cfssljson}
export PATH=$PATH:~/bin
```

初始化

```
mkdir ~/cfssl
cd ~/cfssl
cfssl print-defaults config > ca-config.json
cfssl print-defaults csr > ca-csr.json
```

`ca-config.json`

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
                    "client auth"
                ]
            }
        }
    }
}
```

`ca-csr.json`

```
{
    "CN": "Test CA",
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

```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
```

```
ca-key.pem
ca.csr
ca.pem
```


* Please keep `ca-key.pem` file in safe. This key allows to create any kind of certificates within your CA.
* `*.csr` files are not used in our example.

Generate server certificate

```
cfssl print-defaults csr > server.json
```

`server.json`

```
...
    "CN": "coreos1",
    "hosts": [
        "192.168.122.68",
        "ext.example.com",
        "coreos1.local",
        "coreos1"
    ],
...
```

```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server.json | cfssljson -bare server
```

```
cfssl print-defaults csr > member1.json
```

Generate peer certificate

```
cfssl print-defaults csr > member1.json
```

```
...
    "CN": "member1",
    "hosts": [
        "192.168.122.101",
        "ext.example.com",
        "member1.local",
        "member1"
    ],
...
```

```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer member1.json | cfssljson -bare member1
```

Generate client certificate

```
cfssl print-defaults csr > client.json
```

```
...
    "CN": "client",
    "hosts": [""],
...
```

```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare client
```

```
[virt7-container-common-candidate]
name=virt7-container-common-candidate
baseurl=https://cbs.centos.org/repos/virt7-container-common-candidate/x86_64/os/
enabled=1
gpgcheck=0
```

```
yum install -y kubernetes --disablerepo=extras
```
