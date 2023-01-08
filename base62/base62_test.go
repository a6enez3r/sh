package base62

import (
	"testing"
	"github.com/stretchr/testify/assert"
)

func TestEncodeReturnType(t *testing.T) {
	assert.IsType(t, Encode(7), "encoded")
}

func TestEncodeReturnLength(t *testing.T) {
	assert.ObjectsAreEqual(len(Encode(7)), 7)
	assert.ObjectsAreEqual(len(Encode(2)), 2)
	assert.ObjectsAreEqual(len(Encode(11)), 11)
}

func TestDecodeReturnType(t *testing.T) {
	decoded, err := Decode("encoded")
	if err != nil {
		t.Errorf("Encountered unexpected error while decoding.")
	}
	assert.IsType(t, decoded, uint64(7))
}

func TestEncodeSuccessive(t *testing.T) {
	encoded := Encode(7)
	assert.ObjectsAreEqual(Encode(7),encoded)
}