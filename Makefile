# make all builds both cloud and edge binaries

COMPONENTS=cloudcore \
            admission \
            edgecore \
            edgesite \
            keadm

.EXPORT_ALL_VARIABLES:
OUT_DIR ?= _output

define ALL_HELP_INFO
# Build code.
#
# Args:
#   WHAT: Component names to build.  
#		the build will produce executable files under $(OUT_DIR)
#     If not specified, "everything" will be built.
#
# Example:
#   make
#   make all
#   make all HELP=y
#   make all WHAT=cloudcore
#   make all WHAT=admission
#   make all WHAT=edgecore
#   make all WHAT=edgesite
#   make all WHAT=keadm
endef

.PHONY: all
ifeq ($(HELP),y)
all:
	@echo "$$ALL_HELP_INFO"
else
all: verify-golang
	hack/make-rules/build.sh $(WHAT)
endif


define VERIFY_HELP_INFO
# verify golang,vendor and codegen
#
# Example:
# make verify 
endef
.PHONY: verify
ifeq ($(HELP),y)
verify:
	@echo "$$VERIFY_HELP_INFO"
else
verify:verify-golang verify-vendor verify-codegen 
endif

.PHONY: verify-golang
verify-golang: 
	bash hack/verify-golang.sh

.PHONY: verify-vendor
verify-vendor: 
	bash hack/verify-vendor.sh
.PHONY: verify-codegen
verify-codegen: 
	bash cloud/hack/verify-codegen.sh


####################################

# unit tests
.PHONY: edge_test
edge_test:
	cd edge && $(MAKE) test

.PHONY: cloud_test
cloud_test:
	$(MAKE) -C cloud test

# lint
.PHONY: lint
lint:edge_lint cloud_lint bluetoothdevice_lint keadm_lint

.PHONY: edge_lint
edge_lint:
	cd edge && $(MAKE) lint

.PHONY: cloud_lint
cloud_lint:
	cd cloud && $(MAKE) lint

.PHONY: bluetoothdevice_lint
bluetoothdevice_lint:
	make -C mappers/bluetooth_mapper lint

.PHONY: keadm_lint
keadm_lint:
	make -C keadm lint

.PHONY: edge_integration_test
edge_integration_test:
	cd edge && $(MAKE) integration_test

.PHONY: edge_cross_build
edge_cross_build:
	cd edge && $(MAKE) cross_build

.PHONY: edge_cross_build_v7
edge_cross_build_v7:
	$(MAKE) -C edge armv7

.PHONY: edge_cross_build_v8
edge_cross_build_v8:
	$(MAKE) -C edge armv8

.PHONY: edgesite_cross_build
edgesite_cross_build:
	$(MAKE) -C edgesite cross_build

.PHONY: edge_small_build
edge_small_build:
	cd edge && $(MAKE) small_build

.PHONY: edgesite_cross_build_v7
edgesite_cross_build_v7:
	$(MAKE) -C edgesite armv7

.PHONY: edgesite_cross_build_v8
edgesite_cross_build_v8:
	$(MAKE) -C edgesite armv8

.PHONY: edgesite_small_build
edgesite_small_build:
	$(MAKE) -C edgesite small_build

.PHONY: e2e_test
e2e_test:
#	bash tests/e2e/scripts/execute.sh device_crd
#	This has been commented temporarily since there is an issue of CI using same master for all PRs, which is causing failures when run parallely
	bash tests/e2e/scripts/execute.sh

.PHONY: performance_test
performance_test:
	bash tests/performance/scripts/jenkins.sh

QEMU_ARCH ?= x86_64
ARCH ?= amd64
IMAGE_TAG ?= $(shell git describe --tags)

.PHONY: cloudimage
cloudimage:
	docker build -t kubeedge/cloudcore:${IMAGE_TAG} -f build/cloud/Dockerfile .

.PHONY: admissionimage
admissionimage:
	docker build -t kubeedge/admission:${IMAGE_TAG} -f build/admission/Dockerfile .

.PHONY: csidriverimage
csidriverimage:
	docker build -t kubeedge/csidriver:${IMAGE_TAG} -f build/csidriver/Dockerfile .

.PHONY: edgeimage
edgeimage:
	mkdir -p ./build/edge/tmp
	rm -rf ./build/edge/tmp/*
	curl -L -o ./build/edge/tmp/qemu-${QEMU_ARCH}-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/v3.0.0/qemu-${QEMU_ARCH}-static.tar.gz
	tar -xzf ./build/edge/tmp/qemu-${QEMU_ARCH}-static.tar.gz -C ./build/edge/tmp
	docker build -t kubeedge/edgecore:${IMAGE_TAG} \
	--build-arg BUILD_FROM=${ARCH}/golang:1.12-alpine3.10 \
	--build-arg RUN_FROM=${ARCH}/docker:dind \
	-f build/edge/Dockerfile .

.PHONY: edgesiteimage
edgesiteimage:
	mkdir -p ./build/edgesite/tmp
	rm -rf ./build/edgesite/tmp/*
	curl -L -o ./build/edgesite/tmp/qemu-${QEMU_ARCH}-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/v3.0.0/qemu-${QEMU_ARCH}-static.tar.gz
	tar -xzf ./build/edgesite/tmp/qemu-${QEMU_ARCH}-static.tar.gz -C ./build/edgesite/tmp
	docker build -t kubeedge/edgesite:${IMAGE_TAG} \
	--build-arg BUILD_FROM=${ARCH}/golang:1.12-alpine3.10 \
	--build-arg RUN_FROM=${ARCH}/docker:dind \
	-f build/edgesite/Dockerfile .


.PHONY: bluetoothdevice
bluetoothdevice:
	make -C mappers/bluetooth_mapper

.PHONY: bluetoothdevice_image
bluetoothdevice_image:
	make -C mappers/bluetooth_mapper bluetooth_mapper_image
