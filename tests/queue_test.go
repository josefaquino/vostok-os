package tests

import (
	"math"
	"os"
	"testing"

	"vostok/pkg/queue"
)

func TestQueueEnqueueDequeue(t *testing.T) {
	dbPath := "/tmp/test_queue.db"
	os.Remove(dbPath) // Clean start

	q, err := queue.NewQueueDB(dbPath)
	if err != nil {
		t.Fatalf("Failed to create queue: %v", err)
	}
	defer q.Close()
	defer os.Remove(dbPath)

	data1 := []byte("low priority")
	data2 := []byte("medium priority")
	data3 := []byte("high priority")

	id1, err := q.Enqueue(queue.PriorityLow, data1)
	if err != nil {
		t.Fatalf("Failed to enqueue low: %v", err)
	}
	id2, err := q.Enqueue(queue.PriorityMedium, data2)
	if err != nil {
		t.Fatalf("Failed to enqueue medium: %v", err)
	}
	id3, err := q.Enqueue(queue.PriorityHigh, data3)
	if err != nil {
		t.Fatalf("Failed to enqueue high: %v", err)
	}

	item, err := q.Dequeue()
	if err != nil {
		t.Fatalf("Failed to dequeue: %v", err)
	}
	if item.ID != id3 {
		t.Errorf("Expected id %d, got %d", id3, item.ID)
	}
	if string(item.Data) != "high priority" {
		t.Errorf("Expected 'high priority', got '%s'", string(item.Data))
	}

	item, err = q.Dequeue()
	if err != nil {
		t.Fatalf("Failed to dequeue: %v", err)
	}
	if item.ID != id2 {
		t.Errorf("Expected id %d, got %d", id2, item.ID)
	}

	item, err = q.Dequeue()
	if err != nil {
		t.Fatalf("Failed to dequeue: %v", err)
	}
	if item.ID != id1 {
		t.Errorf("Expected id %d, got %d", id1, item.ID)
	}
}

func TestTokenBucket(t *testing.T) {
	tb := queue.NewTokenBucket(10, 5)

	available := tb.Available()
	if math.Abs(available-10) > 0.001 {
		t.Errorf("Expected 10 available, got %f", available)
	}

	if !tb.Take(5) {
		t.Error("Should be able to take 5 tokens")
	}

	available = tb.Available()
	if math.Abs(available-5) > 0.001 {
		t.Errorf("Expected 5 available, got %f", available)
	}

	if !tb.Take(5) {
		t.Error("Should be able to take 5 more tokens")
	}

	available = tb.Available()
	if math.Abs(available-0) > 0.001 {
		t.Errorf("Expected 0 available, got %f", available)
	}
}

func TestQueueManagerRateLimiting(t *testing.T) {
	dbPath := "/tmp/test_queue_manager.db"
	os.Remove(dbPath) // Clean start

	qm, err := queue.NewQueueManager(dbPath)
	if err != nil {
		t.Fatalf("Failed to create queue manager: %v", err)
	}
	defer qm.Close()
	defer os.Remove(dbPath)

	// Enqueue 10 high priority items
	for i := 0; i < 10; i++ {
		_, err := qm.Enqueue(queue.PriorityHigh, []byte("test"))
		if err != nil {
			t.Fatalf("Failed to enqueue: %v", err)
		}
	}

	// Count unprocessed items (should be 10)
	count, err := qm.Count(false)
	if err != nil {
		t.Fatalf("Failed to count: %v", err)
	}
	if count != 10 {
		t.Errorf("Expected 10 unprocessed items, got %d", count)
	}

	// Dequeue 5 items (rate limiting should work)
	for i := 0; i < 5; i++ {
		item, err := qm.Dequeue()
		if err != nil {
			t.Fatalf("Failed to dequeue: %v", err)
		}
		if item == nil {
			t.Error("Expected item, got nil")
		}
	}

	// Remaining unprocessed should be 5
	count, err = qm.Count(false)
	if err != nil {
		t.Fatalf("Failed to count: %v", err)
	}
	if count != 5 {
		t.Errorf("Expected 5 remaining items, got %d", count)
	}
}
