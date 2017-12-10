GO_PKGS=$(shell go list ./... | grep -v '/vendor/')

build:
	go build  -o bin/hello

test:
	go test -race -v ${GO_PKGS}
lint: 
	golint ${GO_PKGS}
ci:
	.circleci/run.sh

.PHONY: build tools test lint ci
