# 文档 TODO

## __TODO__

+ [ ] Kubernetes 各组件源码解析（偏原理浅析，是时候把这块整合一下了）
    - [ ] kube-apiserver
    - [ ] kube-scheduler
    - [ ] kube-controller-manager
    - [ ] kubelet
    - [ ] kube-proxy
+ [ ] Kubernetes 部署流程
    - [ ] 集成 RBAC 的完整部署流程（当前的文档偏上手，并不是实际生产的部署方案，后续把这块完整整理下）
    - [ ] Kubeadm 部署流程（主要针对当前的二进制方式做对比，Kubeadm 现在还是黑盒，所以一直没有使用它管理部署） 
+ [ ] Kubernetes 网络方案（主要是当前使用 Calico + Flannel 生产实践以及原理总结）
+ [ ] 需要补全的系列短文
    - [ ] Taints and Tolerations
    - [ ] Reserve Compute Resources for System Daemons
    - [ ] Using sysctls in a Kubernetes Cluster
    - [ ] Kubernetes 镜像和容器 GC 机制
