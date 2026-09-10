package export

import (
	"encoding/binary"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"time"
)

type Record struct {
	Timestamp    int64  `json:"timestamp"`
	TimestampRFC string `json:"timestamp_rfc"`
	WorkerID     int32  `json:"worker_id"`
	HealthScore  int32  `json:"health_score"`
	Payload      string `json:"payload"`
}

type Exporter struct {
	storagePath string
	batchSize   int
}

func NewExporter(storagePath string) *Exporter {
	return &Exporter{
		storagePath: storagePath,
		batchSize:   10000,
	}
}

func (e *Exporter) ExportCSV(outputPath string, minHealth uint8) (int, error) {
	file, err := os.Open(e.storagePath)
	if err != nil {
		return 0, fmt.Errorf("falha ao abrir storage: %w", err)
	}
	defer file.Close()

	outFile, err := os.Create(outputPath)
	if err != nil {
		return 0, fmt.Errorf("falha ao criar CSV: %w", err)
	}
	defer outFile.Close()

	writer := csv.NewWriter(outFile)
	defer writer.Flush()

	// Cabeçalho
	if err := writer.Write([]string{"timestamp", "timestamp_rfc", "worker_id", "health_score", "payload"}); err != nil {
		return 0, fmt.Errorf("falha ao escrever cabeçalho: %w", err)
	}

	const (
		MagicByte  = byte(0xAA)
		HeaderSize = 18
	)

	headerBuf := make([]byte, HeaderSize)
	payloadBuf := make([]byte, 0, 1024*1024)
	totalRecords := 0

	for {
		_, err := io.ReadFull(file, headerBuf)
		if err == io.EOF {
			break
		}
		if err != nil {
			return totalRecords, fmt.Errorf("erro ao ler cabeçalho: %w", err)
		}

		if headerBuf[0] != MagicByte {
			return totalRecords, fmt.Errorf("magic byte incorreto")
		}

		timestamp := binary.BigEndian.Uint64(headerBuf[1:9])
		workerID := binary.BigEndian.Uint32(headerBuf[9:13])
		healthScore := headerBuf[13]
		payloadSize := binary.BigEndian.Uint32(headerBuf[14:18])

		if healthScore < minHealth {
			_, err = file.Seek(int64(payloadSize), io.SeekCurrent)
			if err != nil {
				return totalRecords, fmt.Errorf("erro no seek: %w", err)
			}
			continue
		}

		if uint32(cap(payloadBuf)) < payloadSize {
			payloadBuf = make([]byte, payloadSize)
		} else {
			payloadBuf = payloadBuf[:payloadSize]
		}

		_, err = io.ReadFull(file, payloadBuf)
		if err != nil {
			return totalRecords, fmt.Errorf("erro ao ler payload: %w", err)
		}

		t := time.Unix(0, int64(timestamp)).UTC()
		record := []string{
			fmt.Sprintf("%d", timestamp),
			t.Format(time.RFC3339),
			fmt.Sprintf("%d", workerID),
			fmt.Sprintf("%d", healthScore),
			string(payloadBuf),
		}

		if err := writer.Write(record); err != nil {
			return totalRecords, fmt.Errorf("erro ao escrever registro: %w", err)
		}
		totalRecords++
	}

	return totalRecords, nil
}

func (e *Exporter) ExportJSON(outputPath string, minHealth uint8) (int, error) {
	file, err := os.Open(e.storagePath)
	if err != nil {
		return 0, fmt.Errorf("falha ao abrir storage: %w", err)
	}
	defer file.Close()

	outFile, err := os.Create(outputPath)
	if err != nil {
		return 0, fmt.Errorf("falha ao criar JSON: %w", err)
	}
	defer outFile.Close()

	const (
		MagicByte  = byte(0xAA)
		HeaderSize = 18
	)

	headerBuf := make([]byte, HeaderSize)
	payloadBuf := make([]byte, 0, 1024*1024)
	records := make([]Record, 0, e.batchSize)
	totalRecords := 0

	for {
		_, err := io.ReadFull(file, headerBuf)
		if err == io.EOF {
			break
		}
		if err != nil {
			return totalRecords, fmt.Errorf("erro ao ler cabeçalho: %w", err)
		}

		if headerBuf[0] != MagicByte {
			return totalRecords, fmt.Errorf("magic byte incorreto")
		}

		timestamp := binary.BigEndian.Uint64(headerBuf[1:9])
		workerID := binary.BigEndian.Uint32(headerBuf[9:13])
		healthScore := headerBuf[13]
		payloadSize := binary.BigEndian.Uint32(headerBuf[14:18])

		if healthScore < minHealth {
			_, err = file.Seek(int64(payloadSize), io.SeekCurrent)
			if err != nil {
				return totalRecords, fmt.Errorf("erro no seek: %w", err)
			}
			continue
		}

		if uint32(cap(payloadBuf)) < payloadSize {
			payloadBuf = make([]byte, payloadSize)
		} else {
			payloadBuf = payloadBuf[:payloadSize]
		}

		_, err = io.ReadFull(file, payloadBuf)
		if err != nil {
			return totalRecords, fmt.Errorf("erro ao ler payload: %w", err)
		}

		t := time.Unix(0, int64(timestamp)).UTC()
		record := Record{
			Timestamp:    int64(timestamp),
			TimestampRFC: t.Format(time.RFC3339),
			WorkerID:     int32(workerID),
			HealthScore:  int32(healthScore),
			Payload:      string(payloadBuf),
		}
		records = append(records, record)
		totalRecords++

		if len(records) >= e.batchSize {
			encoder := json.NewEncoder(outFile)
			for _, r := range records {
				if err := encoder.Encode(r); err != nil {
					return totalRecords, fmt.Errorf("erro ao escrever JSON: %w", err)
				}
			}
			records = records[:0]
		}
	}

	if len(records) > 0 {
		encoder := json.NewEncoder(outFile)
		for _, r := range records {
			if err := encoder.Encode(r); err != nil {
				return totalRecords, fmt.Errorf("erro ao escrever JSON final: %w", err)
			}
		}
	}

	return totalRecords, nil
}
