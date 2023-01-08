package storage

import "time"

type Service interface {
	Save(string, time.Time) (string, error)
	Load(string) (string, error)
	LoadInfo(string) (*Item, error)
	Close() error
	IsAvailable() bool
	Exists(uint64) bool
}

type Item struct {
	Id      uint64 `json:"id"      redis:"id"`
	URL     string `json:"url"     redis:"url"`
	Expires string `json:"expires" redis:"expires"`
	Visits  int    `json:"visits"  redis:"visits"`
}
