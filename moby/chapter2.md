# Docker 安装与配置

## 安装

上文说的 `Moby` 在 Docker 官网称为社区版，支持的系统可以参见 [Install Docker](https://docs.docker.com/engine/installation/)。从 Docker `17.03` 开始，Docker 使用基于时间的版本发行机制。支持的系统除了常见的 Linux 发行版外，还支持 macOS、Windows 系统。本文只介绍基于 macOS 和 CentOS 这两个系统的 Docker 安装，关于更多系统的安装方式参见前面提到的官网安装文档。

### macOS Docker 安装

关于 macOS Docker 的安装方式官方教程已经很详细了，[Install Docker for Mac](https://docs.docker.com/docker-for-mac/install/)。目前针对 Mac 系统，官方的 Docker 支持 `OS X El Capitan 10.11` 或者更新的 `macOS` 发行版，针对硬件也有限制，只支持 2010 或者更新的 Mac。

下载 [Get Docker for Mac [stable]](https://download.docker.com/mac/stable/Docker.dmg) dmg 文件，双击即可安装，安装之后点击运行 Docker。因为国内下载镜像比较慢的原因，所以需要额外配置一下国内的 Registry mirror 用以加速镜像下载：

<center><img src="images/mac-docker-config.png" width="500" height="600" alt="mac docker config" /></center>

目前国内有很多家企业提供公共的镜像加速服务：

* 网易云镜像加速 [http://hub-mirror.c.163.com/](http://hub-mirror.c.163.com/)
* Docker 中国官方镜像加速 [https://registry.docker-cn.com](https://registry.docker-cn.com)

除以上两个公开的加速器外，还有阿里云、Daocloud 等厂商也提供加速服务，不过需要通过注册帐号登录才可以获取专有的镜像加速服务地址。

> __注：__ macOS 上运行 Docker，需要注意的是删除镜像占用空间也不会释放，所以如果你的 Mac 磁盘不是很大的话，还是得悠着点用，具体的详情可以参见这个帖子 [Docker.qcow2 never shrinks - disk space usage leak in docker for mac](https://github.com/docker/for-mac/issues/371)

### CentOS7 Docker 安装

关于 Docker 社区版在 CentOS 上的安装，官网也提供了教程 [Get Docker CE for CentOS](https://docs.docker.com/engine/installation/linux/docker-ce/centos/)。

## Docker 配置
