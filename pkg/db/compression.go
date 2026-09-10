package db

import (
	"github.com/golang/snappy"
)

const CompressionThreshold = 512
const CompressionFlag = 0x80

// compressPayload comprime se valer a pena
func compressPayload(payload []byte, healthScore uint8) ([]byte, uint8) {
	if len(payload) <= CompressionThreshold {
		return payload, healthScore
	}
	compressed := snappy.Encode(nil, payload)
	if len(compressed) < len(payload) {
		return compressed, healthScore | CompressionFlag
	}
	return payload, healthScore
}

// decompressPayload descomprime se a flag estiver setada
func decompressPayload(data []byte, healthScore uint8) ([]byte, error) {
	if healthScore&CompressionFlag == 0 {
		return data, nil
	}
	return snappy.Decode(nil, data)
}
