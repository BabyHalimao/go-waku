
CC_TEST_REPORTER_ID := 343d0af350b29aaf08d1e5bb4465d0e21df6298a27240acd2434457a9984c74a
GO_HTML_COV         := ./coverage.html
GO_TEST_OUTFILE     := ./c.out
CC_PREFIX       	:= github.com/status-im/go-waku

.PHONY: all build lint test coverage build-example

all: build

deps: lint-install

build:
	go build -o build/waku waku.go

vendor:
	go mod tidy

lint-install:
	curl -sfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | \
		bash -s -- -b $(shell go env GOPATH)/bin v1.41.1

lint:
	@echo "lint"
	@golangci-lint --exclude=SA1019 run ./... --deadline=5m

test:
	go test ./waku/... -coverprofile=${GO_TEST_OUTFILE}.tmp
	cat ${GO_TEST_OUTFILE}.tmp | grep -v ".pb.go" > ${GO_TEST_OUTFILE}
	go tool cover -html=${GO_TEST_OUTFILE} -o ${GO_HTML_COV}

_before-cc:
	CC_TEST_REPORTER_ID=${CC_TEST_REPORTER_ID} ./coverage/cc-test-reporter before-build
	
_after-cc:
	CC_TEST_REPORTER_ID=${CC_TEST_REPORTER_ID} ./coverage/cc-test-reporter after-build --prefix ${CC_PREFIX}

test-ci: _before-cc test _after-cc

generate:
	go generate ./waku/v2/protocol/pb/generate.go

coverage:
	go test  -count 1 -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o=coverage.html

# build a docker image for the fleet
docker-image: DOCKER_IMAGE_TAG ?= latest
docker-image: DOCKER_IMAGE_NAME ?= statusteam/go-waku:$(DOCKER_IMAGE_TAG)
docker-image:
	docker build --tag $(DOCKER_IMAGE_NAME) \
		--build-arg="GIT_COMMIT=$(shell git rev-parse HEAD)" .

build-example-basic2:
	cd examples/basic2 && $(MAKE)

build-example-chat-2:
	cd examples/chat2 && $(MAKE)

build-example-filter2:
	cd examples/filter2 && $(MAKE)

build-example: build-example-basic2 build-example-chat-2 build-example-filter2