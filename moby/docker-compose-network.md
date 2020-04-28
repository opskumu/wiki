# Compose 网络

默认 Compose 会给应用设置一个单独的网络。每个服务中的容器加入到默认的网络中，互相可以访问，并通过和容器名一样的主机名来服务发现。

> 注意：应用网络命名依赖项目名，项目名称基于当前所在目录名。可以通过 `--project-name` 选项或者 `COMPOSE_PROJECT_NAME` 环境变量来覆盖。

例如，你的 app 所在目录为 `myapp`，你的 `docker-compose.yml` 内容如下：

```
version: "3"
services:
  web:
    build: .
    ports:
      - "8000:8000"
  db:
    image: postgres
    ports:
      - "8001:5432"
```

当你运行 `docker-compose up`，会发生如下情况：

+ 1、一个命名为 `myapp_default` 的网络创建
+ 2、一个使用 `web` 配置的容器创建。它以 `web` 为名加入到 `myapp_default` 网络
+ 3、一个使用 `db` 配置的容器创建。它以 `db` 为名加入到 `myapp_default` 网络

现在每个容器都可以通过主机名 `web` 或 `db` 获取相应容器的 IP 地址。如 `web` 应用代码可以通过 `postgres://db:5432` 连接使用 Postgres 数据库。

## 更新容器

如果服务配置变更了，并且运行 `docker-compose up` 更新它，旧的容器会被移除，新的容器会以不同的 IP 地址但是相同的名字加入到网络。运行的容器可以使用名字连接到新的地址，但是旧的地址已经不再提供服务。

如果有任何容器与旧的容器连接，那么会被关闭。容器有责任检测这种情况，并再次查找名称重新连接。

## Links

Links 允许定义额外的别名，通过该别名可以从另外一个服务访问服务。默认情况下，任何服务都可以通过服务名访问，不需要额外启用。接下来的例子中，`db` 服务可以被 `web` 以 `db` 和 `database` 主机名访问到：

```
version: "3"
services:

  web:
    build: .
    links:
      - "db:database"
  db:
    image: postgres
```

## [指定自定义网络](https://docs.docker.com/compose/networking/#specify-custom-networks)

```
version: "3"
services:

  proxy:
    build: ./proxy
    networks:
      - frontend
  app:
    build: ./app
    networks:
      - frontend
      - backend
  db:
    image: postgres
    networks:
      - backend

networks:
  frontend:
    # Use a custom driver
    driver: custom-driver-1
  backend:
    # Use a custom driver which takes special options
    driver: custom-driver-2
    driver_opts:
      foo: "1"
      bar: "2"
```

## 配置默认网络

```
version: "3"
services:

  web:
    build: .
    ports:
      - "8000:8000"
  db:
    image: postgres

networks:
  default:
    # Use a custom driver
    driver: custom-driver-1
```

## 使用之前已存在的网络

```
networks:
  default:
    external:
      name: my-pre-existing-network
```
