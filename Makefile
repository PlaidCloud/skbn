GIT_TAG := $(shell git describe --tags --always)
GIT_COMMIT := $(shell git rev-parse --short HEAD)
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
LDFLAGS := "-X main.GitTag=${GIT_TAG} -X main.GitCommit=${GIT_COMMIT}"
DIST := $(CURDIR)/dist
DOCKER_USER := $(shell printenv DOCKER_USER)
DOCKER_PASSWORD := $(shell printenv DOCKER_PASSWORD)
# TRAVIS := $(shell printenv TRAVIS)
DOCKER_TAG := $(shell printenv DOCKER_TAG)

all: build docker push

fmt:
	go fmt ./pkg/... ./cmd/...

vet:
	go vet ./pkg/... ./cmd/...

# Build skbn binary
build: fmt vet
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags $(LDFLAGS) -o bin/skbn cmd/skbn.go

# Build skbn docker image
docker: fmt vet
	# cp bin/skbn skbn
	docker build -t gcr.io/plaidcloud-build/skbn:latest -t gcr.io/plaidcloud-build/skbn:$(GIT_BRANCH)-$(DOCKER_TAG) .
	# rm skbn


# Push will only happen in travis ci
push:
# ifdef TRAVIS
ifdef DOCKER_USER
ifdef DOCKER_PASSWORD
	printenv DOCKER_PASSWORD | docker login -u $(DOCKER_USER) --password-stdin https://gcr.io
	docker push gcr.io/plaidcloud-build/skbn:latest
	docker push gcr.io/plaidcloud-build/skbn:$(GIT_BRANCH)-$(DOCKER_TAG)
endif
endif
# endif

dist:
	mkdir -p $(DIST)
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags $(LDFLAGS) -o skbn cmd/skbn.go
	tar -zcvf $(DIST)/skbn-linux-$(GIT_TAG).tgz skbn
	rm skbn
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -ldflags $(LDFLAGS) -o skbn cmd/skbn.go
	tar -zcvf $(DIST)/skbn-macos-$(GIT_TAG).tgz skbn
	rm skbn
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -ldflags $(LDFLAGS) -o skbn.exe cmd/skbn.go
	tar -zcvf $(DIST)/skbn-windows-$(GIT_TAG).tgz skbn.exe
	rm skbn.exe
