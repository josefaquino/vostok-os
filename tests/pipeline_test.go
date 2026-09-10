package tests

import (
	"os"
	"testing"

	"vostok/pkg/pipeline"
	"vostok/pkg/queue"
)

func TestPipelineIntegration(t *testing.T) {
	bloomPath := "/tmp/test_pipeline_bloom.dat"
	storagePath := "/tmp/test_pipeline_storage.log"
	queuePath := "/tmp/test_pipeline_queue.db"

	// Limpar arquivos anteriores
	os.Remove(bloomPath)
	os.Remove(storagePath)
	os.Remove(queuePath)

	// Criar pipeline
	p, err := pipeline.NewPipeline(bloomPath, storagePath, queuePath)
	if err != nil {
		t.Fatalf("Failed to create pipeline: %v", err)
	}
	defer p.Close()
	defer os.Remove(bloomPath)
	defer os.Remove(storagePath)
	defer os.Remove(queuePath)

	// Dados de teste
	testData := []struct {
		payload string
	}{
		{"valid_data_1"},
		{"valid_data_2"},
		{"Rate Limit Exceeded"}, // Deve ser filtrado
		{"valid_data_3"},
	}

	// Ingest (passa pelo Gatekeeper)
	expectedIngested := 0
	for _, td := range testData {
		err := p.Ingest(1, []byte(td.payload))
		if err != nil {
			t.Fatalf("Ingest failed: %v", err)
		}
		// Se o payload não foi filtrado, conta
		if p.Storage.GatekeeperConverge([]byte(td.payload)) {
			expectedIngested++
		}
	}

	// Verificar fila
	count, err := p.Queue.Count(false)
	if err != nil {
		t.Fatalf("Failed to count queue: %v", err)
	}
	if count != int64(expectedIngested) {
		t.Errorf("Expected queue count %d, got %d", expectedIngested, count)
	}

	// Processar todos
	processed, err := p.ProcessAll()
	if err != nil {
		t.Fatalf("ProcessAll failed: %v", err)
	}
	if processed != expectedIngested {
		t.Errorf("Expected processed %d, got %d", expectedIngested, processed)
	}

	// Verificar persistência (YodaDB)
	if p.Storage.Ingested != uint64(expectedIngested) {
		t.Errorf("Expected storage ingested %d, got %d", expectedIngested, p.Storage.Ingested)
	}
}

func TestPipelineGatekeeper(t *testing.T) {
	bloomPath := "/tmp/test_gatekeeper_bloom.dat"
	storagePath := "/tmp/test_gatekeeper_storage.log"
	queuePath := "/tmp/test_gatekeeper_queue.db"

	os.Remove(bloomPath)
	os.Remove(storagePath)
	os.Remove(queuePath)

	p, err := pipeline.NewPipeline(bloomPath, storagePath, queuePath)
	if err != nil {
		t.Fatalf("Failed to create pipeline: %v", err)
	}
	defer p.Close()
	defer os.Remove(bloomPath)
	defer os.Remove(storagePath)
	defer os.Remove(queuePath)

	// Testar com dados que devem ser filtrados
	filteredData := []string{
		"Rate Limit Exceeded",
		"404 Not Found",
		"403 Forbidden",
		"short", // len < 10
	}

	for _, data := range filteredData {
		err := p.Ingest(1, []byte(data))
		if err != nil {
			t.Fatalf("Ingest failed: %v", err)
		}
	}

	// Verificar que a fila está vazia (todos foram filtrados)
	count, err := p.Queue.Count(false)
	if err != nil {
		t.Fatalf("Failed to count queue: %v", err)
	}
	if count != 0 {
		t.Errorf("Expected queue count 0, got %d", count)
	}

	// Verificar que o YodaDB não tem registros
	if p.Storage.Ingested != 0 {
		t.Errorf("Expected storage ingested 0, got %d", p.Storage.Ingested)
	}
}

func TestPipelinePriority(t *testing.T) {
	bloomPath := "/tmp/test_priority_bloom.dat"
	storagePath := "/tmp/test_priority_storage.log"
	queuePath := "/tmp/test_priority_queue.db"

	os.Remove(bloomPath)
	os.Remove(storagePath)
	os.Remove(queuePath)

	p, err := pipeline.NewPipeline(bloomPath, storagePath, queuePath)
	if err != nil {
		t.Fatalf("Failed to create pipeline: %v", err)
	}
	defer p.Close()
	defer os.Remove(bloomPath)
	defer os.Remove(storagePath)
	defer os.Remove(queuePath)

	// Enfileirar diretamente com prioridades diferentes
	highData := []byte("high priority")
	mediumData := []byte("medium priority")
	lowData := []byte("low priority")

	// Inserir prioridades fora de ordem
	p.Queue.Enqueue(queue.PriorityLow, lowData)
	p.Queue.Enqueue(queue.PriorityHigh, highData)
	p.Queue.Enqueue(queue.PriorityMedium, mediumData)

	// Processar em ordem
	items := []string{}

	// Processar manualmente para ver ordem
	for i := 0; i < 3; i++ {
		item, err := p.Queue.Dequeue()
		if err != nil {
			t.Fatalf("Dequeue failed: %v", err)
		}
		if item == nil {
			break
		}
		items = append(items, string(item.Data))
	}

	// Verificar ordem: High, Medium, Low
	expectedOrder := []string{"high priority", "medium priority", "low priority"}
	for i, expected := range expectedOrder {
		if i >= len(items) {
			t.Errorf("Expected item %d, but got none", i)
		} else if items[i] != expected {
			t.Errorf("Expected order[%d]=%s, got %s", i, expected, items[i])
		}
	}
}
