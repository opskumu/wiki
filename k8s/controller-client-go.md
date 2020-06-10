# client-go 幕后 「译」

+ 原文 [client-go under the hood](https://github.com/kubernetes/sample-controller/blob/master/docs/controller-client-go.md)

[client-go](https://github.com/kubernetes/client-go/) 库囊括了各种机制，你可以在开发自定义控制器的时候使用它们。这些机制定义在 [tools/cache](https://github.com/kubernetes/client-go/tree/master/tools/cache) 目录下。

下图展示了 client—go 库中各种组件工作机制，以及和你编写的自定义控制器的交互点。

![](images/client-go-controller-interaction.jpeg)

## client-go 组件

+ Reflector：reflector 定义在 [type Reflector inside package cache](https://github.com/kubernetes/client-go/blob/master/tools/cache/reflector.go)，监视 Kubernetes API 中指定的资源类型（kind）。完成此功能的函数是 `ListAndWatch`。可以监视内置的资源，也可以监视自定义资源。当 reflector 通过 watch API 接收到新资源存在的通知时，它将使用相应的 listing API 获取新创建的对象，并将其存放到 `watchHandler` 函数中的 Delta FIFO 队列中。

+ Informer：informer 定义在 [base controller inside package cache](https://github.com/kubernetes/client-go/blob/master/tools/cache/controller.go)，它会从 Delta FIFO 队列中弹出对象。完成此功能的函数是 `processLoop`。该基础控制器的任务是保存对象以备检索，并调用我们的控制器传递该对象。

+ Indexer：indexer 提供了资源索引功能。它定义在 [type Indexer inside package cache](https://github.com/kubernetes/client-go/blob/master/tools/cache/controller.go)。一个典型的索引用例是基于对象的标签来创建索引。indexer 可以基于几个索引函数来维护索引。Indexer 使用了一个线程安全的数据存储来存放对象和它们的键。这里有一个名为 `MetaNamespaceKeyFunc` 的函数定义在 [type Store inside package cache](https://github.com/kubernetes/client-go/blob/master/tools/cache/store.go)，它会为对象生成一个 `<namespace>/<name>` 组合键。

## 自定义控制器组件

+ Informer reference：这是对 Informer 实例的一个引用，该实例知道如何同你的自定义资源对象工作。你的自定义控制器代码需要创建合适的 Informer。

+ Indexer reference：这是对 Indexer 实例的引用，该实例知道如何同自定义资源对象工作。你的自定义控制器代码需要创建这个。你会使用这个 reference 检索对象以备后用。

client-go 中的基础控制器提供了 `NewIndexerInformer` 函数来创建 Informer 和 Indexer。在你的代码中，你可以直接调用 [此函数](https://github.com/kubernetes/client-go/blob/master/examples/workqueue/main.go#L174)，或者使用 [工厂方法](https://github.com/kubernetes/sample-controller/blob/master/main.go#L61) 创建 informer。

+ Resource Event Handlers：当需要传递一个对象给你的控制器时，Informer 会调用回调函数。典型的一个模式是编写这些函数获取调度对象的键并把键加入到工作队列以进一步处理。

+ Work queue：这是你在控制器代码中创建的队列，用于将对象的交付和处理分离。编写 Resource event handler 函数是为了获取交付对象的键并将其添加到工作队列中。

+ Process Item：这个函数是创建在你的代码中用来处理工作队列中的项目。这里可能有一个或多个其它函数来实际处理。这些函数通常使用 [Indexer reference](https://github.com/kubernetes/client-go/blob/master/examples/workqueue/main.go#L73)，或者 Listing wrapper 来检索键对应的对象。
