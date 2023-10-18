PROJECT_NAME=alpine-php8.2-nginx-docker
REGISTRY_NAME=mathieulesniak/alpine-php8.2-nginx-docker

VERSION ?= latest

.PHONY: help
.DEFAULT_GOAL := help

help: ## This help.
        @awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build docker image
	docker build --rm -f "Dockerfile" -t ${PROJECT_NAME}:${VERSION} .
push: ## Push to docker registry
	docker tag ${PROJECT_NAME}:latest ${REGISTRY_NAME}:${VERSION}
	docker push ${REGISTRY_NAME}

build-and-push-multi: ## Build amd64 and arm64 images
	docker buildx build --rm  --platform linux/amd64,linux/arm64 -t ${REGISTRY_NAME}:${VERSION} --push .

