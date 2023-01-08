package config

import (
	"encoding/json"
	"testing"
	"io/ioutil"
)

func MockConfig(path string) {
	sampleConfig := []byte(`{
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
	}`)
	config := Config{}
	err := json.Unmarshal(sampleConfig, &config)
    if err != nil {
        t.Errorf("Expected error while unmarshaling config to struct.")
    }
	configJson, _ := json.Marshal(config)
    err = ioutil.WriteFile("/tmp/valid.json", configJson, 0644)
    if err != nil {
        t.Errorf("Encountered error while writing test config to file.")
    }
}

func TestFromFileValidPath(t *testing.T) {
	MockConfig("/tmp/valid.json")
	contents, err := FromFile("/tmp/valid.json")
	if err != nil && contents == nil{
		t.Errorf("Encountered error while parsing config from file.")
	}
}

func TestFromFileInvalidPath(t *testing.T) {
	contents, err := FromFile("/tmp/invalid.json")
	if err == nil && contents != nil{
		t.Errorf("Expected error while parsing config from file.")
	}
}
