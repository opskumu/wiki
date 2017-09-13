# Docker 配置

以下的配置说明，统一以 `CentOS7.3` 系统安装 Docker 版本说明，其它系统版本可能会有不同，这里不作具体介绍。

```
# docker version
Client:
 Version:         1.13.1
 API version:     1.26
 Package version: docker-1.13.1-25.gitb5e3294.el7.x86_64
 Go version:      go1.8.3
 Git commit:      b5e3294/1.13.1
 Built:           Fri Aug 11 15:30:49 2017
 OS/Arch:         linux/amd64

Server:
 Version:         1.13.1
 API version:     1.26 (minimum version 1.12)
 Package version: docker-1.13.1-25.gitb5e3294.el7.x86_64
 Go version:      go1.8.3
 Git commit:      b5e3294/1.13.1
 Built:           Fri Aug 11 15:30:49 2017
 OS/Arch:         linux/amd64
 Experimental:    false
```

## 相关配置文件

基本配置文件：

* `/etc/sysconfig/docker`
* `/etc/sysconfig/docker-storage`
* `/etc/sysconfig/docker-network`
* `/etc/docker/daemon.js`

systemd 服务配置：

* `/usr/lib/systemd/system/docker.service`

Docker 从 `1.12` 开始支持通过 `/etc/docker/daemon.js` 文件管理 Docker daemon 的配置选项。

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

### Daemon socket option

Docker daemon 可以三种不同类型的 Socket 监听 Docker API 请求：unix，tcp，fd。默认情况下，会创建一个名为 `/var/run/docker.sock` unix Socket 文件，该文件的访问权限需要是 root 权限或者属于 docker 组。如果有远程访问需求，那么则需要开启 tcp Socket。默认开启 tcp Socket，是没有任何加密和安全认证的，可以通过 HTTPS 加密 socket。

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

> Note: 正常情况下，不建议开启 tcp Socket 远程访问。如果有相关需求，建议通过 HTTPS 等安全方式加密。

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
