# Kubelet

- `cmd/kubelet/kubelet.go`
- `pkg/kubelet/kubelet.go`

> __注：__ 基于 [Kubernetes release-1.9](https://github.com/kubernetes/kubernetes/tree/release-1.9)

## 网络

Kubernetes 容器使用的网络规范为 `CNI`（容器网络接口），`CNI` 包括方法规范和参数规范。Kubernetes 并不实际去操作容器的网络，而是通过遵循 CNI 规范的各种网络插件去管理容器网络资源，如 `Calico`、`Flannel`、`Contiv netplugin` 网络插件等。

- [Container Network Interface Specification](https://github.com/containernetworking/cni/blob/master/SPEC.md)

### CNI 接口

- `github.com/containernetworking/cni/libcni/api.go`

CNI 接口只需要实现以下方法，实际就是两种，一个添加网络调用，一个删除调用：

```
type CNI interface {
    AddNetworkList(net *NetworkConfigList, rt *RuntimeConf) (types.Result, error)
    DelNetworkList(net *NetworkConfigList, rt *RuntimeConf) error

    AddNetwork(net *NetworkConfig, rt *RuntimeConf) (types.Result, error)
    DelNetwork(net *NetworkConfig, rt *RuntimeConf) error
}
```

![](http://upload-images.jianshu.io/upload_images/3611024-8026258c0424f952.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 网络初始化

Kubelet 启动过程中针对网络主要做以下步骤，分别是探针获取当前环境的网络插件以及初始化网络。

#### 步骤 1：探针获取当前环境的网络插件
- `cmd/kubelet/app/server.go`

```
func UnsecuredDependencies(s *options.KubeletServer) (*kubelet.Dependencies, error) {
... ...
                // 执行具体函数，获取当前环境的网络插件
                NetworkPlugins:      ProbeNetworkPlugins(s.CNIConfDir, s.CNIBinDir),
... ...
}
```

- `cmd/kubelet/app/plugins.go`

```
// ProbeNetworkPlugins collects all compiled-in plugins
func ProbeNetworkPlugins(cniConfDir, cniBinDir string) []network.NetworkPlugin {
    allPlugins := []network.NetworkPlugin{}

    // for each existing plugin, add to the list
    allPlugins = append(allPlugins, cni.ProbeNetworkPlugins(cniConfDir, cniBinDir)...)
    allPlugins = append(allPlugins, kubenet.NewPlugin(cniBinDir))

    return allPlugins
}
```

- `pkg/kubelet/network/plugins.go`

以下是 kubelet `NetworkPlugin` 接口，`pkg/kubelet/network/cni/cni.go` 中 `cniNetworkPlugin` 实现了这套接口：

```
// Plugin is an interface to network plugins for the kubelet
type NetworkPlugin interface {
    // Init initializes the plugin.  This will be called exactly once
    // before any other methods are called.
    Init(host Host, hairpinMode kubeletconfig.HairpinMode, nonMasqueradeCIDR string, mtu int) error

    // Called on various events like:
    // NET_PLUGIN_EVENT_POD_CIDR_CHANGE
    Event(name string, details map[string]interface{})

    // Name returns the plugin's name. This will be used when searching
    // for a plugin by name, e.g.
    Name() string

    // Returns a set of NET_PLUGIN_CAPABILITY_*
    Capabilities() utilsets.Int

    // SetUpPod is the method called after the infra container of
    // the pod has been created but before the other containers of the
    // pod are launched.
    SetUpPod(namespace string, name string, podSandboxID kubecontainer.ContainerID, annotations map[string]string) error

    // TearDownPod is the method called before a pod's infra container will be deleted
    TearDownPod(namespace string, name string, podSandboxID kubecontainer.ContainerID) error

    // GetPodNetworkStatus is the method called to obtain the ipv4 or ipv6 addresses of the container
    GetPodNetworkStatus(namespace string, name string, podSandboxID kubecontainer.ContainerID) (*PodNetworkStatus, error)

    // Status returns error if the network plugin is in error state
    Status() error
}
```

- `pkg/kubelet/network/cni/cni.go`

```
func probeNetworkPluginsWithVendorCNIDirPrefix(pluginDir, binDir, vendorCNIDirPrefix string) []network.NetworkPlugin {
    if binDir == "" {
        // DefaultCNIDir 默认值为 `/opt/cni/bin`
        binDir = DefaultCNIDir
    }
    plugin := &cniNetworkPlugin{
        defaultNetwork:     nil,
        // 默认会设置 loNetwork 用于添加 lo 设备，所以在 binDir 下，即 CNI 插件目录下必须需要 `loopback` 插件
        loNetwork:          getLoNetwork(binDir, vendorCNIDirPrefix),
        execer:             utilexec.New(),
        pluginDir:          pluginDir,
        binDir:             binDir,
        vendorCNIDirPrefix: vendorCNIDirPrefix,
    }

    // sync NetworkConfig in best effort during probing.
    // 探测网络，并同步网络配置，此处没有针对 err 处理，syncNetworkConfig 函数执行错误只会记录相关日志
    plugin.syncNetworkConfig()
    // 虽然是个列表，但运行时只会支持一种插件
    return []network.NetworkPlugin{plugin}
}

func ProbeNetworkPlugins(pluginDir, binDir string) []network.NetworkPlugin {
    return probeNetworkPluginsWithVendorCNIDirPrefix(pluginDir, binDir, "")
}

... ...

// 探测网络，并设置插件默认网络
func (plugin *cniNetworkPlugin) syncNetworkConfig() {
    network, err := getDefaultCNINetwork(plugin.pluginDir, plugin.binDir, plugin.vendorCNIDirPrefix)
    if err != nil {
        glog.Warningf("Unable to update cni config: %s", err)
        return
    }
    plugin.setDefaultNetwork(network)
}
```

```
func getDefaultCNINetwork(pluginDir, binDir, vendorCNIDirPrefix string) (*cniNetwork, error) {
    // 默认 pluginDir `/etc/cni/net.d`
    if pluginDir == "" {
        pluginDir = DefaultNetDir
    }
    files, err := libcni.ConfFiles(pluginDir, []string{".conf", ".conflist", ".json"})
    switch {
    case err != nil:
        return nil, err
    case len(files) == 0:
        return nil, fmt.Errorf("No networks found in %s", pluginDir)
    }

    sort.Strings(files)
    // 遍历所有的配置文件，只要匹配文件满足条件就返回，因此多个配置设置是无效的
    for _, confFile := range files {
        var confList *libcni.NetworkConfigList
        if strings.HasSuffix(confFile, ".conflist") {
            confList, err = libcni.ConfListFromFile(confFile)
            if err != nil {
                glog.Warningf("Error loading CNI config list file %s: %v", confFile, err)
                continue
            }
        } else {
            conf, err := libcni.ConfFromFile(confFile)
            if err != nil {
                glog.Warningf("Error loading CNI config file %s: %v", confFile, err)
                continue
            }
            // Ensure the config has a "type" so we know what plugin to run.
            // Also catches the case where somebody put a conflist into a conf file.
            if conf.Network.Type == "" {
                glog.Warningf("Error loading CNI config file %s: no 'type'; perhaps this is a .conflist?", confFile)
                continue
            }

            confList, err = libcni.ConfListFromConf(conf)
            if err != nil {
                glog.Warningf("Error converting CNI config file %s to list: %v", confFile, err)
                continue
            }
        }
        if len(confList.Plugins) == 0 {
            glog.Warningf("CNI config list %s has no networks, skipping", confFile)
            continue
        }
        confType := confList.Plugins[0].Network.Type

        // Search for vendor-specific plugins as well as default plugins in the CNI codebase.
        vendorDir := vendorCNIDir(vendorCNIDirPrefix, confType)
        cninet := &libcni.CNIConfig{
            Path: []string{vendorDir, binDir},
        }
        network := &cniNetwork{name: confList.Name, NetworkConfig: confList, CNIConfig: cninet}
        return network, nil
    }
    return nil, fmt.Errorf("No valid networks found in %s", pluginDir)
}
```

#### 步骤 2：初始化网络插件

- `pkg/kubelet/kubelet.go`

```
plug, err := network.InitNetworkPlugin(kubeDeps.NetworkPlugins, crOptions.NetworkPluginName, &criNetworkHost{&networkHost{klet}, &network.NoopPortMappingGetter{}}, hairpinMode, nonMasqueradeCIDR, int(crOptions.NetworkPluginMTU))
if err != nil {
        return nil, err
}
klet.networkPlugin = plug
```

- `pkg/kubelet/network/plugins.go`

```
// InitNetworkPlugin inits the plugin that matches networkPluginName. Plugins must have unique names.
func InitNetworkPlugin(plugins []NetworkPlugin, networkPluginName string, host Host, hairpinMode kubeletconfig.HairpinMode, nonMasqueradeCIDR string, mtu int) (NetworkPlugin, error) {
        // 如果未指定网络插件 `--network-plugin`，默认为 `noop` 插件，使用 CNI 网络，指定该插件为 `cni`，
        // 关于 `noop` 具体详见官方说明 https://kubernetes.io/docs/concepts/cluster-administration/network-plugins/
        if networkPluginName == "" {
                // default to the no_op plugin
                plug := &NoopNetworkPlugin{}
                plug.Sysctl = utilsysctl.New()
                // `noop` 网络初始化
                if err := plug.Init(host, hairpinMode, nonMasqueradeCIDR, mtu); err != nil {
                        return nil, err
                }
                return plug, nil
        }

        pluginMap := map[string]NetworkPlugin{}

        allErrs := []error{}
        for _, plugin := range plugins {
                name := plugin.Name()
                if errs := validation.IsQualifiedName(name); len(errs) != 0 {
                        allErrs = append(allErrs, fmt.Errorf("network plugin has invalid name: %q: %s", name, strings.Join(errs, ";")))
                        continue
                }

                if _, found := pluginMap[name]; found {
                        allErrs = append(allErrs, fmt.Errorf("network plugin %q was registered more than once", name))
                        continue
                }
                pluginMap[name] = plugin
        }

        // 确认是否和与指定的网络插件匹配，如果匹配则进行相关初始化
        chosenPlugin := pluginMap[networkPluginName]
        if chosenPlugin != nil {
                err := chosenPlugin.Init(host, hairpinMode, nonMasqueradeCIDR, mtu)
                if err != nil {
                        allErrs = append(allErrs, fmt.Errorf("Network plugin %q failed init: %v", networkPluginName, err))
                } else {
                        glog.V(1).Infof("Loaded network plugin %q", networkPluginName)
                }
        } else {
                allErrs = append(allErrs, fmt.Errorf("Network plugin %q not found.", networkPluginName))
        }

        return chosenPlugin, utilerrors.NewAggregate(allErrs)
}
```

> __注：__ 上文 hairpinMode 设置 haripin NAT 方式，使得服务后端 endpoints 访问服务自身时负载到本地，配置项为 `--hairpin-mode`，默认值 `promiscuous-bridge`

- `pkg/kubelet network/cni/cni.go`

```
func (plugin *cniNetworkPlugin) Init(host network.Host, hairpinMode kubeletconfig.HairpinMode, nonMasqueradeCIDR string, mtu int) error {
    // platformInit 用于确定主机是否有 `nsenter` 命令
    err := plugin.platformInit()
    if err != nil {
        return err
    }

    plugin.host = host

    plugin.syncNetworkConfig()
    return nil
}
```

### 网络操作

网络操作主要是 Pod 创建的网络添加以及删除的网络回收操作，上文中介绍了 `NetworkPlugin` 接口，其中包含了添加网络和删除网络的方法：

- `pkg/kubelet/network/plugins.go`

```
// Plugin is an interface to network plugins for the kubelet
type NetworkPlugin interface {
... ...

    // SetUpPod is the method called after the infra container of
    // the pod has been created but before the other containers of the
    // pod are launched.
    SetUpPod(namespace string, name string, podSandboxID kubecontainer.ContainerID, annotations map[string]string) error

    // TearDownPod is the method called before a pod's infra container will be deleted
    TearDownPod(namespace string, name string, podSandboxID kubecontainer.ContainerID) error
... ...
}
```

![](http://upload-images.jianshu.io/upload_images/3611024-c344ae56935dc1b5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

以下为 Kubelet 调用 CNI 网络的具体操作实现：

#### 添加网络

- `pkg/kubelet/network/cni/cni.go`

```
func (plugin *cniNetworkPlugin) SetUpPod(namespace string, name string, id kubecontainer.ContainerID, annotations map[string]string) error {
    if err := plugin.checkInitialized(); err != nil {
        return err
    }
    // 通过 GetNetNS() 获取指定容器 net 命名空间路径，格式为 `/proc/<pid>/net`
    // pkg/kubelet/dockershim/helpers_linux.go `getNetworkNamespace`
    netnsPath, err := plugin.host.GetNetNS(id.ID)
    if err != nil {
        return fmt.Errorf("CNI failed to retrieve network namespace path: %v", err)
    }

    // Windows doesn't have loNetwork. It comes only with Linux
    // 给容器生成 lo 网卡
    if plugin.loNetwork != nil {
        if _, err = plugin.addToNetwork(plugin.loNetwork, name, namespace, id, netnsPath); err != nil {
            glog.Errorf("Error while adding to cni lo network: %s", err)
            return err
        }
    }

    _, err = plugin.addToNetwork(plugin.getDefaultNetwork(), name, namespace, id, netnsPath)
    if err != nil {
        glog.Errorf("Error while adding to cni network: %s", err)
        return err
    }

    return err
}

... ...

func (plugin *cniNetworkPlugin) addToNetwork(network *cniNetwork, podName string, podNamespace string, podSandboxID kubecontainer.ContainerID, podNetnsPath string) (cnitypes.Result, error) {
    rt, err := plugin.buildCNIRuntimeConf(podName, podNamespace, podSandboxID, podNetnsPath)
    if err != nil {
        glog.Errorf("Error adding network when building cni runtime conf: %v", err)
        return nil, err
    }

    netConf, cniNet := network.NetworkConfig, network.CNIConfig
    glog.V(4).Infof("About to add CNI network %v (type=%v)", netConf.Name, netConf.Plugins[0].Network.Type)
    res, err := cniNet.AddNetworkList(netConf, rt)
    if err != nil {
        glog.Errorf("Error adding network: %v", err)
        return nil, err
    }

    return res, nil
}

```

- `github.com/containernetworking/cni/libcni/api.go`

```
// AddNetworkList executes a sequence of plugins with the ADD command
func (c *CNIConfig) AddNetworkList(list *NetworkConfigList, rt *RuntimeConf) (types.Result, error) {
    var prevResult types.Result
    for _, net := range list.Plugins {
        pluginPath, err := invoke.FindInPath(net.Network.Type, c.Path)
        if err != nil {
            return nil, err
        }

        newConf, err := buildOneConfig(list, net, prevResult, rt)
        if err != nil {
            return nil, err
        }

        // 调用插件添加网络
        prevResult, err = invoke.ExecPluginWithResult(pluginPath, newConf.Bytes, c.args("ADD", rt))
        if err != nil {
            return nil, err
        }
    }

    return prevResult, nil
}
```

#### 删除网络

- `pkg/kubelet/network/cni/cni.go`

```
func (plugin *cniNetworkPlugin) TearDownPod(namespace string, name string, id kubecontainer.ContainerID) error {
    if err := plugin.checkInitialized(); err != nil {
        return err
    }

    // Lack of namespace should not be fatal on teardown
    netnsPath, err := plugin.host.GetNetNS(id.ID)
    if err != nil {
        glog.Warningf("CNI failed to retrieve network namespace path: %v", err)
    }

    return plugin.deleteFromNetwork(plugin.getDefaultNetwork(), name, namespace, id, netnsPath)
}
... ...

func (plugin *cniNetworkPlugin) deleteFromNetwork(network *cniNetwork, podName string, podNamespace string, podSandboxID kubecontainer.ContainerID, podNetnsPath string) error {
    rt, err := plugin.buildCNIRuntimeConf(podName, podNamespace, podSandboxID, podNetnsPath)
    if err != nil {
        glog.Errorf("Error deleting network when building cni runtime conf: %v", err)
        return err
    }

    netConf, cniNet := network.NetworkConfig, network.CNIConfig
    glog.V(4).Infof("About to del CNI network %v (type=%v)", netConf.Name, netConf.Plugins[0].Network.Type)
    err = cniNet.DelNetworkList(netConf, rt)
    if err != nil {
        glog.Errorf("Error deleting network: %v", err)
        return err
    }
    return nil
}
```

- `github.com/containernetworking/cni/libcni/api.go`

```
// DelNetworkList executes a sequence of plugins with the DEL command
func (c *CNIConfig) DelNetworkList(list *NetworkConfigList, rt *RuntimeConf) error {
    for i := len(list.Plugins) - 1; i >= 0; i-- {
        net := list.Plugins[i]

        pluginPath, err := invoke.FindInPath(net.Network.Type, c.Path)
        if err != nil {
            return err
        }

        newConf, err := buildOneConfig(list, net, nil, rt)
        if err != nil {
            return err
        }

        // 调用插件删除网络
        if err := invoke.ExecPluginWithoutResult(pluginPath, newConf.Bytes, c.args("DEL", rt)); err != nil {
            return err
        }
    }

    return nil
}
```

### 参考

- [Kubernetes 网络](https://github.com/keontang/k8s-notes/blob/master/kubernetes-network.md)
- [Kubernetes网络插件CNI调研整理](https://yucs.github.io/2017/12/06/2017-12-6-CNI/)
- [kubernetes 容器网络接口(CNI)网络插件的设计与实现 ](http://dockone.io/article/2188)
