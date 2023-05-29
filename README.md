# `sh` [![pipeline](https://github.com/a6enez3r/sh/actions/workflows/pipeline.yml/badge.svg?branch=main)](https://github.com/a6enez3r/sh/actions/workflows/pipeline.yml)

link shortening and forwarding in 4 tiny Go packages :)

## install

download the binary [for your platform] using `curl`
```
  curl -L  https://github.com/a6enez3r/sh/raw/main/builds/sh-darwin-amd64 >> sh && chmod +x ./sh
```

## `quickstart`

start a `Redis` server

```shell
  redis-server
```

create a configuration file describing how to connect to `Redis` and such

```json
  {
      "server": {
        "port": "8080"
      },
      "options": {
        "schema": "http",
        "prefix": "localhost:8080"
      },
      "redis": {
        "host": "127.0.0.1",
        "port": "6379",
        "password": "supersecret"
      }
  }
```

start the forwarder server

```shell
  ./sh
```
once you have the link forwarder running you can shorten links using `curl` for instance

```shell
curl -L -X POST 'localhost:8080/encode' \
  -H 'Content-Type: application/json' \
  --data-raw '{
      "url": "https://golang.hotexamples.com/examples/github.com.valyala.fasthttp/RequestCtx/Redirect/golang-requestctx-redirect-method-examples.html",
      "expires": "2120-10-04 17:18:00"
  }'
```
which will return a much shorter link `{"success":true,"shortUrl":"http://localhost:8080/N0Q9H0NdYuk"}`

## `develop`
```
usage:
  make <cmd>

cmds:
  help                 show help
  save-local           save changes locally using git
  save-remote          save changes to remote using git
  pull-remote          pull changes from remote
  tag                  create new tag, recreate if it exists
  deps-dev             install deps [dev]
  build                cross platform build
  run                  run package
  test                 test package
  benchmark            benchmark package
  coverage             test coverage
  vet                  vet modules
  lint                 lint package
  format               format package
  scan-duplicate       scan package for duplicate code [dupl]
  scan-errors          scan package for errors [errcheck]
  scan-security        scan package for security issues [gosec]
  build-env            build docker env
  up-env               start docker env
  exec-env             exec. into docker env
  purge-env            remove docker env
  init-env             init env + install common tools
```
