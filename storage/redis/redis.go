package redis

import (
	"errors"
	"fmt"
	"sh/base62"
	"sh/storage"
	redisClient "github.com/garyburd/redigo/redis"
	"math/rand"
	"strconv"
	"time"
)

// ErrNoLink : custom error type
type ErrNoLink struct {
	StatusCode int
	Err        error
}

func (r *ErrNoLink) Error() string {
	return fmt.Sprintf("status %d: err %v", r.StatusCode, r.Err)
}

// redis : custom Redis object + common methods
type redis struct{ pool *redisClient.Pool }

// New : create a new Redis connection pool
func New(host, port, password, username string) (storage.Service, error) {
	pool := &redisClient.Pool{
		MaxIdle:     10,
		IdleTimeout: 240 * time.Second,
		Dial: func() (redisClient.Conn, error) {
			return redisClient.DialURL(
				fmt.Sprintf("redis://%s:%s@%s:%s", username, password, host, port),
			)
		},
	}

	return &redis{pool}, nil
}

// Exists : check whether a given key exists in Redis
func (r *redis) Exists(id uint64) bool {
	conn := r.pool.Get()
	defer conn.Close()

	exists, err := redisClient.Bool(conn.Do("EXISTS", strconv.FormatUint(id, 10)))
	if err != nil {
		return false
	}
	return exists
}

// Save : shorten and save a link to Redis
func (r *redis) Save(url string, expires time.Time) (string, error) {
	conn := r.pool.Get()
	defer conn.Close()

	var id uint64

	for used := true; used; used = r.Exists(id) {
		id = rand.Uint64()
	}

	shortLink := storage.Item{id, url, expires.Format("2100-01-02 15:04:05.728046 +0300 EEST"), 0}
	_, err := conn.Do(
		"HMSET",
		id,
		"url",
		shortLink.URL,
		"expires",
		shortLink.Expires,
		"visits",
		shortLink.Visits,
	)

	if err != nil {
		return "", err
	}

	return base62.Encode(id), nil
}

// Load : fetch a shortened link by unique identifier
func (r *redis) Load(code string) (string, error) {
	conn := r.pool.Get()
	defer conn.Close()

	id, _ := base62.Decode(code)

	urlString, err := redisClient.String(
		conn.Do("HGET", id, "url"),
	)

	if err != nil {
		return "", err
	} else if len(urlString) == 0 {
		return "", &ErrNoLink{
			StatusCode: 404,
			Err:        errors.New("unavailable"),
		}
	}

	_, err = conn.Do("HINCRBY", id, "visits", 1)

	return urlString, nil
}

// LoadInfo : fetch info about a shortened link
func (r *redis) LoadInfo(code string) (*storage.Item, error) {
	conn := r.pool.Get()
	defer conn.Close()

	id, _ := base62.Decode(code)

	values, err := redisClient.Values(
		conn.Do("HGETALL", id),
	)

	if err != nil {
		return nil, err
	} else if len(values) == 0 {
		return nil, &ErrNoLink{
			StatusCode: 404,
			Err:        errors.New("unavailable"),
		}
	}
	var shortLink storage.Item
	err = redisClient.ScanStruct(values, &shortLink)
	if err != nil {
		return nil, err
	}

	return &shortLink, nil
}

// Close : close a connection instance
func (r *redis) Close() error {
	return r.pool.Close()
}

// IsAvailable: check whether Redis is available
func (r *redis) IsAvailable() bool {
	conn := r.pool.Get()
	_, err := conn.Do("PING")
	if err != nil {
		return false
	}
	return true
}
