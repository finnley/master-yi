#!/bin/bash

# 加载环境变量，用于后续的 Docker 配置
source .env

# 定义了脚本中使用的 JSON 配置文件、输出的 Docker Compose 配置文件和模板文件的路径。
CONFIG_FILE=./config.json
COMPOSE_FILE=./docker-compose.yaml
TEMPLATES_FILE=./templates.yaml

# 检查 HOST_NUMBER 是否在 5 到 253 之间，确保分配的 IP 地址范围合理，超出范围脚本会退出。
if [[ ${HOST_NUMBER} -gt 253 || ${HOST_NUMBER} -lt 5 ]]; then
    echo "HOST_NUMBER must be between 5 and 253"
    exit 1
fi

# Docker Compose 初始化
# 脚本最初在 ${COMPOSE_FILE} 中创建或覆盖以 version: '3' 和 x-templates: 开头的内容。
# Initialize compose file with version and x-templates section
cat > ${COMPOSE_FILE} <<EOF
x-templates:
EOF

# 将输入的字符串转换为小写
# Function to convert key to lowercase
to_lowercase() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# 检查一个元素是否存在于数组中。
# Check if an element is in an array
# "$1" 是要检查的元素，${@:2} 表示其后所有参数（即数组的元素）
# “$1” 代表调用函数时传递的第一个参数
# “${@:2}” 代表所有传递给函数的参数，从第二个参数开始的所有参数，
# 2 是一个索引，表示从第二个参数开始（记得在 Bash 中，参数索引从 1 开始，而非 0）。所以，这指的是在函数调用时，除了第一个参数之外的所有参数。
contains_element() {
  local element
  for element in "${@:2}"; do
    if [[ "$element" == "$1" ]]; then
      return 0
    fi
  done
  return 1
}

# 初始化一个空数组
# Initialize an array to track added templates
templates=()

# 读取 config.json 文件中的每个条目，检查是否启用（enable 字段为 true）。
# 找到启用的模板后，将其添加到 docker-compose.yaml 的 x-templates 部分，如果未添加过则进行处理。
# 使用 yq 命令从模板文件中提取模板内容加入构建的 docker-compose.yaml。
# Read the templates.yaml and write only the enabled templates to docker-compose.yaml
jq -c 'to_entries[]' ${CONFIG_FILE} | while read -r entry; do
  key=$(echo "${entry}" | jq -r '.key')
  value=$(echo "${entry}" | jq -r '.value')
  enable=$(echo "${value}" | jq -r '.enable')
  template="agent_$(to_lowercase ${key})"

  if [[ "${enable}" == "true" ]]; then
    # Add template to the file if not already added
    if ! contains_element "${template}" "${templates[@]}"; then
      echo "  ${template}:" >> ${COMPOSE_FILE}
      #如果模板尚未添加，则将模板名称写入 COMPOSE_FILE，格式为 agent_x:。
      # 使用 yq 从指定的模板文件中提取该模板的内容，并通过 sed 将每行前加四个空格（以符合 YAML 格式的缩进），然后追加到 COMPOSE_FILE。
      yq eval ".x-templates.${template}" ${TEMPLATES_FILE} | sed 's/^/    /' >> ${COMPOSE_FILE}
      # 已添加的模板名称添加到 templates 数组中，避免重复添加
      templates+=("${template}")
    fi
  fi
done

# 向 docker-compose.yaml 添加 services: 部分，准备为每个服务定义详细信息
# Add services section
echo "
services:" >> ${COMPOSE_FILE}


#读取 config.json 中启用的服务配置，获取每个条目对应的服务信息。
#服务信息包含：容器名称、主机名、网络配置及其特定 IP 地址、可能的端口映射和卷挂载。
#根据服务次数（count），为每个配置生成相应数量的服务实例。
#特定条件下（例如，特定架构），加入平台声明。
container_index=1
# Process JSON file
jq -c 'to_entries[]' ${CONFIG_FILE} | while read -r entry; do
  key=$(echo "${entry}" | jq -r '.key')
  value=$(echo "${entry}" | jq -r '.value')

  enable=$(echo "${value}" | jq -r '.enable')
  count=$(echo "${value}" | jq -r '.count')

#  ports=$(echo "${value}" | jq -r '.ports[]')
  volumes=$(echo "${value}" | jq -r '.volumes[]')

  ## mac 不支持该语法
  ## template="agent_${key,,}"
  template="agent_$(to_lowercase ${key})"

  # Only process enabled configurations
  if [[ "${enable}" == "true" ]]; then
    for ((i=1; i<=count; i++)); do
      echo "
  vm-${container_index}:
    container_name: vm-${container_index}
    hostname: \"vm-${container_index}\"
    networks:
      vm_net:
        ipv4_address: 172.20.30.${container_index}
      vm_net2:
        ipv4_address: 172.20.40.${container_index}" >> ${COMPOSE_FILE}

      # 检查并处理端口映射
      ports=$(echo "${value}" | jq -r --arg idx "vm-${container_index}" '.ports[$idx] // [] | .[]')
      if [[ -n "${ports}" ]]; then
        echo "    ports:" >> ${COMPOSE_FILE}
        for port in ${ports}; do
          echo "      - \"${port}\"" >> ${COMPOSE_FILE}
        done
      fi

      ## 检查并处理卷映射
      if [[ -n "${volumes}" ]]; then
        if [[ "${container_index}" == "1" ]]; then
          echo "    volumes:" >> ${COMPOSE_FILE}
          for volume in ${volumes}; do
            echo "      - \"${volume}\"" >> ${COMPOSE_FILE}
          done
        fi
#        echo "    volumes:" >> ${COMPOSE_FILE}
#        for volume in ${volumes}; do
#          echo "      - \"${volume}\"" >> ${COMPOSE_FILE}
#        done
      fi

      if [[ "${HOST_ARCHITECTURE}" == "altarch2x64" ]] && [[ "$(to_lowercase ${key})" == "centos7_x64" ]]; then
        echo "    platform: linux/amd64" >> "${COMPOSE_FILE}"
      fi
      echo "    <<: *${template}" >> ${COMPOSE_FILE}
      ((container_index++))
    done
  fi
done

# 定义两个网络 vm_net 和 vm_net2，每个网络分配不同的子网和网关
echo "
networks:
  vm_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.20.30.0/24
          gateway: 172.20.30.254
  vm_net2:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.40.0/24
          gateway: 172.20.40.254
" >> ${COMPOSE_FILE}

# 输出生成成功的提示信息
echo "docker-compose.yaml has been generated successfully."