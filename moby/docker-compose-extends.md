# Compose 服务扩展 

+ [Extend services in Compose](https://docs.docker.com/compose/extends/)

Compose 支持两种共享通用配置的方法：

+ 1、通过 [使用多个 Compose 文件](https://docs.docker.com/compose/extends/#multiple-compose-files)
+ 2、使用 `extends` 字段扩展单个服务（3.x 已经不支持了，可以忽略该选项）

## 多个 Compose 文件

你可以使用多个 Compose 文件自定义 Compose 应用，以适配不同的环境或者工作流。

### 理解多个 Compose 文件

默认，Compose 读取两个文件，一个是 `docker-compose.yml`，以及另外一个可选的 `docker-compose.override.yml` 文件。按照约定，`docker-compose.yml` 包含了基本的配置。override 文件，顾名思义，包含的配置可以覆盖现有服务或者是全新服务配置。

如果一个服务定义多个文件中，Compose 会使用 [Adding and overriding configuration](https://docs.docker.com/compose/extends/#adding-and-overriding-configuration) 中的规则合并配置。

要使用多个覆盖文件，或者不同名称的覆盖文件，可以使用 `-f` 选项来指定文件列表。Compose 按照命令行指定配置的顺序来合并。具体见 [docker-compose 命令参考](https://docs.docker.com/compose/reference/overview/) 获取更多关于 `-f` 的信息。

```
$ docker-compose -f docker-compose.yml -f docker-compose.admin.yml run backup_db
```

## 添加和覆盖配置

将配置从原始服务复制到本地服务。如果原始服务和本地服务中都定义了配置选项，则本地值将替换或扩展原始值。

针对单值选项类似 `image`，`command` 或者 `mem_limit`，新值替换旧值。

```
# original service
command: python app.py

# local service
command: python otherapp.py

# result
command: python otherapp.py
```

对于多值选项类似 `ports`，`expose`，`external_links`，`dns`，`dns_search`，以及 `tmpfs`，Compose 会合并这些值：

```
# original service
expose:
  - "3000"

# local service
expose:
  - "4000"
  - "5000"

# result
expose:
  - "3000"
  - "4000"
  - "5000"
```

在 `environment`，`labels`，`volume` 和 `devices` 中，Compose 会以 local 优先的方式合并这些值：

```
# original service
environment:
  - FOO=original
  - BAR=original

# local service
environment:
  - BAR=local
  - BAZ=local

# result
environment:
  - FOO=original
  - BAR=local
  - BAZ=local
```

```
# original service
volumes:
  - ./original:/foo
  - ./original:/bar

# local service
volumes:
  - ./local:/bar
  - ./local:/baz

# result
volumes:
  - ./original:/foo
  - ./local:/bar
  - ./local:/baz
```
