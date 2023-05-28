pn := sh

ifeq ($(version),)
version := 0.0.1
endif
ifeq ($(commit_message),)
commit_message := default commit message
endif
ifeq ($(branch),)
branch := main
endif
ifeq ($(${docker_env}),)
docker_env := development
endif
ifeq ($(container_name),)
container_name := jak_${docker_env}
endif
ifeq ($(container_tag),)
container_tag := latest
endif
ifeq ($(${dep_cmd}),)
dep_cmd := install
endif

.DEFAULT_GOAL := help
TARGET_MAX_CHAR_NUM=20
# COLORS
ifneq (,$(findstring xterm,${TERM}))
	BLACK        := $(shell tput -Txterm setaf 0 || exit 0)
	RED          := $(shell tput -Txterm setaf 1 || exit 0)
	GREEN        := $(shell tput -Txterm setaf 2 || exit 0)
	YELLOW       := $(shell tput -Txterm setaf 3 || exit 0)
	LIGHTPURPLE  := $(shell tput -Txterm setaf 4 || exit 0)
	PURPLE       := $(shell tput -Txterm setaf 5 || exit 0)
	BLUE         := $(shell tput -Txterm setaf 6 || exit 0)
	WHITE        := $(shell tput -Txterm setaf 7 || exit 0)
	RESET := $(shell tput -Txterm sgr0)
else
	BLACK        := ""
	RED          := ""
	GREEN        := ""
	YELLOW       := ""
	LIGHTPURPLE  := ""
	PURPLE       := ""
	BLUE         := ""
	WHITE        := ""
	RESET        := ""
endif

## show usage / common commands available
.PHONY: help
help:
	@printf "${RED}cmds:\n\n";

	@awk '{ \
			if ($$0 ~ /^.PHONY: [a-zA-Z\-\_0-9]+$$/) { \
				helpCommand = substr($$0, index($$0, ":") + 2); \
				if (helpMessage) { \
					printf "  ${PURPLE}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n\n", helpCommand, helpMessage; \
					helpMessage = ""; \
				} \
			} else if ($$0 ~ /^[a-zA-Z\-\_0-9.]+:/) { \
				helpCommand = substr($$0, 0, index($$0, ":")); \
				if (helpMessage) { \
					printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
					helpMessage = ""; \
				} \
			} else if ($$0 ~ /^##/) { \
				if (helpMessage) { \
					helpMessage = helpMessage"\n                     "substr($$0, 3); \
				} else { \
					helpMessage = substr($$0, 3); \
				} \
			} else { \
				if (helpMessage) { \
					print "\n${LIGHTPURPLE}             "helpMessage"\n" \
				} \
				helpMessage = ""; \
			} \
		}' \
		$(MAKEFILE_LIST)

## -- git --

## save changes locally using git
save-local:
	@echo "saving..."
	@git add .
	@git commit -m "${commit_message}"

## save changes to remote using git
save-remote:
	@echo "saving to remote..."
	@git push origin ${branch}

## pull changes from remote
pull-remote:
	@echo "pulling from remote..."
	@git merge origin ${branch}

## create new tag, recreate if it exists
tag:
	@git tag -d ${version} || : 
	@git push --delete origin ${version} || : 
	@git tag -a ${version} -m "latest" 
	@git push origin --tags

## -- go --

## install deps [dev]
deps:
	# gosec
	# sudo curl -sfL https://raw.githubusercontent.com/securego/gosec/master/install.sh | sudo sh -s -- -b $(go env GOPATH)/bin v2.9.5
	# golines
	go ${dep_cmd} github.com/segmentio/golines@latest
	# errcheck
	go ${dep_cmd} github.com/kisielk/errcheck@latest
	# dupl
	go ${dep_cmd} github.com/mibk/dupl@latest
	# golint
	go get golang.org/x/lint/golint
	# deps
	go mod download
	
## cross platform build
build:
	rm -rf builds && mkdir builds && chmod +x ./scripts/go-build-all && ./scripts/go-build-all && mv ${pn}-* builds

## run package
run:
	go run main.go

## test package
test:
	go test -v ./...

## benchmark package
benchmark:
	go test -bench=. ./sh/

## test coverage
coverage:
	go test -v ./... -coverprofile cp.out && go tool cover -html=cp.out

## vet modules
vet:
	go vet .

## -- code quality --

UNAME_S := $(shell uname -s)

## lint package
lint:
ifeq ($(UNAME_S),Linux)
	@~/go/bin/golint .
endif
ifeq ($(UNAME_S),Darwin)
	@golint .
endif

## format package
format:
	golines -w main.go
	golines -w base62
	golines -w config
	golines -w handler
	golines -w storage

## scan package for duplicate code [dupl]
scan-duplicate:
	dupl .

## scan package for errors [errcheck]
scan-errors:
	errcheck ./...

## scan package for security issues [gosec]
scan-security:
	gosec ./...

## -- docker --

## build docker env
build-env:
	@docker build -t ${container_name}:${container_tag} -f dockerfiles/Dockerfile.${docker_env} .

## start docker env
up-env: build-env
	$(eval cid = $(shell (docker ps -aqf "name=${container_name}")))
	$(if $(strip $(cid)), \
		@echo "existing env container found. please run make purge-env",\
		@echo "running env container..." && docker run -it -d -v $(CURDIR):/go/src/ --name ${container_name} ${container_name}:${container_tag} /bin/bash)
	$(endif)

## exec. into docker env
exec-env:
	$(eval cid = $(shell (docker ps -aqf "name=${container_name}")))
	$(if $(strip $(cid)), \
		@echo "exec into env container..." && docker exec -it ${cid} bash,\
		@echo "env container not running.")
	$(endif)

## remove docker env
purge-env:
	$(eval cid = $(shell (docker ps -aqf "name=${container_name}")))
	$(if $(strip $(cid)), \
		@echo "purging env container..." && docker stop ${container_name} && docker rm ${container_name},\
		@echo "env container not running.")
	$(endif)

## get status of docker env
status-env:
	$(eval cid = $(shell (docker ps -aqf "name=${container_name}")))
	$(if $(strip $(cid)), \
		@echo "container running",\
		@echo "container not running.")
	$(endif)

## init env + install common tools
init-env:
	apk update
	apk add --update curl
	apk add --update sudo
	apk add --update bash
	apk add --update ncurses
