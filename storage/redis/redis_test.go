package redis

import (
	"os"
	"sh/base62"
	"github.com/stretchr/testify/assert"
	"testing"
	"time"
)

func getEnv(key, fallback string) string {
	value, exists := os.LookupEnv(key)
	if !exists {
		value = fallback
	}
	return value
}

func TestNewValid(t *testing.T) {
	db, err := New(
		getEnv("REDIS_HOST", "localhost"),
		getEnv("REDIS_PORT", "6399"),
		"pw",
		getEnv("REDIS_USERNAME", ""),
	)
	if err != nil && db.IsAvailable() == false {
		t.Errorf("Encountered error while initializing Redis database driver.")
	}
}

func TestNewInvalidHost(t *testing.T) {
	db, err := New("localhostt", getEnv("REDIS_PORT", "6399"), "pw", getEnv("REDIS_USERNAME", ""))
	if err == nil && db.IsAvailable() != false {
		t.Errorf("Expected error while initializing Redis database driver.")
	}
}

func TestNewInvalidPort(t *testing.T) {
	db, err := New(getEnv("REDIS_HOST", "localhost"), "6378", "pw", getEnv("REDIS_USERNAME", ""))
	if err == nil && db.IsAvailable() != false {
		t.Errorf("Expected error while initializing Redis database driver.")
	}
}

func TestNewInvalidPassword(t *testing.T) {
	db, err := New(
		getEnv("REDIS_HOST", "localhost"),
		getEnv("REDIS_PORT", "6399"),
		"pwttt",
		getEnv("REDIS_USERNAME", ""),
	)
	if err == nil && db.IsAvailable() != false {
		t.Errorf("Expected error while initializing Redis database driver.")
	}
}

func TestExistsNotSaved(t *testing.T) {
	db, err := New(
		getEnv("REDIS_HOST", "localhost"),
		getEnv("REDIS_PORT", "6399"),
		"pw",
		getEnv("REDIS_USERNAME", ""),
	)
	if err != nil && db.IsAvailable() == false {
		t.Errorf("Encountered error while initializing Redis database driver.")
	}
	assert.ObjectsAreEqual(db.Exists(uint64(1)), false)
}

func TestExistsSaved(t *testing.T) {
	db, err := New("127.0.0.1", getEnv("REDIS_PORT", "6399"), "pw", getEnv("REDIS_USERNAME", ""))
	if err != nil && db.IsAvailable() == false {
		t.Errorf("Encountered error while initializing Redis database driver.")
	}
	assert.ObjectsAreEqual(db.Exists(uint64(1)), false)
	expiration := time.Now().Add(time.Hour*1 + time.Minute*1 + time.Second*1)
	saveId, err := db.Save("http://google.com", expiration)
	if err != nil {
		t.Errorf("Encountered: %s while saving URL to Redis database.", err)
	}
	decoded, err := base62.Decode(saveId)
	if err != nil {
		t.Errorf("Encountered error while decoding URL id fetched from Redis database.")
	}
	assert.ObjectsAreEqual(db.Exists(uint64(decoded)), true)
}

func TestLoadNotSaved(t *testing.T) {
	db, err := New(
		getEnv("REDIS_HOST", "localhost"),
		getEnv("REDIS_PORT", "6399"),
		"pw",
		getEnv("REDIS_USERNAME", ""),
	)
	if err != nil && db.IsAvailable() == false {
		t.Errorf("Encountered error while initializing Redis database driver.")
	}
	loaded, err := db.Load(base62.Encode(uint64(1)))
	if err == nil {
		t.Errorf("Expected error while loading string from Redis database.")
	}
	assert.ObjectsAreEqual(loaded, false)
}

func TestLoadSaved(t *testing.T) {
	db, err := New("127.0.0.1", getEnv("REDIS_PORT", "6399"), "pw", getEnv("REDIS_USERNAME", ""))
	if err != nil && db.IsAvailable() == false {
		t.Errorf("Encountered error while initializing Redis database driver.")
	}
	assert.ObjectsAreEqual(db.Exists(uint64(1)), false)
	expiration := time.Now().Add(time.Hour*1 + time.Minute*1 + time.Second*1)
	saveId, err := db.Save("http://google.com", expiration)
	if err != nil {
		t.Errorf("Encountered: %s while saving URL to Redis database.", err)
	}
	loaded, err := db.Load(saveId)
	if err != nil {
		t.Errorf("Encountered error while loading string from Redis database.")
	}
	assert.ObjectsAreEqual(loaded, "http://google.com")
}

func TestSaveSuccessive(t *testing.T) {
	db, err := New("127.0.0.1", getEnv("REDIS_PORT", "6399"), "pw", getEnv("REDIS_USERNAME", ""))
	if err != nil && db.IsAvailable() == false {
		t.Errorf("Encountered error while initializing Redis database driver.")
	}
	assert.ObjectsAreEqual(db.Exists(uint64(1)), false)
	firstExpiration := time.Now().Add(time.Hour*1 + time.Minute*1 + time.Second*1)
	firstSaveId, err := db.Save("http://google.com", firstExpiration)
	if err != nil {
		t.Errorf("Encountered: %s while saving URL to Redis database.", err)
	}
	firstDecoded, err := base62.Decode(firstSaveId)
	secondExpiration := time.Now().Add(time.Hour*1 + time.Minute*1 + time.Second*1)
	secondSaveId, err := db.Save("http://mail.google.com", secondExpiration)
	if err != nil {
		t.Errorf("Encountered: %s while saving URL to Redis database.", err)
	}
	secondDecoded, err := base62.Decode(secondSaveId)
	if err != nil {
		t.Errorf("Encountered error while decoding URL id fetched from Redis database.")
	}
	assert.ObjectsAreEqual(db.Exists(uint64(firstDecoded)), true)
	assert.ObjectsAreEqual(db.Exists(uint64(secondDecoded)), true)
}

func TestSaveWithExpiration(t *testing.T) {
	db, err := New("127.0.0.1", getEnv("REDIS_PORT", "6399"), "pw", getEnv("REDIS_USERNAME", ""))
	if err != nil && db.IsAvailable() == false {
		t.Errorf("Encountered error while initializing Redis database driver.")
	}
	assert.ObjectsAreEqual(db.Exists(uint64(1)), false)
	expiration := time.Now().Add(time.Second * 1)
	saveId, err := db.Save("http://google.com", expiration)
	if err != nil {
		t.Errorf("Encountered: %s while saving URL to Redis database.", err)
	}
	time.Sleep(2 * time.Second)
	decoded, err := base62.Decode(saveId)
	if err != nil {
		t.Errorf("Encountered error while decoding URL id fetched from Redis database.")
	}
	assert.ObjectsAreEqual(db.Exists(uint64(decoded)), false)
}
