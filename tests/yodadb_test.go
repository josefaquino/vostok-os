package tests

import (
	"bytes"
	"io"
	"os"
	"sync"
	"testing"
	"time"

	"vostok/pkg/db"
)

func TestBloomFilterBasic(t *testing.T) {
	bloomPath := "/tmp/test_bloom.dat"
	storagePath := "/tmp/test_storage.log"

	yodadb, err := db.NewYodaDB(bloomPath, storagePath)
	if err != nil {
		t.Fatalf("Failed to create DB: %v", err)
	}
	defer yodadb.Close()
	defer os.Remove(bloomPath)
	defer os.Remove(storagePath)

	payload := []byte("test_data_001")
	exists := yodadb.CheckAndAdd(payload)
	if exists {
		t.Error("Expected false for new key")
	}

	exists = yodadb.CheckAndAdd(payload)
	if !exists {
		t.Error("Expected true for existing key")
	}
}

func TestBloomFilterUnique(t *testing.T) {
	bloomPath := "/tmp/test_bloom.dat"
	storagePath := "/tmp/test_storage.log"

	yodadb, err := db.NewYodaDB(bloomPath, storagePath)
	if err != nil {
		t.Fatalf("Failed to create DB: %v", err)
	}
	defer yodadb.Close()
	defer os.Remove(bloomPath)
	defer os.Remove(storagePath)

	seen := make(map[string]bool)
	for i := 0; i < 1000; i++ {
		payload := []byte("key_" + string(rune(i)))
		exists := yodadb.CheckAndAdd(payload)
		if exists && !seen[string(payload)] {
			t.Errorf("False positive detected for key_%d", i)
		}
		seen[string(payload)] = true
	}
}

func TestBloomFilterPersistence(t *testing.T) {
	bloomPath := "/tmp/test_bloom.dat"
	storagePath := "/tmp/test_storage.log"

	yodadb1, err := db.NewYodaDB(bloomPath, storagePath)
	if err != nil {
		t.Fatalf("Failed to create first DB: %v", err)
	}
	payload := []byte("persistent_key")
	yodadb1.CheckAndAdd(payload)
	yodadb1.Close()

	yodadb2, err := db.NewYodaDB(bloomPath, storagePath)
	if err != nil {
		t.Fatalf("Failed to create second DB: %v", err)
	}
	defer yodadb2.Close()
	defer os.Remove(bloomPath)
	defer os.Remove(storagePath)

	exists := yodadb2.CheckAndAdd(payload)
	if !exists {
		t.Error("Bloom filter did not persist state")
	}
}

func TestGatekeeperFiltersErrors(t *testing.T) {
	yodadb, err := db.NewYodaDB("/tmp/test_bloom.dat", "/tmp/test_storage.log")
	if err != nil {
		t.Fatalf("Failed to create DB: %v", err)
	}
	defer yodadb.Close()
	defer os.Remove("/tmp/test_bloom.dat")
	defer os.Remove("/tmp/test_storage.log")

	tests := []struct {
		name     string
		payload  []byte
		expected bool
	}{
		{"Valid", []byte("valid data"), true},
		{"Rate Limit", []byte("Rate Limit Exceeded"), false},
		{"404", []byte("404 Not Found"), false},
		{"403", []byte("403 Forbidden"), false},
		{"Too short", []byte("short"), false},
		{"Valid with noise", []byte("valid data with rate limit mention"), true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := yodadb.GatekeeperConverge(tt.payload)
			if result != tt.expected {
				t.Errorf("GatekeeperConverge(%q) = %v, expected %v", tt.payload, result, tt.expected)
			}
		})
	}
}

func TestWriteRecord(t *testing.T) {
	bloomPath := "/tmp/test_bloom.dat"
	storagePath := "/tmp/test_storage.log"

	yodadb, err := db.NewYodaDB(bloomPath, storagePath)
	if err != nil {
		t.Fatalf("Failed to create DB: %v", err)
	}
	defer yodadb.Close()
	defer os.Remove(bloomPath)
	defer os.Remove(storagePath)

	payload := []byte("test_payload")
	err = yodadb.WriteRecord(1, 100, payload)
	if err != nil {
		t.Fatalf("WriteRecord failed: %v", err)
	}

	if yodadb.Ingested != 1 {
		t.Errorf("Expected Ingested=1, got %d", yodadb.Ingested)
	}
}

