package kyber

import (
	"os"
	"testing"
)

func TestKyberDB(t *testing.T) {
	// Criar diretório de teste
	testDir := "/tmp/kyber_test"
	if err := os.MkdirAll(testDir, 0755); err != nil {
		t.Fatalf("Failed to create test dir: %v", err)
	}
	defer os.RemoveAll(testDir)

	db, err := NewKyberDB(testDir)
	if err != nil {
		t.Fatalf("Failed to open KyberDB: %v", err)
	}
	defer db.Close()

	key := []byte("test_key")
	value := []byte("test_value")

	if err := db.Put(key, value); err != nil {
		t.Fatalf("Put failed: %v", err)
	}

	got, err := db.Get(key)
	if err != nil {
		t.Fatalf("Get failed: %v", err)
	}
	if string(got) != string(value) {
		t.Errorf("Expected %s, got %s", value, got)
	}

	if err := db.Delete(key); err != nil {
		t.Fatalf("Delete failed: %v", err)
	}
}
