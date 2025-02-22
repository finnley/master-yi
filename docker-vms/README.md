# docker-vms

## 使用

1. 使用本地环境（默认）：

```bash
make prepare
# 或者显式指定
make prepare ENV_TYPE=local
```

2. 使用测试环境：

```bash
make prepare ENV_TYPE=test
```

## docker-compose.yaml

```yaml
version: '3'

x-templates:
  agent_centos8_aarch64:
    &agent_centos8_aarch64
    image: harbor.einscat.com:10011/library/centos8:aarch64
    privileged: true
    stdin_open: true
    tty: true
    extra_hosts:
      - "docker-registry:192.168.18.20"
    cap_add:
      - ALL
    working_dir: /opt
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw

services:

  vm-1:
    container_name: vm-1
    hostname: "vm-1"
    networks:
      vm_net:
        ipv4_address: 172.20.30.1
      vm_net_2:
        ipv4_address: 172.20.40.1
    ports:
      - "3306:3306"
    volumes:
      - "/sys/fs/cgroup:/sys/fs/cgroup:rw"
      - "~/workspace:/root/workspace"
    <<: *agent_centos8_aarch64
```

解释：

**x-templates**
    `x-templates` 这是一个自定义的顶级键，表示这些是模板定义。`x-` 前缀在一些 YAML 文件中用于标记非标准的键，以便工具和解析器能够轻松识别它们。

**agent_centos8_aarch64: &agent_centos8_aarch64**
    定义了一个名为 `agent_centos8_aarch64` 的模板，并使用锚 `&agent_centos8_aarch64` 标记它。后续可以通过 `*agent_centos8_aarch64` 引用这个模板。
**image**
    指定镜像名称

**privileged: true**
    启用了特权模式。在特权模式下，容器内的 root 用户拥有主机上的几乎所有权限，可以执行更底层的系统操作。

**stdin_open: true**
    保持标准输入（stdin）打开，允许与容器进行交互。

**tty: true**
    为容器分配一个伪终端（TTY），通常用于交互式会话。

**extra_hosts**
    用于在容器的 “/etc/hosts” 文件中添加额外的主机名映射。

**"docker-registry:192.168.18.20"**
    将 docker-registry 映射到 192.168.18.20。

**cap_add**
    用于添加额外的 Linux 能力（capabilities）到容器。

**- ALL**
    添加所有可用的 Linux 能力，赋予容器更多的权限。

**working_dir: /opt**
    指定了容器的工作目录为 /opt，即容器启动后的工作目录。

**<<: *agent_centos8_aarch64**
    通过别名引用了前面定义的 agent_centos8_aarch64 模板，将模板中的配置合并到 vm-1 服务中。


