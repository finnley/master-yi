PWD = $(shell pwd)
TARGET_DOCKER_TMP_DIR = "/tmp/deploy"
TARGET_DOCKER = "chaos-1"

# 默认为本地环境
ENV_TYPE ?= local

# 验证 ENV_TYPE 参数
ifeq ($(filter $(ENV_TYPE),local test),)
    $(error ENV_TYPE must be either 'local' or 'test')
endif

default: docker_up

install:
	make docker_up
#	docker exec ${TARGET_DOCKER} rm -rf ${TARGET_DOCKER_TMP_DIR}
#	docker cp ${PWD} ${TARGET_DOCKER}:${TARGET_DOCKER_TMP_DIR}
	#docker exec -t ${TARGET_DOCKER} chmod +x ${TARGET_DOCKER_TMP_DIR}/udp_install.sh
	#docker exec -t ${TARGET_DOCKER} ${TARGET_DOCKER_TMP_DIR}/udp_install.sh

prepare:
	./setup.sh

docker_up:
	docker compose up -d

clean:
	docker compose down --remove-orphans
