package main

import (
	"log"
	"sh/config"
	"sh/handler"
	"sh/storage/redis"

	"github.com/valyala/fasthttp"
)

func main() {
	configuration, err := config.FromFile("./configuration.json")
	if err != nil {
		log.Fatal(err)
	}

	service, err := redis.New(
		configuration.Redis.Host,
		configuration.Redis.Port,
		configuration.Redis.Password,
		configuration.Redis.Username,
	)
	if err != nil {
		log.Fatal(err)
	}
	defer service.Close()

	router := handler.New(configuration.Options.Schema, configuration.Options.Prefix, service)

	log.Fatal(fasthttp.ListenAndServe(":"+configuration.Server.Port, router.Handler))
}
