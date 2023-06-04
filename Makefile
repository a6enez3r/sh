pn := sh
tn := tests

ifeq ($(version),)
version := 0.0.1
endif
ifeq ($(commit_message),)
commit_message := default commit message
endif
ifeq ($(branch),)
branch := main
endif
ifeq ($(pytest_opts),)
pytest_opts := -vv
endif
ifeq ($(dep_type),)
dep_type := development
endif
ifeq ($(container_tag),)
container_tag := ${dep_type}
endif
ifeq ($(docker_env),)
docker_env := development
endif
ifeq ($(durations),)
durations := 10
endif
ifeq ($(${dep_cmd}),)
dep_cmd := install
endif
ifeq ($(${docker_env}),)
docker_env := development
endif
ifeq ($($(bin_path)),)
bin_path := /Users/abenezer/go/1.18.0/bin/
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

## save changes locally [git]
save-local:
	@echo "saving..."
	@git add .
	@git commit -m "${commit_message}"

## save changes to remote [git]
save-remote:
	@echo "saving to remote..."
	@git push origin ${branch}

## pull changes from remote
pull-remote:
	@echo "pulling from remote..."
	@git pull origin ${branch}

## create new tag, recreate if it exists
tag:
	@git tag -d ${version} || : 
	@git push --delete origin ${version} || : 
	@git tag -a ${version} -m "latest version" 
	@git push origin --tags

## -- go --

## install deps
deps:
	# tools
	@sudo curl -sfL https://raw.githubusercontent.com/securego/gosec/master/install.sh | sudo sh -s -- -b $(shell go env GOPATH)/bin v2.9.5
	@go ${dep_cmd} golang.org/x/lint/golint@latest
	@go ${dep_cmd} go101.org/golds@latest
	@go ${dep_cmd} github.com/segmentio/golines@latest
	@go ${dep_cmd} github.com/kisielk/errcheck@latest
	@go ${dep_cmd} github.com/mibk/dupl@latest
	# deps
	@go mod download
	
## cross platform build
build-all:
	@rm -rf builds && mkdir builds && chmod +x ./scripts/go-build-all && ./scripts/go-build-all && mv ${pn}-* builds

## current platform build
build:
	@go build -o ${pn} main.go cli.go

## run package
run:
	@go run main.go cli.go

## test package
test:
	@go test -v ./...

## benchmark package
benchmark:
	@go test -bench=. ./jak/

## test coverage
coverage:
	@go test -v ./... -coverprofile cp.out && go tool cover -html=cp.out

## vet modules
vet:
	@go vet .

## -- code quality --

## lint package
lint:
	@${bin_path}golint .

## format package
format:
	@${bin_path}golines -w main.go
	@${bin_path}golines -w cli.go
	@${bin_path}golines -w blackjack

## scan package for duplicate code [dupl]
scan-duplicate:
	@${bin_path}dupl .

## scan package for errors [errcheck]
scan-errors:
	@${bin_path}errcheck ./...

## scan package for security issues [gosec]
scan-security:
	@${bin_path}gosec ./...

## -- docs --

## serve docs [godoc]
docs-serve:
	${bin_path}golds ./...

## -- docker --

## build docker env
build-env:
	@docker build -t ${pn}:${container_tag} -f dockerfiles/Dockerfile.${docker_env} .

## start docker env
up-env: build-env
	$(eval cid = $(shell (docker ps -aqf "name=${pn}")))
	$(if $(strip $(cid)), \
		@echo "existing env container found. please run make purge-env",\
		@echo "running env container..." && docker run -it -d -v $(CURDIR):/go/src/ --name ${pn} ${pn}:${container_tag} /bin/bash)
	$(endif)

## exec. into docker env
exec-env:
	$(eval cid = $(shell (docker ps -aqf "name=${pn}")))
	$(if $(strip $(cid)), \
		@echo "exec into env container..." && docker exec -it ${cid} bash,\
		@echo "env container not running.")
	$(endif)

## remove docker env
purge-env:
	$(eval cid = $(shell (docker ps -aqf "name=${pn}")))
	$(if $(strip $(cid)), \
		@echo "purging env container..." && docker stop ${pn} && docker rm ${pn},\
		@echo "env container not running.")
	$(endif)

## get status of docker env
status-env:
	$(eval cid = $(shell (docker ps -aqf "name=${pn}")))
	$(if $(strip $(cid)), \
		@echo "container running",\
		@echo "container not running.")
	$(endif)

## init env + install common tools
init-env:
	@apk update
	@apk add --update curl
	@apk add --update sudo
	@apk add --update bash
	@apk add --update ncurses
