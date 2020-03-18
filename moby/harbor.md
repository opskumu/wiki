# Harbor 安装和升级标注

> 安装统一下载在线安装包，离线安装包比较大，因为集成了离线镜像，意义不大 https://github.com/goharbor/harbor/releases

## 1.5.x

### 目录结构

```
# tree -L 1 harbor
harbor
├── common                          # 配置目录
├── docker-compose.clair.yml        # clair 编排文件
├── docker-compose.notary.yml       # notary 编排文件
├── docker-compose.yml              # 编排文件
├── ha                              # ha 配置目录
├── harbor.cfg                      # 配置文件
├── install.sh                      # 安装脚本
├── LICENSE
├── NOTICE
├── open_source_license
└── prepare                         # 环境初始化脚本

2 directories, 9 files
```

### 环境和配置初始化

`harbor.cfg` 为配置文件，根据实际需求修改。`common` 下为相关组件的模板文件，`prepare` 脚本会根据 `harbor.cfg` 和 `common` 下的模板文件生成实际的配置文件。`install.sh` 会调用 `prepare` 并启动 harbor。因此正常情况下我们只需要修改 `harbor.cfg` 并执行 `install.sh` 即可。不过实际生产环境使用过程中一般会有一些自定义的需求，比如一般会把 MySQL 单独抽离，使用现成的服务，还不是默认 compose 文件中启动的。 接下来会详细介绍一下，首先修改 `harbor.cfg`，然后执行 `prepare`，`harbor.cfg` 相对易懂，这里不展开讲：

```
# ./prepare
Generated and saved secret to file: /data/secretkey
Generated configuration file: ./common/config/nginx/nginx.conf
Generated configuration file: ./common/config/adminserver/env
Generated configuration file: ./common/config/ui/env
Generated configuration file: ./common/config/registry/config.yml
Generated configuration file: ./common/config/db/env
Generated configuration file: ./common/config/jobservice/env
Generated configuration file: ./common/config/jobservice/config.yml
Generated configuration file: ./common/config/log/logrotate.conf
Generated configuration file: ./common/config/jobservice/config.yml
Generated configuration file: ./common/config/ui/app.conf
Generated certificate, key file: ./common/config/ui/private_key.pem, cert file: ./common/config/registry/root.crt
The configuration files are ready, please use docker-compose to start the service.
```

可以从输出看出 `prepare` 脚本主要是用来生成证书、配置文件等。

> 如果开启 https，则需要提前创建相关证书，可参考 https://github.com/goharbor/harbor/blob/v1.5.2/docs/configure_https.md

`harbor.cfg` 定义了 `db_host`、`db_password`、`db_port` 以及 `db_user` 唯独没有定义库名，这里模板 `common/templates/adminserver/env` 中是固定死的，为 `MYSQL_DATABASE=registry`。如果你使用外部的数据库，那么你需要根据实际的库名修改此处。 

使用外部的数据库需要提前导入相关的表，相关 SQL 文件安装包并没有提供，需要下载 `vmware/harbor-db:v1.5.2` 镜像，SQL 文件位置为 `/docker-entrypoint-initdb.d/registry.sql` 拷贝出来，导入数据库即可。在执行相关操作的时候，还需要额外修改 `docker-compose.yml` 文件，去除 harbor-db 的依赖，然后再执行 `docker-compose up -d` 启动 harbor 服务。当然，也可以直接执行 `install.sh` 一步到位，这里拆开来说是方便了解整个过程。

## 升级 1.5.x -> 1.6.x 

因为 1.6.0  版本开始数据库从 MariaDB 变更到 Postgresql，1.5.x 的版本如果往上升级则需要先升级到 1.6.x 版本，在此基础上进行后续的升级。

关闭和备份旧版本

```
docker-compose down
mv harbor harbor_bak
```

备份数据和配置（更新到什么版本，下载具体 tag 的迁移镜像，如此处升级到 1.6.3 则迁移镜像为 `goharbor/harbor-migrator:v1.6.3`）

```
docker run -it --rm -e DB_USR=root -e DB_PWD=<数据库密码> -v <旧版本数据存储目录>:/var/lib/mysql -v <旧版本配置路径>:/harbor-migration/harbor-cfg/harbor.cfg -v <备份目录>:/harbor-migration/backup goharbor/harbor-migrator:[tag] backup
```

数据和配置升级，在 1.5.x 升级到 1.6.x 时候，因为涉及到 DB 的变更，这步操作会把原始数据目录的格式转为 PostgreSQL，此处要注意，每次升级前都要执行上面的备份操作。

```
docker run -it --rm -e DB_USR=root -e DB_PWD=<数据库密码> -v <旧版本数据存储目录>:/var/lib/mysql -v <旧版本配置路径>:/harbor-migration/harbor-cfg/harbor.cfg goharbor/harbor-migrator:[tag] up
```

把新版本解压到原始程序目录 harbor 中，然后使用上面的更新过的配置替换当前的配置，执行 `./install.sh` 即可启动新版本的服务，当然如果涉及到外部的数据库，操作同之前的。

> https://github.com/goharbor/harbor/blob/v1.6.3/docs/migration_guide.md

##  升级 1.6.x -> 1.8.x

因为版本限制，如果要升级到 1.10.x 需要先升级到 1.7.x，这里直接跳过升级到 1.8.x（当然升级到 1.7.x 再升级到 1.10.x 也是可以的）。后续的 Harbor 版本安装对 Docker 版本有要求了，所以建议升级 Docker 版本到最新版本。

```
docker-compose down
mv harbor harbor_bak
cp -r /data/database /my_backup_dir/
tar xf harbor-online-installer-v1.8.6.tgz 
```

更新配置

```
docker run -it --rm -v <旧版本配置路径>:/harbor-migration/harbor-cfg/harbor.yml -v <新版本 harbor.yml 配置路径>:/harbor-migration/harbor-cfg-out/harbor.yml goharbor/harbor-migrator:[tag] --cfg up
```

安装启动

`./install.sh --with-chartmuseum` 执行安装指令，这里还额外支持 Helm Charts。

> https://github.com/goharbor/harbor/blob/v1.8.6/docs/migration_guide.md
