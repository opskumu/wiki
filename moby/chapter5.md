# 镜像构建

虽然可以通过 [Docker hub](https://hub.docker.com/) 获取到公共镜像，但是针对自己的应用 Docker 化的时候，我们必须要定制镜像了。镜像构建需要引入 `Dockerfile` 文件，`Dockerfile` 是一个包含创建镜像所有命令的文本文件，Docker 通过 `Dockerfile` 的内容来自动构建镜像。

## Dockerfile

### 用法

`docker build` 命令构建镜像需要一个 `Dockerfile` 和一个构建环境（context）。

> **[info] 标注**  
> 关于构建环境可以是文件系统的具体目录路径也可以是一个 URL，其中 URL 需要是一个 Git 仓库地址。

镜像构建环境是一个递归处理的过程，针对目录来说，则遍历目录下的所有子目录，而 URL 则囊括 Git 仓库本身和它的子模块。镜像构建是通过 Docker daemon 来实现的，而不是客户端。构建开始时，构建进程会把构建环境整个发送给 Docker daemon。假如你的环境是本地文件系统的一个目录，那么尽可能的只包括 `Dockerfile` 和镜像构建所需要的文件。

> **[warning] 警告**  
> 不要使用 root 目录 `/` 作为构建环境，否则会发送当前整个文件系统给 Docker daemon。

为了提升构建性能，可以通过在当前构建环境根目录下创建 `.dockerignore` 文件来排除一些不必要的文件和目录（类似 `.gitignore`）。

可以通过 `-f` 选项来指定 `Dockerfile`，如果不指定则 `docker build` 默认读取当前名为 Dockerfile 的文件。

```
$ docker build .                            # 默认读取当前目录下名为 Dockerfile 的文件
$ docker build -f /path/to/a/Dockerfile .   # 指定 Dockerfile
```

通过 `-t` 可以指定镜像仓库和标签:

```
$ docker build -t shykes/myapp .
```

`-t` 选项可以指定多次：

```
$ docker build -t shykes/myapp:1.0.2 -t shykes/myapp:latest .
```

在构建过程中，Docker daemon 会逐个运行 `Dockerfile` 中的指令，在必要时将每条指令的结果提交成为一个新的镜像，并输出新的镜像 ID。Docker daemon 会自动清除发送过去的环境（context）。Docker 中每个指令都是独立的，一条指令创建一个镜像。因为镜像的分层机制，Docker 构建过程中会利用中间镜像（缓存），用来提升构建效率。

构建缓存只能用于拥有同一个本地父链（local parent chain）的镜像。意思就是说这些镜像由之前历史构建创建的或者整条镜像链都是由 docker 加载的。如果希望使用特定镜像的构建缓存，则可以使用 `--cache-from` 选项指定，`--cache-from` 不需要拥有一个父链并且可以从其它镜像仓库获取。

> **[info] 标注**  
> 这段描述的有些晦涩，另外 `--cache-from` 实际过程中应该使用的很少，笔者基本没有这样的应用场景。

### 格式

`Dockerfile` 的格式是：

```
# Comment 通过 # 号注释
INSTRUCTION arguments
```

> **[info] 标注**  
> `Dockerfile` 指令并不区分大小写，但是为了区分，建议指令统一采用 `大写`

Docker 运行 `Dockerfile` 指令是顺序执行的，一个 `Dockerfile` 文件必须以 `FROM` 指令开始。`FROM` 指令指定了构建镜像的基础镜像。

### 环境变量替换

通过 `ENV` 可以在 Dockerfile 中声明一个变量，有些指令可以直接通过 `$variable_name` 或者 `${variable_name}` 获取变量（这种方式同 bash 中引用一样）。当然，`${variable_name}` 还支持标准的 `bash` 修饰符：

* `${variable:-word}` 表示如果 `variable` 有值则使用该值，否则为值 `word`
* `${variable:+word}` 表示如果 `variable` 有值则使用 `word`，否则为空值

还可以通过 `\` 转义环境变量：

```
FROM busybox
ENV foo /bar
WORKDIR ${foo}   # WORKDIR /bar
ADD . $foo       # ADD . /bar
COPY \$foo /quux # COPY $foo /quux 此处变量被转义
```

不是所有的 `Dockerfile` 指令支持环境变量，当前支持的有如下指令：

* `ADD`
* `COPY`
* `ENV`
* `EXPOSE`
* `FROM`
* `LABEL`
* `STOPSIGNAL`
* `USER`
* `VOLUME`
* `RUN`
* `WORKDIR`

### .dockerignore 文件

前面已经提到过 `.dockerignore`， 它的功能类似 `.gitignore`。它需要存放在构建环境根目录下才会起作用，通过 `.dockerignore` 定义匹配规则来排除文件和目录。通过 `.dockerignore` 可以避免不必要的大型或敏感文件和目录发送给 Docker daemon，从而避免 `ADD` 或者 `COPY` . 拷贝这些文件和目录。

简单的 `.dockerignore` 文件如下：

```
# comment
*/temp*
*/*/temp*
temp?
```

| 规则 | 解释 |
|:-- | :-- |
| `# comment` | 注释，忽略 |
| `*/temp*` | 排除根目录一级子目录下所有以 `temp` 开头的文件和目录。如 `/somedir/temp`、`/somedir/temporary.txt` 都将会被排除 |
| `*/*/temp*` | 排除根目录下二级子目录下所有以 `temp` 开头的文件和目录，如 `/somedir/subdir/temporary.txt` 会被排除 |
| `temp?` | ? 号表示占用一个字符串，如 `/tempa`、`/tempb` 文件目录都会被排除  |

```
.
├── a               # 不匹配规则被保留
│   ├── b           # 不匹配规则被保留
│   │   └── tempb   # 匹配 */*/temp* 规则被排除
│   └── tempa       # 匹配 */temp* 规则被排除
├── temp            # 不匹配规则被保留
└── tempc           # 匹配规则 temp? 被排除
```


`.dockerignore` 的匹配规则遵循 Go 的 [filepath.Match](https://golang.org/pkg/path/filepath/#Match) 规则。除了该规则外，Docker 还支持了一些特殊的通配符，`**` 匹配任意层级的目录。例如，`**/*.go` 将排除构建环境根目录下所有以 `.go` 为后缀的文件。`!` 表示忽略排除，如下：

```
*.md
!README.md
```

表示排除根目录当前层级除了`README.md` 外所有以 `.md` 为后缀的文件。

```
.
├── README.md       # 匹配规则被保留
├── a.md            # 匹配规则被排除
└── temp            # 不匹配规则被保留
    └── t.md        # 不匹配规则被保留
```

> **[info] 标注**  
> 匹配是有顺序的，如果前后的规则有重叠或者冲突，则后面的规则生效。如果 `!README.md` 在 `*.md` 之前，则以 `*.md` 为规则，`README.md` 依然会被排除。

可以通过 `.dockerignore` 来排除 `Dockerfile` 和 `.dockerignore` 文件。但是这些文件依然会发送到 Docker daemon。不过，`ADD` 和 `COPY` 指令将不会拷贝它们。

### 指令

#### FROM

`FROM` 用来指定构建镜像的基础镜像，如果本地没有指定的镜像，在构建过程中会自动从相应镜像仓库 pull。如果 `FROM` 语句没有指定镜像标签，则默认使用 `latest` 标签。

```
FROM <image>[:<tag>]
```

#### RUN

`RUN` 有两种格式：

* `RUN <command>` （shell 格式，命令会在 shell 中执行，默认是 `/bin/sh -c`）
* `RUN ["executable", "param1", "param2"]` （exec 格式）

`RUN` 指令会在当前镜像的新层上执行命令并提交执结果，后续 `Dockerfile` 的指令操作则基于此最新提交的镜像。分层 `RUN` 指令提交方式是 Docker 的核心理念，首先提交的成本比较低，并且容器可以基于任何历史镜像点创建，好比源码版本控制（`git checkout`）。

> **[info] 标注**  
> `exec` 格式会被解析成一个 JSON 数组，所以必须使用 __双引号__ ，而非单引号。`exec` 格式执行命令不会调用 command shell，所以也不会继承环境变量。

```
RUN ["echo", "$HOME"]
```

这种方式不会输出 `HOME` 变量，正确在 `exec` 这种格式下集成环境变量可以使用如下方式：

```
RUN ["/bin/sh", "-c", "echo", "$HOME"]
```

`RUN` 指令操作缓存在下次构建时不会自动失效，如果不想利用缓存，则可以添加 `--no-cache` 选项禁用缓存，即 `docker build --no-cache`。

正常情况下，建议使用 `RUN <command>` shell 格式类型：

```
RUN yum install -y rsync && \
    yum clean all
```

简单来说，`RUN` 指令主要是在镜像构建过程中，执行一系列的 Linux 命令以达到定制镜像的目的。

#### CMD

`CMD` 有三种格式：

* `CMD ["executable","param1","param2"]`（exec 格式, 推荐使用这种格式）
* `CMD ["param1","param2"]` （作为 `ENTRYPOINT` 指令参数）
* `CMD command param1 param2` （shell 格式，默认 `/bin/sh -c`）

`Dockerfile` 只能有一个 `CMD` 指令，如果有多个，则只有最后一个 `CMD` 会生效。`CMD` 的主要作用是用于容器启动的默认执行命令或者作为 `ENTRYPOINT` 指令的参数。

> **[info] 标注**  
> 同 `RUN` 指令的 `exec` 格式，`CMD` 指令的 `exec` 格式也会被解析成一个 JSON 数组，所以必须使用 __双引号__ ，而非单引号。同样 `exec` 格式执行命令不会调用 command shell，所以也不会继承环境变量。

简单来说，不同于 `RUN` 只会在构建就像时执行，`CMD` 是在容器启动时才会执行里面的命令，并且在 `Dockerfile` 中只能有一个 `CMD`。

#### LABEL

```
LABEL <key>=<value> \
      <key>=<value> \
      <key>=<value> ...
```

`LABEL` 指令主要用于添加镜像的元数据，是一个 key-value 键值对，使用示例如下：

```
LABEL "com.example.vendor"="ACME Incorporated"
LABEL com.example.label-with-value="foo"
LABEL version="1.0"
LABEL description="This text illustrates \
that label-values can span multiple lines."
```

通过 `docker inspect` 可以查看镜像相关的标签信息。

#### EXPOSE

```
EXPOSE <port> [<port>/<protocol>...]
```

`EXPOSE` 指令通知 Docker 在容器运行时对外暴露的监听端口。可以指定 `TCP` 或者 `UDP`，默认是 TCP。`EXPOSE` 指令并不会实际对外暴露指定端口，如果需要暴露，则还需要在 `docker run` 时添加 `-p` 或者 `-P` 选项，其中 `-p` 可以指定某个或某几个端口映射，而 `-P` 选择则把 `EXPOSE` 的所有端口映射到宿主。


#### ENV

```
ENV <key> <value>               # 这种格式只能定义一个环境变量
ENV <key>=<value> ...           # 这种格式可以定义对个环境变量
```

`ENV` 指令通过键值对定义环境变量。`Dockerfile` 中定义的环境变量，可以在执行 `docker run` 的时候通过 `-e` 选项替换值。

> **[info] 标注**  
> 如果需要针对一个单独的命令添加环境变量，则可以通过 `RUN <key>=<value> 设置`。

#### ADD

`ADD` 有两种格式：

* `ADD <src>... <dest>`
* `ADD ["<src>",... "<dest>"]` （这种格式一般在路径有空格的情况下使用）

`ADD` 指令复制本地主机文件、目录或者远程文件 URLS 从 `<src>` 添加到镜像中的路径 `<dest>` （其中如果远程 URL 需要认证，则只能通过 `RUN wegt` 或者 `RUN curl` 代理，不过一般也不用 `ADD` 添加远程文件）。`<src>` 支持正则匹配，基于 Go 的 [filepath.Match](http://golang.org/pkg/path/filepath#Match) 规则。例如：

```
ADD hom* /mydir/        # 添加所有以 hom 开头的文件
ADD hom?.txt /mydir/    # ? 用于代表单个字符，如 home.txt
```

> **[info] 标注**  
> `<src>` 根目录不是以系统 `/` 开始的，而是当前构建环境的根目录，如构建环境目录为 `~/docker/app/`，则 `ADD` 拷贝本地文件目录只能局限于 `~/docker/app/` 下的子文件或者子目录。

`<dest>` 是一个绝对路径，或者基于 `WORKDIR` 的绝对路径：

```
ADD test relativeDir/          # 添加 test 到 `WORKDIR`/relativeDir/
ADD test /absoluteDir/         # 添加 test 到 /absoluteDir/
```

> **[info] 标注**  
> 通过 `ADD` 添加的文件和目录在镜像文件系统中 UID 和 GID 都是 0。如果添加的是一个目录，则只会把目录下的内容（包括文件系统元数据）传输到镜像 `<dest>` 下，目录本身不拷贝。如果 `<dest>` 中目录不存在，则会自动层级创建相应目录。

如果 `<src>` 是一个本地 tar 包（tar.gz、tar.xz、tar.bz 都行），添加到镜像中会自动解压成一个文件（解压同 `tar -x`），远程文件不支持。

> **[info] 标注**  
> 如果 `<src>` 有多个资源指定，那么 `<dest>` 必须以斜线 `/` 结尾。

#### COPY

`COPY` 有两种格式：

* `COPY <src>... <dest>`
* `COPY ["<src>",... "<dest>"]` （这种格式一般在路径有空格的情况下使用）

`COPY` 作用同 `ADD`，都是拷贝资源到镜像，不过 `COPY` 功能相对单一，不支持远程 URLs，也不支持自动解压 tar 文件。正常如果不是添加 tar 包的话，统一用 `COPY` 即可。

#### ENTRYPOINT

`ENTRYPOINT` 有两种格式：

* `ENTRYPOINT ["executable", "param1", "param2"]` （exec 格式，推荐优先使用这种格式）
* `ENTRYPOINT command param1 param2` （shell 格式）

`ENTRYPOINT` 和 `CMD` 指令有相同的作用，都可以用于容器启动执行命令。两者也可以结合使用，如：

```
ENTRYPOINT ["command"]        # ENTRYPOINT 作为命令
CMD ["param1", "param2"]      # CMD 作为命令选项
```

`CMD` 可以在 `docker run` 的时候轻易被覆盖，而如果要覆盖 `ENTRYPOINT`，则必须添加 `--entrypoint` 选项。同 `CMD`，一个 `Dockerfile` 中只能有一个 `ENTRYPOINT`，如果有多个则最后一个生效。

```
docker run -it --rm --entrypoint=bash nginx     # 运行 nginx 容器，并且以 bash 命令启动
```

> **[info] 标注**  
> 不推荐使用 shell 格式，因为通过 shell 格式之后，命令会以 `/bin/sh -c` 的一个子命令启动，并且不会传递任何信号。意思就是说，执行命令在容器中并不会以 `PID 1` 运行，并且不会接收 UNIX 信号，那么容器在 `docker stop` 时就不能接收到 `SIGTERM` 完成正常的退出。

如果你需要给一个执行程序写一个启动脚本，你必须确保最终执行程序能通过 `exec` 和 `gosu` 命令收到 Unix 信号，以完成程序优雅的退出：

```
#!/usr/bin/env bash
set -e

if [ "$1" = 'postgres' ]; then
    chown -R postgres "$PGDATA"

    if [ -z "$(ls -A "$PGDATA")" ]; then
        gosu postgres initdb
    fi

    exec gosu postgres "$@"
fi

exec "$@"
```

如果你在容器停止的时候做一些额外清理工作，或者容器中运行不止一个执行程序，你需要确保 `ENTRYPOINT` 脚本能收到 Unix 信号，并且正常传递，那么你可以通过如下方式实现：

```
#!/bin/sh
# Note: I've written this using sh so it works in the busybox container too

# USE the trap if you need to also do manual cleanup after the service is stopped,
#     or need to start multiple services in the one container
# 通过使用 trap 命令实现
trap "echo TRAPed signal" HUP INT QUIT TERM

# start service in background here
/usr/sbin/apachectl start

echo "[hit enter key to exit] or run 'docker stop <container>'"
read

# stop service and clean up here
echo "stopping apache"
/usr/sbin/apachectl stop

echo "exited $0"
```

> **[info] 标注**  
> `ENTRYPOINT` 可以通过 `--entrypoint` 覆盖，不过只能是以 exec  格式。exec 格式会被解析成一个 JSON 数组，所以必须是 `双引号`。

`Dockerfile` 中至少要指定 `CMD` 或者 `ENTRYPOINT` 中的一个。关于 `CMD` 和 `ENTRYPOINT` 的更多，建议参考官方文档 [Understand how CMD and ENTRYPOINT interact](https://github.com/docker/docker-ce/blob/master/components/cli/docs/reference/builder.md#understand-how-cmd-and-entrypoint-interact)

#### VOLUME

```
VOLUME ["/data"]
```

`VOLUME` 指令创建一个指定名称的挂载点，并讲其标记为从本地主机或者其它容器外挂卷。该值可以为 JSON 数组，也可以是包含多个参数的普通字符串，如 `VOLUME /var/log` 或者 `VOLUME /var/log /var/db`。

#### USER

```
USER <user>[:<group>]
```

或者 `USER [:]`

`USER` 指令用来表示容器执行程序的用户（UID）和组（GID）。

#### WORKDIR

```
WORKDIR /path/to/workdir
```

`WORKDIR` 用于设置工作目录，`RUN`、`CMD`、`ENTRYPOINT`、`COPY` 和 `ADD` 指令将会遵从这一规则。

> **[info] 标注**  
> 如果设置的 `WORKDIR` 不存在，则会自动创建

`Dockerfile` 还有一些高级技巧和黑魔法，比如可以通过 `STOPSIGNAL signal` 设置 system call 信号用以传送给容器退出。这里不做过多的介绍，更多参见 [Dockerfile reference](https://github.com/docker/docker-ce/blob/master/components/cli/docs/reference/builder.md)

## Dockerfile 最佳实践

### 使用 `.dockerignore` 文件

使用`.dockerignore` 文件可以避免不必要的文件发送到 Docker daemon，以提升镜像构建效率，因此强烈建议使用 `.dockerignore` 文件。

### 避免安装不必要的软件包

为了降低复杂性、依赖性、文件大小以及构建时间，应该避免安装额外的或不必要的包。例如，不需要在一个数据库镜像中安装一个文本编辑器。

### 每个容器应该只包括一个 `concern`

将应用程序解耦为多个容器，可以让容器更便于横向扩展和复用。针对容器，你可能经常会听到 `一个容器一个进程` 的理念，这是一个好的经验法则，但并不是一条硬性规定，实际过程中保持容器尽可能干净和模块化即可。

### 最小化镜像层数

* Docker 1.10 或者更高版本开始，只有 `RUN`、`COPY` 和 `ADD` 指令会创建镜像层，其它指令创建临时中间镜像，不再直接增加构建的大小
* Docker 17.05 或者更高版本还支持多阶段构建（[multi-stage builds](https://docs.docker.com/engine/userguide/eng-image/multistage-build/)）

### 多行参数排序

如果可能，通过字母顺序来排序，这样可以避免安装包的重复并且更容易更新列表，另外可读性也会更强，添加一个空行使用 `\` 换行:

```
RUN apt-get update && apt-get install -y \
  bzr \
  cvs \
  git \
  mercurial \
  subversion
```

### 构建缓存

在镜像构建过程中，Docker 会按照 `Dockerfile` 中的顺序执行指令，Docker 会检测缓存中是否有可以复用的镜像，而不是直接创建新的镜像。如果不想使用缓存，可以通过 `--no-cache=true` 取消缓存读取。

* Docker 从缓存中的父镜像开始，将下一条指令和该基础镜像派生出的所有子镜像对比，查看是否使用了完全相同的构建指令，以确定缓存是否可复用。如果不相同，缓存失效。
* 大多数情况，只需要将 `Dockerfile` 中的指令与子镜像进行比较就够了。针对 `COPY` 和 `ADD` 指令则有些不同，除了比较指令是否相同，还需要校验比较镜像中的文件内容（忽略修改时间和访问时间）。如果文件中有任何内容改变，则缓存失效。
* `RUN apt-get -y update` 这类命令，则不会匹配缓存。

> **[info] 标注**  
> 为了有效地利用缓存，你需要保持你的 Dockerfile 一致，并且尽量在末尾修改。

### 指令最佳实践

#### FROM

如果有可能，尽量使用官方仓库的镜像作为基础镜像。（比如安全因素、干净性等）

#### RUN

保持 `Dockerfile` 可读性、可理解、可维护性，通过 `\` 分隔比较长或者复杂的 `RUN` 指令：

```
RUN apt-get update && apt-get install -y \
    aufs-tools \
    automake \
    build-essential \
    curl \
    dpkg-sig \
    libcap-dev \
    libsqlite3-dev \
    mercurial \
    reprepro \
    ruby1.9.1 \
    ruby1.9.1-dev \
    s3cmd=1.1.* \
 && rm -rf /var/lib/apt/lists/*
```

> **[info] 标注**  
> `apt-get update` 要和 `apt-get install` 指令要同时使用，否则单独使用 `apt-get update` 会导致缓存问题（直接使用缓存而不执行该条命令）并且导致 `apt-get install 安装命令失败`。

__使用管道__

使用 `RUN` 运行命令的时候，可能一些命令依赖 shell 管道的的功能，如：

```
RUN wget -O - https://some.site | wc -l > /number
```

Docker 执行这些命令的时候使用的是 `/bin/sh -c`，最后执行的命令退出码决定整个命令是否执行成功。也就是说管道前的命令 `wget` 即使执行失败，只要 `wc -l` 能成功执行，就不会停止镜像构建。为了规避这个问题，可以加入 `set -o pipefail &&` 来保证镜像正常构建：

```
RUN set -o pipefail && wget -O - https://some.site | wc -l > /number
```

> **[info] 标注**  
> 不是所有的 shell 都支持 `-o pipefail` 选项的（比如 dash）。Debian 基础类的镜像默认 shell 是 dash，可以通过如下方式来支持 `pipefail`：
>```
>RUN ["/bin/bash", "-c", "set -o pipefail && wget -O - https://some.site | wc -l > /number"]
>```

#### CMD

`CMD` 应该以 `CMD ["executable", "param1", "param2"…]` 这种格式运行。不建议结合 `ENTRYPOINT` 使用，这样反而会带来一定的复杂性。

#### EXPOSE

`EXPOSE` 指令用来表面容器将监听连接的端口，建议使用标准的端口，如 Nginx Web 服务则是 `EXPOSE 80`，而 MongoDB 服务则是 `EXPOSE 27017`。至于外部映射的端口，用户则可以根据实际自己定义。

#### ENV

通过指定一些环境变量，可以使得 `Dockerfile` 更方便维护，如：

```
ENV PG_MAJOR 9.3
ENV PG_VERSION 9.3.4
RUN curl -SL http://example.com/postgres-$PG_VERSION.tar.xz | tar -xJC /usr/src/postgress && …
ENV PATH /usr/local/postgres-$PG_MAJOR/bin:$PATH
```

#### ADD or COPY

尽管 `ADD` 和 `COPY` 功能上很类似，一般建议优先使用 `COPY`。`COPY` 相对 `ADD` 更透明，就是提供本地文件的拷贝。`ADD` 最好的应用场景就是，拷贝 tar 包，自动解压。其它场景建议一律使用 `COPY`，针对远程文件的拷贝，则使用 `RUN` 结合 `wget` 或者 `curl` 命令代替：

```
RUN mkdir -p /usr/src/things \
    && curl -SL http://example.com/big.tar.xz \
    | tar -xJC /usr/src/things \
    && make -C /usr/src/things all
```

#### ENTRYPOINT

`ENTRYPOINT` 最好的就是用其设置镜像的主运行命令，方便镜像运行的时候直接指定命令参数（或者结合 `CMD` 设置默认参数）。

#### VOLUME

`VOLUME` 指令用来定义数据存储路径，强烈建议有存储相关的路径通过 `VOLUME` 设置卷。

#### USER

应该尽量避免安装或者使用 sudo，因为它具有不可预知的 TTY 和信号转发行为，可能会导致很多问题。如果需要 sudo 类似的功能（例如，以 root 初始化守护进程，但是以非 root 身份运行守护进程），则可以使用 `gosu`。

为了减少镜像层和降低复杂性，应该避免频繁的用户切换。

#### WORKDIR

为了清晰和可靠性，建议 `WORKDIR` 使用绝对路径。另外，建议通过 `WORKDIR` 来替换类似 `RUN cd … && do-something`  指定，以带来更好的可读性、故障定位等。

获取更多关于 `Dockerfile` 的最佳实践，详细的请阅读 Docker 官方文档 [Best practices for writing Dockerfiles](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices) 。
