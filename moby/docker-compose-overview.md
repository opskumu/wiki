# Docker Compose

## Docker Compose 概览

Compose 是一个用于定义和运行多容器 Docker 应用的工具。通过 Compose，你使用一个 YAML 文件来配置你的应用的服务。然后，通过一个命令，从你的配置中创建和启动所有的服务。为了学习更多 Compose 所有的特性，可以查看 [特性列表](https://docs.docker.com/compose/#features)。

Compose 可以在所有的环境中工作：生产，预发，开发，测试以及 CI 工作流。你可以从 [常用案例](https://docs.docker.com/compose/#common-use-cases) 中学到更多。

使用 Compose 基本三步走：

+ 1、通过 `Dockerfile` 定义你的应用环境，以便在任何场景复用
+ 2、在 `docker-compose.yml` 中定义组成应用程序的服务，以便他们能在隔离的环境中一同运行
+ 3、运行 `docker-compose up`，Compose 启动和运行你整个应用

一个 `docker-compose.yml` 看起来像这样：

```
version: '2.0'
services:
  web:
    build: .
    ports:
    - "5000:5000"
    volumes:
    - .:/code
    - logvolume01:/var/log
    links:
    - redis
  redis:
    image: redis
volumes:
  logvolume01: {}
```

获取更多的 Compose 文件信息，可以见 [Compose 文件参考](https://docs.docker.com/compose/compose-file/)

Compose 有一系列命令管理应用的整个生命周期：

+ 启动，停止和重建服务
+ 查看运行服务的状态
+ 查看服务的日志输出
+ 在服务上运行一次性命令

## Compose 文档

+ [安装 Compose](https://docs.docker.com/compose/install/)
+ [Compose 入门](https://docs.docker.com/compose/gettingstarted/)
+ [Django 服务 Compose 入门](https://docs.docker.com/compose/django/)
+ [Rails 服务 Compose 入门](https://docs.docker.com/compose/rails/)
+ [WordPress 服务 Compose 入门](https://docs.docker.com/compose/wordpress/)
+ [常见问题](https://docs.docker.com/compose/faq/)
+ [命令行参考](https://docs.docker.com/compose/reference/)
+ [Compose 文件参考](https://docs.docker.com/compose/compose-file/)

## 特性

Compose 的这些特性让它更高效：

+ [单个主机多环境隔离](https://docs.docker.com/compose/#multiple-isolated-environments-on-a-single-host)
+ [创建容器时保留卷数据](https://docs.docker.com/compose/#preserve-volume-data-when-containers-are-created)
+ [仅在变更时重新创建容器](https://docs.docker.com/compose/#only-recreate-containers-that-have-changed)
+ [通过变量来控制不同环境](https://docs.docker.com/compose/#variables-and-moving-a-composition-between-environments)

### 单个主机多环境隔离

Compose 通过一个项目名来隔离隔离环境。你可以在若干不同的上下文中使用这个项目名：

+ 在一个开发机上，创建单个环境的多个副本，例如当你想针对一个项目每个功能分支各运行一个稳定的副本
+ 在一个 CI 服务器上，为了防止内部版本相互干扰，可以将项目名设置为唯一的版本号
+ 在共享主机或者开发机上，以防止可能使用相同服务名称的不同项目相互干扰

默认的项目名是项目目录名。你可以通过 `-p` 命令选项或者 `COMPOSE_PROJECT_NAME` 环境变量自定义项目名。

### 创建容器时保留卷数据

Compose 保留服务用到的所有卷。当 `docker-compose up` 运行时，如果发现任何之前已经运行的容器，它会从旧的容器复制数据到新的容器。这一操作确保你在卷中创建的任何数据都不会丢失。如果你在 Windows 机器上使用 `docker-compose`，查看 [环境变量](https://docs.docker.com/compose/reference/envvars/) 并根据特定需求调整环境变量。

### 仅在变更时重新创建容器

Compose 缓存用于创建容器的配置。当你重启一个没有任何变更的服务时，Compose 会重新使用现有的容器。重复使用容器意味着你可以快速更改环境。

### 通过变量来控制不同环境

Compose 支持 Compose 文件中的变量。你可以使用这些变量来针对不同的环境或不同的用户自定义。具体见 [变量替换](https://docs.docker.com/compose/compose-file/#variable-substitution)。

你可以使用 `extends` 字段扩展 Compose 文件或者通过创建多个 Compose 文件。具体见 [扩展](https://docs.docker.com/compose/extends/)。

## 常见案例

Compose 可以用在不同的方式中。下面概述了一些常用的案例。

### 开发环境

当你开发一个软件时，隔离环境运行应用和交互是至关重要的。Compose 命令行工具可用于创建环境并与之交互。

[Compose 文件](https://docs.docker.com/compose/compose-file/) 提供了文档化和配置应用所有服务依赖项（数据库，队列，缓存，Web 服务 APIs 等等）的一种方法。使用 Compose 命令行工具，你可以使用单个命令（`docker-compose up`）为每个依赖创建和启动一个或多个容器。

这些功能为开发者提供了一种方便的方法来开始一个项目。Compose 可以将多页的 “开发者入门指南” 简化为单个机器可读的 Compose 文件和一些命令。

### 自动化测试环境

自动化测试套件是任何持续部署或者持续集成过程的重要组成部分。自动化端到端的测试需要一个环境来运行测试。Compose 提供了快捷的方式为测试套件创建和销毁隔离的测试环境。

通过在 [Compose 文件](https://docs.docker.com/compose/compose-file/) 中定义完整的环境，你只需要几个命令即可创建和销毁这些环境：

```
$ docker-compose up -d
$ ./run_tests
$ docker-compose down
```

### 单主机部署

Compose 一直专注于开发和测试工作流，但是每个版本都会在面向生产上有一些进展并提供了相应的功能。你可以使用 Compose 部署到远程 Docker Engine。Docker Engine 可以是配备 [Docker Machine](https://docs.docker.com/machine/overview/) 的单个实例或者整个 [Docker Swarm](https://docs.docker.com/engine/swarm/) 集群。

有关面向生产特性的详细信息，可以见文档 [compose in production](https://docs.docker.com/compose/production/)。

## 发行说明

要获取 Docker Compose 过去和现在发行版本的详细列表，见 [CHANGELOG](https://github.com/docker/compose/blob/master/CHANGELOG.md)。

## 获取帮助

Docker Compose 还在积极开发中。如果你需要帮助，想做出一些贡献，或者只是想和志趣相投的人谈论该项目，我们有许多开放的沟通渠道。

+ 反馈 Bug 或者文件功能请求：使用 [issue tracker on Github](https://github.com/docker/compose/issues)
+ 需要实时讨论该项目：Slack 加入 `#docker-compose` 频道
+ 贡献代码或者文档变更：提交 [pull request on Github](https://github.com/docker/compose/pulls)
