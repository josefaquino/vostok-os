package queue

import (
	"sync"
)

type QueueManager struct {
	db           *QueueDB
	highBucket   *TokenBucket
	mediumBucket *TokenBucket
	lowBucket    *TokenBucket
	mu           sync.RWMutex
}

func NewQueueManager(dbPath string) (*QueueManager, error) {
	db, err := NewQueueDB(dbPath)
	if err != nil {
		return nil, err
	}

	return &QueueManager{
		db:           db,
		highBucket:   NewTokenBucket(100, 10),   // 10 req/s
		mediumBucket: NewTokenBucket(50, 5),     // 5 req/s
		lowBucket:    NewTokenBucket(10, 1),     // 1 req/s
	}, nil
}

func (qm *QueueManager) Close() error {
	return qm.db.Close()
}

func (qm *QueueManager) Enqueue(priority Priority, data []byte) (int64, error) {
	return qm.db.Enqueue(priority, data)
}

func (qm *QueueManager) Dequeue() (*QueueItem, error) {
	item, err := qm.db.Dequeue()
	if err != nil {
		return nil, err
	}
	if item == nil {
		return nil, nil
	}

	// Apply rate limiting based on priority
	var bucket *TokenBucket
	switch item.Priority {
	case PriorityHigh:
		bucket = qm.highBucket
	case PriorityMedium:
		bucket = qm.mediumBucket
	case PriorityLow:
		bucket = qm.lowBucket
	default:
		bucket = qm.lowBucket
	}

	// Wait for token availability
	bucket.Wait(1.0)

	return item, nil
}

func (qm *QueueManager) Peek() (*QueueItem, error) {
	return qm.db.Peek()
}

func (qm *QueueManager) Count(processed bool) (int64, error) {
	return qm.db.Count(processed)
}

func (qm *QueueManager) Retry(id int64) error {
	return qm.db.Retry(id)
}

func (qm *QueueManager) AvailableTokens(priority Priority) float64 {
	switch priority {
	case PriorityHigh:
		return qm.highBucket.Available()
	case PriorityMedium:
		return qm.mediumBucket.Available()
	case PriorityLow:
		return qm.lowBucket.Available()
	default:
		return qm.lowBucket.Available()
	}
}
