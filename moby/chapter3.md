# Docker 配置

以下配置说明，统一以 `CentOS7.3` 为系统环境，其它系统版本可能会有所不同。

## 相关配置文件

基本配置文件：

* `/etc/sysconfig/docker`
* `/etc/sysconfig/docker-storage-setup`
* `/etc/sysconfig/docker-network`
* `/etc/docker/daemon.json`

systemd 服务配置：

* `/usr/lib/systemd/system/docker.service`

Docker 从 `1.12` 开始支持通过 `/etc/docker/daemon.json` 文件管理 Docker daemon 的配置选项。

## 具体配置说明

默认配置内容如下：

```
# grep -vE '^#|^$' /etc/sysconfig/docker
OPTIONS='--selinux-enabled --log-driver=journald'
if [ -z "${DOCKER_CERT_PATH}" ]; then
    DOCKER_CERT_PATH=/etc/docker
fi
```

关于 docker daemon 配置选项，本文主要参考官方文档，最新说明以官方 [Daemon CLI reference(dockerd)](https://docs.docker.com/engine/reference/commandline/dockerd/) 为主。

### Daemon socket 选项

Docker daemon 可以三种不同类型的 Socket 监听 Docker API 请求：unix，tcp，fd。默认情况下，会创建一个名为 `/var/run/docker.sock` 的 unix Socket 文件，该文件的访问权限需要是 root 权限或者属于 docker 组。如果有远程访问需求，那么则需要开启 tcp Socket。正常开启 tcp Socket，是没有任何加密和安全认证的，可以通过 HTTPS 等方式加密 tcp Socket，默认不建议开启 tcp Socket。

> Note: If you’re using an HTTPS encrypted socket, keep in mind that only TLS1.0 and greater are supported. Protocols SSLv3 and under are not supported anymore for security reasons.

```
# ls -l /var/run/docker.sock
srw-rw---- 1 root root 0 Sep 13 00:53 /var/run/docker.sock
```

> Note：默认情况下，没有 `docker` 用户组，需要手动创建才会有。但是不建议授权非 root 用户到 docker 组，如此该用户就等于拥有 root 权限了（如直接 mount 宿主根目录到容器，即可变相获取 root 用户的权限）。

```
# groupadd docker
# systemctl restart docker
# ls -l /var/run/docker.sock
srw-rw---- 1 root docker 0 Sep 13 00:59 /var/run/docker.sock    // 注意此时 docker.sock 文件已经属于 docker 用户组了
# usermod -G docker test                                        // 添加 test 用户到 docker 组
# su - test
$ docker ps
```

> 参考：[Enabling Non-root Users to Run Docker Commands](https://docs.oracle.com/cd/E37670_01/E75728/html/section_rdz_hmw_2q.html)

通过 `-H` 选项可以指定 Docker daemon 使用的 Socket 类型，默认 unix Socket 方式，通过添加 `-H tcp://0.0.0.0:2375`  达到使用 tcp Socket 的方式，`0.0.0.0` 表示监听当前主机所有网络接口。

```
# grep -vE '^#|^$' /etc/sysconfig/docker
OPTIONS='--selinux-enabled --log-driver=journald -H tcp://0.0.0.0:2375'
if [ -z "${DOCKER_CERT_PATH}" ]; then
    DOCKER_CERT_PATH=/etc/docker
fi
# systemctl restart docker
# netstat -tulnp | grep 2375
tcp6       0      0 :::2375                 :::*                    LISTEN      16288/dockerd-curre
# docker ps
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
// docker 客户端默认是以 unix socket 连接，因为指定了 tcp Socket，而没有指定 unix Socket，因此直接执行连接失败
# export DOCKER_HOST="tcp://0.0.0.0:2375"   // 设置环境变量，修改 docker 客户端默认连接
# docker ps
```

> ```
> # listen using the default unix socket, and on 2 specific IP addresses on this host. 指定多种连接
> $ sudo dockerd -H unix:///var/run/docker.sock -H tcp://192.168.59.106 -H tcp://10.10.10.2
> ```

### Daemon storage-driver 选项

Docker daemon 当前支持以下几种镜像层存储驱动：

* aufs
* devicemapper
* btrfs
* zfs
* overlay
* overlay2

以上关于不同类型的存储驱动，后续会具体介绍，这一章节只介绍基本的存储驱动配置项，针对 CentOS7 系统则选择使用 devicemapper、overlay、overlay2 居多。当前笔者通过 [Docker 安装](chapter2-1.md#centos7-docker-安装) 的默认存储驱动为 overlay2：

```
# docker info
Containers: 0
 Running: 0
 Paused: 0
 Stopped: 0
Images: 0
Server Version: 1.13.1
Storage Driver: overlay2
 Backing Filesystem: xfs
 Supports d_type: true
 Native Overlay Diff: false
... ...
```

用户可以通过添加 `--storage-driver` 选项设置运行存储驱动，不过更推荐使用 `/etc/docker/daemon.json` 配置文件配置。

通过添加 `--storage-driver` 选项指定存储驱动：

```
# grep -vE '^#|^$' /etc/sysconfig/docker
OPTIONS='--selinux-enabled --log-driver=journald --storage-driver=devicemapper'
if [ -z "${DOCKER_CERT_PATH}" ]; then
    DOCKER_CERT_PATH=/etc/docker
fi
# systemctl restart docker
# docker info
... ...
Storage Driver: devicemapper
 Pool Name: docker-253:0-67599031-pool
 Pool Blocksize: 65.54 kB
 Base Device Size: 10.74 GB
 Backing Filesystem: xfs
 Data file: /dev/loop0
 Metadata file: /dev/loop1
... ...
```

> Note: 考虑到 `daemon.json` 是跨平台的，并且为了和系统初始化脚本配置冲突的问题，所以 Docker 官方推荐使用 `daemon.json` 方式代理 `--storage-driver` 选项方式。

移除 `--storage-driver` 选项，并且在 `/etc/docker/daemon.json` 文件中添加配置，如果文件不存在则创建即可。

```
# cat /etc/docker/daemon.json
{
  "storage-driver": "devicemapper"
}
# systemctl restart docker
```

> Note: 以上指定存储驱动为 devicemapper，如果不添加其它选项，那么此时属于 `loop-lvm` 模式，这种模式下因为回环设备的原因，性能比较差，只适用于测试环境下使用。针对生产环境，则建议使用 `direct-lvm` 模式，后文会专门针对存储驱动做详细介绍。

### Docker runtime execution 选项

通过指定 `native.cgroupdriver` 选项，可以配置容器 cgroups 管理。

```
# docker info | grep 'Cgroup Driver'       // 可以看到 CentOS7 默认 cgroup 驱动为 systemd
Cgroup Driver: systemd
# cat /usr/lib/systemd/system/docker.service
// CentOS7 的运行时选项是直接写死在 docker.service 文件中的，如果要修改，则需要修改该文件。
... ...
ExecStart=/usr/bin/dockerd-current \
          --add-runtime oci=/usr/libexec/docker/docker-runc-current \
          --default-runtime=oci \
          --authorization-plugin=rhel-push-plugin \
          --containerd /run/containerd.sock \
          --exec-opt native.cgroupdriver=cgroupfs \
          --userland-proxy-path=/usr/libexec/docker/docker-proxy-current \
... ...
# systemctl daemon-reload
# systemctl restart docker
# docker info | grep 'Cgroup Driver'
Cgroup Driver: cgroupfs
```

> Note: 如无特色需求，Cgroup Driver 保持默认即可。

### Daemon DNS 选项

| 选项 | 说明 |
| :-- | :-- |
| --dns 8.8.8.8 | 设置容器 DNS |
| --dns-search example.com | 设置容器 search domain |

### Docker Registry 相关选项

#### insecure registries

Docker 认为一个私有仓库要么安全的，要么就是不安全的。以私有仓库 myregistry:5000 为例，一个安全的镜像仓库需要使用 TLS，并且需要拷贝 CA 证书到每台 Docker 主机 `/etc/docker/certs.d/myregistry:5000/ca.crt` 上。

通过选项 `--insecure-registry` 可以标识指定私有仓库为不安全的。 如 `--insecure-registry myregistry:5000` 标识为 myregistry:5000 私有仓库为不安全的，而 `--insecure-registry 10.1.0.0/16` 则告诉 Docker daemon 所有域名被解析到这个网段中底子的镜像仓库都被标识为不安全的。一个不安全的镜像只有被标识为不安全的时候，才可以正常的进行 docker pull、push、search 等操作。

#### lagacy registries

默认情况下，Registry V1 协议是被禁用的，Docker daemon 不会在执行 push、pull 以及 login 操作的时候去尝试通过 V1 协议去连接。可以通过 `--disable-legacy-registry=false` 启用该选项。需要注意的是，在 Docker 17.12 版本中该选项将会被移除，不再支持 Registry V1。

> Note: Interaction v1 registries will no longer be supported in Docker v17.12, and the disable-legacy-registry configuration option will be removed.

### Default ulimit settings

选项 `--default-ulimit` 可以设置所有容器的默认 ulimit 值，通过 `--default-ulimit nproc=10240:10240 --default-ulimit nofile=65535:65535` 设置容器的 nproc 和 nofile 值。如果该值没有设置，那么 ulimit 相关会继承宿主的设置。如果 docker run 设置 ulimit 相关，则会覆盖默认值，也就是说 docker run 优先级最高。

### Daemon configuration file

`--config-file` 选项用来指定 daemon 的 JSON 格式配置文件，默认 Linux 上 JSON 格式的配置文件为 `/etc/docker/daemon.json`。

以下为所有支持配置在 JSON 文件中的选项:

```
{
	"authorization-plugins": [],
	"data-root": "",
	"dns": [],
	"dns-opts": [],
	"dns-search": [],
	"exec-opts": [],
	"exec-root": "",
	"experimental": false,
	"storage-driver": "",
	"storage-opts": [],
	"labels": [],
	"live-restore": true,
	"log-driver": "",
	"log-opts": {},
	"mtu": 0,
	"pidfile": "",
	"cluster-store": "",
	"cluster-store-opts": {},
	"cluster-advertise": "",
	"max-concurrent-downloads": 3,
	"max-concurrent-uploads": 5,
	"default-shm-size": "64M",
	"shutdown-timeout": 15,
	"debug": true,
	"hosts": [],
	"log-level": "",
	"tls": true,
	"tlsverify": true,
	"tlscacert": "",
	"tlscert": "",
	"tlskey": "",
	"swarm-default-advertise-addr": "",
	"api-cors-header": "",
	"selinux-enabled": false,
	"userns-remap": "",
	"group": "",
	"cgroup-parent": "",
	"default-ulimits": {},
	"init": false,
	"init-path": "/usr/libexec/docker-init",
	"ipv6": false,
	"iptables": false,
	"ip-forward": false,
	"ip-masq": false,
	"userland-proxy": false,
	"userland-proxy-path": "/usr/libexec/docker-proxy",
	"ip": "0.0.0.0",
	"bridge": "",
	"bip": "",
	"fixed-cidr": "",
	"fixed-cidr-v6": "",
	"default-gateway": "",
	"default-gateway-v6": "",
	"icc": false,
	"raw-logs": false,
	"allow-nondistributable-artifacts": [],
	"registry-mirrors": [],
	"seccomp-profile": "",
	"insecure-registries": [],
	"disable-legacy-registry": false,
	"no-new-privileges": false,
	"default-runtime": "runc",
	"oom-score-adjust": -500,
	"runtimes": {
		"runc": {
			"path": "runc"
		},
		"custom": {
			"path": "/usr/local/bin/my-runc-replacement",
			"runtimeArgs": [
				"--debug"
			]
		}
	}
}
```
