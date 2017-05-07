include makes/env.mk
include makes/local.mk
include makes/docker.mk

.PHONY: docker-bench
docker-bench: ARGS = -benchmem
docker-bench: docker-bench-1.7
docker-bench: docker-bench-1.8
docker-bench: docker-bench-latest

.PHONY: docker-glide
docker-glide: COMMAND = -y research.yml install
docker-glide: ARGS    = --strip-vendor
docker-glide: docker-tool-glide

.PHONY: docker-gometalinter
docker-gometalinter: ARGS = --vendor --deadline=1m ./...
docker-gometalinter: docker-tool-gometalinter

.PHONY: docker-pull
docker-pull: docker-pull-1.7
docker-pull: docker-pull-1.8
docker-pull: docker-pull-latest
docker-pull: docker-pull-tools
docker-pull: PRUNE = --force
docker-pull: docker-clean

.PHONY: docker-test
docker-test: ARGS = -v
docker-test: docker-test-1.7
docker-test: docker-test-1.8
docker-test: docker-test-latest

.PHONY: docker-test-with-coverage
docker-test-with-coverage: ARGS = -v
docker-test-with-coverage: OPEN_BROWSER = true
docker-test-with-coverage: docker-test-with-coverage-1.7
docker-test-with-coverage: docker-test-with-coverage-1.8
docker-test-with-coverage: docker-test-with-coverage-latest

.PHONY: pull-github-tpl
pull-github-tpl:
	rm -rf .github
	(git clone git@github.com:kamilsk/shared.git .github && cd .github && git checkout github-tpl-go-v1 \
	  && echo 'github templates at revision' $$(git rev-parse HEAD) && rm -rf .git)

.PHONY: pull-makes
pull-makes:
	rm -rf makes
	(git clone git@github.com:kamilsk/shared.git makes && cd makes && git checkout makefile-go-v1 \
	  && echo 'makes at revision' $$(git rev-parse HEAD) && rm -rf .git)

.PHONY: cmd-test
cmd-test:
	docker run --rm \
	           -v '$(GOPATH)/src/$(GO_PACKAGE)':'/go/src/$(GO_PACKAGE)' \
	           -w '/go/src/$(GO_PACKAGE)' \
	           golang:1.7 \
	           /bin/sh -c 'go install -ldflags "-X 'main.Timeout=100ms' -X 'main.Version=0.1'" ./cmd/retry && \
	                       retry -limit=3 -backoff=lin[10ms] -timeout=200ms -- curl http://unknown.host'
