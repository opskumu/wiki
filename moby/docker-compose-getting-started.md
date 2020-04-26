# Docker Compose 入门

本页你构建一个简单的 Python web 应用通过 Docker Compose 运行。应用使用 Flask 框架以及使用 Redis 缓存。虽然示例使用 Python，但即使你不熟悉这些技术栈，你应该也可以理解。

## 准备

确保你已经安装了 [Docker Engine](https://docs.docker.com/compose/install/) 和 [Docker Compose](https://docs.docker.com/compose/install/)。你不需要安装 Python 或者 Redis，所有的这些由 Docker 镜像提供。

## 步骤 1：Setup

定义应用的依赖。

+ 1、创建一个项目目录

```
$ mkdir composetest
$ cd composetest
```

+ 2、在项目目录中创建一个名为 `app.py` 的文件并复制以下内容进去：

```
import time

import redis
from flask import Flask

app = Flask(__name__)
cache = redis.Redis(host='redis', port=6379)


def get_hit_count():
    retries = 5
    while True:
        try:
            return cache.incr('hits')
        except redis.exceptions.ConnectionError as exc:
            if retries == 0:
                raise exc
            retries -= 1
            time.sleep(0.5)


@app.route('/')
def hello():
    count = get_hit_count()
    return 'Hello World! I have been seen {} times.\n'.format(count)
```

这个示例中，在应用网络中 redis 容器的主机名是 `redis`。我们使用 Redis 默认的端口，`6379`。

+ 3、创建另外一个叫 `requirements.txt` 在你的项目目录并粘贴：

```
flask
redis
```

## 步骤 2：创建一个 Dockerfile

在这一步中，你需要写一个 Dockerfile 来构建一个 Docker 镜像。这个镜像包含 Python 应用的所有依赖项，包括 Python 本身。

在你的项目目录中，创建一个名为 `Dockerfile` 的文件并粘贴：

```
FROM python:3.7-alpine
WORKDIR /code
ENV FLASK_APP app.py
ENV FLASK_RUN_HOST 0.0.0.0
RUN apk add --no-cache gcc musl-dev linux-headers
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
COPY . .
CMD ["flask", "run"]
```

这个告诉 Docker：

+ 以 Python 3.7 镜像为基础构建镜像
+ 设置工作目录为 `/code`
+ 设置 `flask` 命令用到的环境变量
+ 安装 gcc，以便诸如 MarkupSafe 和 SQLAlchemy 之类 Python 包的编译加速
+ 拷贝 `requirement.txt` 并安装 Python 依赖
+ 拷贝当前的目录 `.` 到镜像中的工作目录中
+ 设置容器的默认启动命令为 `flask run`

关于更多编写 Dockerfile 的信息，详见 [Docker 用户指南](https://docs.docker.com/develop/) 和 [Dockerfile 参考](https://docs.docker.com/engine/reference/builder/)。

## 步骤 3：在 Compose 文件中定义服务

在项目目录下创建一个叫 `docker-compose.yml` 文件，并粘贴：

```
version: '3'
services:
  web:
    build: .
    ports:
      - "5000:5000"
  redis:
    image: "redis:alpine"
```

Compose 文件定义两个服务：`web` 和 `redis`。

### Web 服务

Web 服务使用了当前目录下的 `Dockerfile` 构建的镜像。然后把容器的端口 5000 映射到主机 5000 端口上。此示例使用的是 Flask web 服务器的默认端口，`5000`。

### Redis 服务

Redis 服务使用了 Docker Hub 仓库的公共 [Redis](https://registry.hub.docker.com/_/redis/) 镜像。

## 步骤 4：通过 Compose 构建和运行你的 app

+ 1、从你的项目目录，通过运行 `docker-compose up` 启动你的应用。

```
$ docker-compose up
Creating network "composetest_default" with the default driver
Creating composetest_web_1 ...
Creating composetest_redis_1 ...
Creating composetest_web_1
Creating composetest_redis_1 ... done
Attaching to composetest_web_1, composetest_redis_1
web_1    |  * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
redis_1  | 1:C 17 Aug 22:11:10.480 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
redis_1  | 1:C 17 Aug 22:11:10.480 # Redis version=4.0.1, bits=64, commit=00000000, modified=0, pid=1, just started
redis_1  | 1:C 17 Aug 22:11:10.480 # Warning: no config file specified, using the default config. In order to specify a config file use redis-server /path/to/redis.conf
web_1    |  * Restarting with stat
redis_1  | 1:M 17 Aug 22:11:10.483 * Running mode=standalone, port=6379.
redis_1  | 1:M 17 Aug 22:11:10.483 # WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.
web_1    |  * Debugger is active!
redis_1  | 1:M 17 Aug 22:11:10.483 # Server initialized
redis_1  | 1:M 17 Aug 22:11:10.483 # WARNING you have Transparent Huge Pages (THP) support enabled in your kernel. This will create latency and memory usage issues with Redis. To fix this issue run the command 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' as root, and add it to your /etc/rc.local in order to retain the setting after a reboot. Redis must be restarted after THP is disabled.
web_1    |  * Debugger PIN: 330-787-903
redis_1  | 1:M 17 Aug 22:11:10.483 * Ready to accept connections
```

Compose 拉取 Redis 镜像，从你的代码中构建一个镜像，并启动你定义的服务。这个示例中，代码会在构建时复制到镜像中。

+ 2、浏览器访问 http://localhost:5000/ 查看应用运行

如果你在本地运行 Docker，那么浏览器通过 http://localhost:5000/ 访问可以看到 `Hello World` 的信息。如果不能解析，可以尝试 http://127.0.0.1:5000。

如果你在 Mac 或者 Windows 上使用 Docker Machine，你可以使用 `docker-machine ip MACHINE_VM` 获取你 Docker 主机的 IP 信息。然后在浏览器打开 `http://MACHINE_VM_IP:5000`。

你会看到浏览器上的信息：

```
Hello World! I have been seen 1 times.
```

+ 3、刷新页面

数字会递增

```
Hello World! I have been seen 2 times.
```

+ 4、切换到另外一个终端窗口，执行 `docker images ls` 列出本地镜像。

```
$ docker image ls
REPOSITORY              TAG                 IMAGE ID            CREATED             SIZE
composetest_web         latest              e2c21aa48cc1        4 minutes ago       93.8MB
python                  3.4-alpine          84e6077c7ab6        7 days ago          82.5MB
redis                   alpine              9d8fa9aa0e5b        3 weeks ago         27.5MB
```

你可以通过 `docker inspect <tag or id>` 检查镜像。

+ 5、停止应用，在第二个打开的终端下，进入你的项目目录中执行 `docker-compose down`，或者直接在启动应用的原始终端执行 CTRL+C  终止应用。

## 步骤 5：编辑你的 Compose 文件并加入 mount 映射

在你的项目目录中编辑 `docker-compose.yml`，并给 `web` 服务添加一个 [bind mount](https://docs.docker.com/storage/bind-mounts/)：

```
version: '3'
services:
  web:
    build: .
    ports:
      - "5000:5000"
    volumes:
      - .:/code
    environment:
      FLASK_ENV: development
  redis:
    image: "redis:alpine"
```

这个新的 `volumes` 字段挂载主机的项目目录到容器中的 `/code` 下，允许你即时修改代码，而无需重新构建镜像。`environment` 字段设置 `FLASK_ENV` 环境变量，告诉 `flask run` 运行在开发模式，在代码变更时自动加载。这种模式仅能用于开发环境。

## 步骤 6：使用 Compose 重新构建和运行应用

从你的项目目录下，键入 `docker-compose up` 通过更新的 Compose 文件来构建应用，并运行。

```
$ docker-compose up
Creating network "composetest_default" with the default driver
Creating composetest_web_1 ...
Creating composetest_redis_1 ...
Creating composetest_web_1
Creating composetest_redis_1 ... done
Attaching to composetest_web_1, composetest_redis_1
web_1    |  * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
...
```

在浏览器上检查 `Hello World`，并刷新查看数量递增。 

## 步骤 7：更新应用

因为现在应用代码是使用卷挂载到容器中的，你可以更改代码并立即查看变化，而不用重新构建镜像。

+ 1、修改 `app.py` 并保存。如，把 `Hello World!` 变为 `Hello from Docker!`：

```
return 'Hello from Docker! I have been seen {} times.\n'.format(count)
```

+ 2、浏览器刷新应用 URL，欢迎词是更新的，并且数量还是递增的

## 步骤 8：试用其他命令

如果你想在后台运行应用，你可以传递 `-d` 选项到 `docker-compose up` 并使用 `docker-compose ps` 查看当前运行状况：

```
$ docker-compose up -d
Starting composetest_redis_1...
Starting composetest_web_1...

$ docker-compose ps
Name                 Command            State       Ports
-------------------------------------------------------------------
composetest_redis_1   /usr/local/bin/run         Up
composetest_web_1     /bin/sh -c python app.py   Up      5000->5000/tcp
```

`docker-compose run` 允许运行服务的一次性命令。如查看 `web` 服务当前的环境变量：

```
$ docker-compose run web env
```

通过 `docker-compose --help` 查看其他可用的命令。你也可以安装 bash 和 zsh  [命令补全](https://docs.docker.com/compose/completion/) 来查看可用的指令。

如果你使用 `docker-compose up -d` 启动，可以使用如下命令停止：

```
$ docker-compose stop
```

你可以使用 `down` 命令关闭所有内容，完全删除容器。传递 `--volumes` 选项还可以移除 Redis 数据卷。

```
$ docker-compose down --volumes
```

至此，你已经基本了解了 Compose 工作机制。
