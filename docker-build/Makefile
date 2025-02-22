HOST_ARCHITECTURE=el7_altarch el8_aarch64

.PHONY: default build help ${HOST_ARCHITECTURE}

default: help

help:
	@echo "Usage: make [TARGET]"
	@echo ""
	@echo "Targets:"
	@echo "  build            Build all specified architectures."
	@echo "  el7_x86_64       Build for CentOS 7 x86_64 architecture."
	@echo "  el7_altarch      Build for CentOS 7 altarch architecture."
	@echo "  el8_aarch64      Build for CentOS 8 aarch64 architecture."
	@echo "  ubuntu2004_amd64 Build for Ubuntu 20.04 amd64 architecture."
	@echo "  help             Show this help message."

build: ${HOST_ARCHITECTURE}

el7_x86_64:
	docker build -f Dockerfile.el7.x86_64 -t harbor.einscat.com:10011/library/centos7:x86_64 .

el7_altarch:
	DOCKER_BUILDKIT=0 docker build -f Dockerfile.el7.altarch -t harbor.einscat.com:10011/library/centos7:altarch .

el8_aarch64:
	DOCKER_BUILDKIT=0 docker build -f Dockerfile.el8.aarch64 -t harbor.einscat.com:10011/library/centos8:aarch64 .

ubuntu2004_amd64:
	docker build -f Dockerfile.ubuntu2004.amd64 -t harbor.einscat.com:10011/library/ubuntu2004:amd64 .
