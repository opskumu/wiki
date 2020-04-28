# Compose 环境变量

+ [Environment variables in Compose](https://docs.docker.com/compose/environment-variables/)

## 在 Compose 文件中替换环境变量

你可以在 shell 中使用环境变量来填充 Compose 文件中的值：

```
web:
  image: "webapp:${TAG}"
```

可以通过 Compose 文件参考 [变量替换](https://docs.docker.com/compose/compose-file/#variable-substitution) 章节获取更多信息。

## 在容器中设置环境变量

可以通过 ['environment' 键](https://docs.docker.com/compose/compose-file/#environment) 来设置服务中容器的环境变量，同 `docker run -e VARIABLE=VALUE ...`：

```
web:
  environment:
    - DEBUG=1
```

## 传递环境变量给容器

你可以使用 ['environment' 键](https://docs.docker.com/compose/compose-file/#environment) 从 shell 直接传递环境变量到服务中的容器，而不赋值，同 `docker run -e VARIABLE ...`：

```
web:
  environment:
    - DEBUG
```

容器中 `DEBUG` 变量的值取自 Compose 运行的 shell 同名环境变量的值。

## "env_file" 配置项

你可以通过 ['env_file' 选项](https://docs.docker.com/compose/compose-file/#env_file) 让一个服务的容器从外部文件中传递多个环境变量，类似 `docker run --env-file=FILE ...`：

```
web:
  env_file:
    - web-variables.env
```

## 通过 'docker-compose run' 设置环境变量

同 `docker run -e` 一样，你可以执行 `docker-compose run -e` 设置环境变量：

```
docker-compose run -e DEBUG=1 web python console.py
```

也可以传递一个没有值的环境变量，此时则会继承当前 shell 的环境变量值：

```
docker-compose run -e DEBUG web python console.py
```

## ".env" 文件

你可以在名为 '.env' 的环境变量文件中，为 Compose 中引用或者用于配置 Compose 的任何环境变量设置默认值：

```
$ cat .env
TAG=v1.5

$ cat docker-compose.yml
version: '3'
services:
  web:
    image: "webapp:${TAG}"
```

当你运行 `docker-compose up`，上面定义的 Web 服务使用镜像 `webapp:v1.5`。你可以使用 config 命令验证这一点，该命令会将你解析的应用程序配置输出到终端：

```
$ docker-compose config

version: '3'
services:
  web:
    image: 'webapp:v1.5'
```

Shell 中的值优先于 `.env` 文件中指定的值。如果在 Shell 上把 `TAG` 设置为其它值，则会被替换为该值：

```
$ export TAG=v2.0
$ docker-compose config

version: '3'
services:
  web:
    image: 'webapp:v2.0'
```

当你在多个文件中设置了相同的环境变量时，以下为 Compose 使用的优先级顺序：

+ 1、Compose 文件
+ 2、Shell 环境变量的值
+ 3、环境变量文件（.env）
+ 4、Dockerfile
+ 5、环境变量未定义

在下面的例子中，我们在环境变量文件和 Compose 文件中设置了同样的环境变量：

```
$ cat ./Docker/api/api.env
NODE_ENV=test

$ cat docker-compose.yml
version: '3'
services:
  api:
    image: 'node:6-alpine'
    env_file:
     - ./Docker/api/api.env
    environment:
     - NODE_ENV=production
```

运行容器时，Compose 中定义的环境变量优先：

```
$ docker-compose exec api node

> process.env.NODE_ENV
'production'
```

仅当 Compose 文件中没有 'enviroment' 或者 'env_file' 条目时，才会对 Dockerfile 中的 `ARG` 或 `ENV` 设置进行评估。

> 注意：针对 NodeJS 容器，如果有一个 `package.json` 条目 `script:start`，类似 `NODE_ENV=test node server.js`，那么这将会覆盖 `docker-compose.yml` 文件中的环境变量。（其实不仅仅是 NodeJS，所有容器启动脚本相关的操作都会覆盖系统自身的环境变量）

## 通过环境变量配置 Compose

这儿有一些环境变量来配置 Docker Compose 的命令行行为。他们以 `COMPOSE_` 或 `DOCKER_` 开头，具体可以见 [CLI Environment Variables](https://docs.docker.com/compose/reference/envvars/)。
