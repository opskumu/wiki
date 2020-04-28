# Compose 启动顺序控制

+ [Control startup order](https://docs.docker.com/compose/startup-order/)

你可以通过 [depends_on](https://docs.docker.com/compose/compose-file/#depends_on) 选项控制服务启动顺序。Compose 总是按照依赖的顺序启动和停止容器，依赖包括 `depends_on`，`links`，`volumes_from` 以及 `network_mode: "service:..."`。

Compose 启动不会等到容器中服务就绪，而只要容器启动即可。简单来说，Compose 不管这一层，官档的意思是应用程序应该考虑应对依赖的服务没有启动的情况。最好的方式就是代码中处理好这块逻辑，如果不行的话可以封装一些脚本曲线解决问题：

+ 使用如 [wait-for-it](https://github.com/vishnubob/wait-for-it)，[dockerize](https://github.com/jwilder/dockerize) 或者 shell 兼容的 [wait-for](https://github.com/Eficode/wait-for) 这类的工具。这些小型的封装脚本，可以把这些加入到镜像中，以轮询给定的主机和端口，直到它接受 TCP 连接为止。如使用 `wait-for-it.sh` 或者 `wait-for` 封装你的服务命令：

```
version: "3"
services:
  web:
    build: .
    ports:
      - "80:8000"
    depends_on:
      - "db"
    command: ["./wait-for-it.sh", "db:5432", "--", "python", "app.py"]
  db:
    image: postgres
```

> 使用这类的工具好处使方便，坏处也有，比如服务端口监听并不表示服务已经可以对外提供服务了，这种细粒度的事情，这些脚本做不了，可以使用下面的解决方式。

+ 或者编写自己的封装脚本以执行更特定于应用程序运行状态的检测，如等到 Postgres 准备好接受命令为止：

```
#!/bin/sh
# wait-for-postgres.sh

set -e
  
host="$1"
shift
cmd="$@"
  
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "$host" -U "postgres" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done
  
>&2 echo "Postgres is up - executing command"
exec $cmd
```

定制好了之后通过如下方式设置：

```
command: ["./wait-for-postgres.sh", "db", "python", "app.py"]
```
