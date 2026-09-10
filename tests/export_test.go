package tests

import (
	"os"
	"testing"

	"vostok/pkg/db"
	"vostok/pkg/export"
)

func TestCSVExport(t *testing.T) {
	bloomPath := "/tmp/test_export_bloom.dat"
	storagePath := "/tmp/test_export_storage.log"
	csvPath := "/tmp/test_export.csv"

	os.Remove(bloomPath)
	os.Remove(storagePath)
	os.Remove(csvPath)

	yodadb, err := db.NewYodaDB(bloomPath, storagePath)
	if err != nil {
		t.Fatalf("Failed to create DB: %v", err)
	}

	for i := 0; i < 10; i++ {
		if err := yodadb.WriteRecord(uint32(i), uint8(i%100), []byte("test_data")); err != nil {
			t.Fatalf("WriteRecord failed: %v", err)
		}
	}
	yodadb.Close()

	exporter := export.NewExporter(storagePath)
	count, err := exporter.ExportCSV(csvPath, 0)
	if err != nil {
		t.Fatalf("ExportCSV failed: %v", err)
	}
	if count != 10 {
		t.Errorf("Expected 10 records, got %d", count)
	}

	stat, err := os.Stat(csvPath)
	if err != nil {
		t.Fatalf("CSV file not created: %v", err)
	}
	if stat.Size() == 0 {
		t.Error("CSV file is empty")
	}

	os.Remove(bloomPath)
	os.Remove(storagePath)
	os.Remove(csvPath)
}

func TestJSONExport(t *testing.T) {
	bloomPath := "/tmp/test_export_bloom.dat"
	storagePath := "/tmp/test_export_storage.log"
	jsonPath := "/tmp/test_export.json"

	os.Remove(bloomPath)
	os.Remove(storagePath)
	os.Remove(jsonPath)

	yodadb, err := db.NewYodaDB(bloomPath, storagePath)
	if err != nil {
		t.Fatalf("Failed to create DB: %v", err)
	}

	for i := 0; i < 10; i++ {
		if err := yodadb.WriteRecord(uint32(i), uint8(i%100), []byte("test_data")); err != nil {
			t.Fatalf("WriteRecord failed: %v", err)
		}
	}
	yodadb.Close()

	exporter := export.NewExporter(storagePath)
	count, err := exporter.ExportJSON(jsonPath, 0)
	if err != nil {
		t.Fatalf("ExportJSON failed: %v", err)
	}
	if count != 10 {
		t.Errorf("Expected 10 records, got %d", count)
	}

	stat, err := os.Stat(jsonPath)
	if err != nil {
		t.Fatalf("JSON file not created: %v", err)
	}
	if stat.Size() == 0 {
		t.Error("JSON file is empty")
	}

	os.Remove(bloomPath)
	os.Remove(storagePath)
	os.Remove(jsonPath)
}
