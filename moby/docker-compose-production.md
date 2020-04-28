# 生产中使用 Compose

+ [Use Compose in production](https://docs.docker.com/compose/production/)

部署应用程序最简单的方法是在单个服务器上运行它，类似运行开发环境的方式。如果要扩容应用程序，则可以在 Swarm 集群上运行 Compose 应用。

## 修改 Compose 文件以适配生产

你可能要修改你的应用配置以使它可以生产就绪的。这些变化包括：

+ 移除程序代码绑定的卷，以使得代码运行在容器中并且不能被外部更改
+ 在主机上绑定不同的端口
+ 设置不同的环境变量，如调整日志级别降低输出，或者指定外部服务的设置如电子邮件服务器
+ 指定重启策略，如 `restart: always` 以避免停机
+ 添加额外的服务，如日志收集服务

基于这些原因，可以考虑定义一个附加的 Compose 文件，如 `production.yml`，指定生产适用的配置。这个配置只需要包含源 Compose 文件需要变更的部分，以覆盖源文件创建新的配置。

```
docker-compose -f docker-compose.yml -f production.yml up -d
```

## 部署变更

当你变更了你的应用代码，记得重新构建你的镜像并重新创建应用容器。重新部署名为 `web` 的服务，使用：

```
$ docker-compose build web
$ docker-compose up --no-deps -d web
```

这首先会创建 `web` 镜像，然后仅停止、销毁以及重新创建 `web` 服务。`--no-deps` 选项防止 Compose 重新创建 Web 依赖的任何服务。
