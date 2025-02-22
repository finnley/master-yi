#!/bin/bash

# source prepare.sh
source .env

function echo_mysql_to_nginx() {
  if [[ ${MYSQL_5_7_ENABLE} == 'true' ]]; then
    cat <<EOF
- mysql57
EOF
  fi
  if [[ ${MYSQL_8_0_ENABLE} == 'true' ]]; then
  cat <<EOF
- mysql80
EOF
  fi
}

function echo_php_to_nginx() {
  if [[ ${PHP_ENABLE} == 'true' ]]; then
    cat <<EOF
depends_on:
      - php-fpm
EOF
  fi
}

cat > ./docker-compose.yaml <<EOF
version: "3"

services:
EOF


# MySQL 5.7
# no matching manifest for linux/arm64/v8 in the manifest list entries
# solution: https://stackoverflow.com/questions/65456814/docker-apple-silicon-m1-preview-mysql-no-matching-manifest-for-linux-arm64-v8
echo "MYSQL_5_7_ENABLE: ${MYSQL_5_7_ENABLE}"
# 最简单的部署
# if [[ ${MYSQL_5_7_ENABLE} == 'true' ]]; then
#   cat >> ./docker-compose.yaml <<EOF
#   mysql57:
#     # platform: linux/x86_64
#     platform: linux/amd64
#     image: mysql:${MYSQL_5_7_VERSION}
#     restart: always
#     command: --default-authentication-plugin=mysql_native_password
#     environment:
#       MYSQL_ROOT_PASSWORD: root
#     volumes:
#       # 设置初始化脚本
#       - ./mysql/docker-entrypoint-initdb.d/:/docker-entrypoint-initdb.d/
#     ports:
#       # 注意这里我映射为了 13357 端口
#       - "13357:3306"

# EOF
# fi


if [[ ${MYSQL_5_7_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  mysql57:
    container_name: mysql57
    # build:
    #   context: ./services/mysql
    #   args:
    #     - MYSQL_VERSION=${MYSQL_5_7_VERSION}
    platform: linux/amd64
    image: mysql:${MYSQL_5_7_VERSION}
    restart: always
    environment:
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - TIMEZONE=${TIMEZONE}
    volumes:
      - ${MYSQL_ENTRYPOINT_INITDB}:/docker-entrypoint-initdb.d
      # - ./mysql/5.7/conf:/etc/mysql/conf.d
      # - ${DATA_PATH_HOST}/mysql/5.7/data:/var/lib/mysql
    ports:
      - 3357:${MYSQL_PORT}

EOF
fi


# MySQL 8.0
echo "MYSQL_8_0_ENABLE: ${MYSQL_8_0_ENABLE}"
if [[ ${MYSQL_8_0_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  mysql80:
    image: mysql:${MYSQL_8_0_VERSION}
    restart: always
    command: --default-authentication-plugin=mysql_native_password
    environment:
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - TIMEZONE=${TIMEZONE}
    volumes:
      - ${MYSQL_ENTRYPOINT_INITDB}:/docker-entrypoint-initdb.d
    ports:
      - 3380:${MYSQL_PORT}

EOF
fi


echo "REDIS_ENABLE: ${REDIS_ENABLE}"
if [[ ${REDIS_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  redis:
    image: bitnami/redis:${REDIS_VERSION}
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
    ports:
      - 6379:${REDIS_PORT}

EOF
fi

echo "MONGODB_ENABLE: ${MONGODB_ENABLE}"
if [[ ${MONGODB_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  mongodb:
    container_name: mongodb
    restart: always
    build: ./mongodb
    ports:
      - "${MONGODB_PORT}:27017"
    environment:
      - MONGODB_INITDB_ROOT_USERNAME=${MONGODB_ROOT_USERNAME}
      - MONGODB_INITDB_ROOT_PASSWORD=${MONGODB_ROOT_PASSWORD}
    volumes:
      - ${DATA_PATH_HOST}/mongodb:/data/db
      - ${PWD}/mongodb/mongo-conf:/docker-entrypoint-initdb.d

EOF
fi

echo "CONSUL_ENABLE: ${CONSUL_ENABLE}"
if [[ ${CONSUL_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  consul:
    image: consul:${CONSUL_VERSION}
    ports:
      - 8300:8300
      - 8500:8500
      - 8301:8301
      - 8301:8301/udp
      - 8302:8302
      - 8302:8302/udp
      - 8600:8600
      - 8600:8600/udp
    # volumes:
    #   - ${PWD}/config:/consul/config
    #   - ${DATA_STORAGE_PATH}/consul/data:/consul/data
    restart: always
    command: agent -dev -client=0.0.0.0

EOF
fi


#--------------------------------------------------------------------------
# Nacos
#
# 单机版     
# docker run --name nacos-standalone -e MODE=standalone -e JVM_XMS=512m -e JVM_XMX=512m -e JVM_XMN=256m -p 8848:8848 -d nacos/nacos-server:latest
#--------------------------------------------------------------------------
echo "NACOS_ENABLE: ${NACOS_ENABLE}"
if [[ ${NACOS_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  nacos-standalone:
    container_name: nacos-standalone
    # platform: linux/amd64
    image: nacos/nacos-server:${NACOS_VERSION}
    ports:
      - 8848:8848 
    # volumes:
    #   - ./nacos/init.d/custom.properties:/home/nacos/init.d/custom.properties
    environment:
      - MODE=standalone                  
      - JVM_XMS=512m
      - JVM_XMX=512m
      - JVM_XMN=256m
    restart: always

EOF
fi


#--------------------------------------------------------------------------
# ETCD
#
# --------------------------------------------------------------------------
echo "ETCD_ENABLE: ${ETCD_ENABLE}"
if [[ ${ETCD_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  etcd:
    image: bitnami/etcd:${ETCD_VERSION}
    environment:
      - ALLOW_NONE_AUTHENTICATION=yes
    ports:
      - 12379:${ETCD_PORT}
EOF
fi


echo "SQLITE3_ENABLE: ${SQLITE3_ENABLE}"
if [[ ${SQLITE3_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  sqlite3:
    volumes:
      - ${PWD}/sqlite3:/data/db
      - ${PWD}/mongo_config:/data/configdb
      - ${PWD}/mongo/mongo-conf:/docker-entrypoint-initdb.d
    command: 'sqlite3 /data/mydatabase.db'

EOF
fi