func TestConcurrentWrites(t *testing.T) {
	bloomPath := "/tmp/test_bloom.dat"
	storagePath := "/tmp/test_storage.log"

	yodadb, err := db.NewYodaDB(bloomPath, storagePath)
	if err != nil {
		t.Fatalf("Failed to create DB: %v", err)
	}
	defer yodadb.Close()
	defer os.Remove(bloomPath)
	defer os.Remove(storagePath)

	var wg sync.WaitGroup
	numWrites := 100

	for i := 0; i < numWrites; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			payload := []byte("concurrent_data_" + string(rune(id)))
			err := yodadb.WriteRecord(uint32(id), 100, payload)
			if err != nil {
				t.Errorf("Write failed for %d: %v", id, err)
			}
		}(i)
	}
	wg.Wait()

	if yodadb.Ingested != uint64(numWrites) {
		t.Errorf("Expected Ingested=%d, got %d", numWrites, yodadb.Ingested)
	}
}

func TestConcurrentBloomAccess(t *testing.T) {
	bloomPath := "/tmp/test_bloom.dat"
	storagePath := "/tmp/test_storage.log"

	yodadb, err := db.NewYodaDB(bloomPath, storagePath)
	if err != nil {
		t.Fatalf("Failed to create DB: %v", err)
	}
	defer yodadb.Close()
	defer os.Remove(bloomPath)
	defer os.Remove(storagePath)

	var wg sync.WaitGroup
	numOps := 1000

	for i := 0; i < numOps; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			payload := []byte("bloom_key_" + string(rune(id)))
			yodadb.CheckAndAdd(payload)
		}(i)
	}
	wg.Wait()

	for i := 0; i < numOps; i++ {
		payload := []byte("bloom_key_" + string(rune(i)))
		yodadb.CheckAndAdd(payload)
	}
}

func TestStreamData(t *testing.T) {
	bloomPath := "/tmp/test_bloom.dat"
	storagePath := "/tmp/test_storage.log"

	yodadb, err := db.NewYodaDB(bloomPath, storagePath)
	if err != nil {
		t.Fatalf("Failed to create DB: %v", err)
	}

	testData := []struct {
		workerID uint32
		health   uint8
		payload  string
	}{
		{1, 100, "healthy_data_1"},
		{2, 80, "healthy_data_2"},
		{3, 50, "medium_data"},
		{4, 20, "low_data"},
		{5, 0, "zero_data"},
	}

	for _, td := range testData {
		err := yodadb.WriteRecord(td.workerID, td.health, []byte(td.payload))
		if err != nil {
			t.Fatalf("WriteRecord failed: %v", err)
		}
	}
	yodadb.Close()

	oldStdout := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w

	db.StreamData(storagePath, 80)

	w.Close()
	os.Stdout = oldStdout

	var buf bytes.Buffer
	io.Copy(&buf, r)
	output := buf.String()

	if !bytes.Contains([]byte(output), []byte("healthy_data_1")) {
		t.Error("healthy_data_1 not found in stream")
	}
	if !bytes.Contains([]byte(output), []byte("healthy_data_2")) {
		t.Error("healthy_data_2 not found in stream")
	}
	if bytes.Contains([]byte(output), []byte("medium_data")) {
		t.Error("medium_data should not appear (health=50 < 80)")
	}
	if bytes.Contains([]byte(output), []byte("low_data")) {
		t.Error("low_data should not appear (health=20 < 80)")
	}
	if bytes.Contains([]byte(output), []byte("zero_data")) {
		t.Error("zero_data should not appear (health=0 < 80)")
	}

	os.Remove(bloomPath)
	os.Remove(storagePath)
}

func TestRollbackTo(t *testing.T) {
	bloomPath := "/tmp/test_bloom.dat"
	storagePath := "/tmp/test_storage.log"

	yodadb, err := db.NewYodaDB(bloomPath, storagePath)
	if err != nil {
		t.Fatalf("Failed to create DB: %v", err)
	}

	now := uint64(time.Now().UnixNano())
	data := []struct {
		payload string
	}{
		{"record_1"},
		{"record_2"},
		{"record_3"},
	}

	for _, d := range data {
		yodadb.WriteRecord(1, 100, []byte(d.payload))
	}
	yodadb.Close()

	targetTimestamp := now + uint64(1*time.Second)
	db.RollbackTo(storagePath, targetTimestamp)

	stat, err := os.Stat(storagePath)
	if err != nil {
		t.Fatalf("Failed to stat storage: %v", err)
	}
	if stat.Size() == 0 {
		t.Error("Storage file should not be empty after rollback")
	}

	os.Remove(bloomPath)
	os.Remove(storagePath)
}
