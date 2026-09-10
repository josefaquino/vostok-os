package queue

import (
	"database/sql"
	"fmt"
	"sync"
	"time"

	_ "modernc.org/sqlite"
)

// Priority levels for the queue
type Priority int

const (
	PriorityLow Priority = iota
	PriorityMedium
	PriorityHigh
)

func (p Priority) String() string {
	switch p {
	case PriorityLow:
		return "low"
	case PriorityMedium:
		return "medium"
	case PriorityHigh:
		return "high"
	default:
		return "unknown"
	}
}

type QueueItem struct {
	ID         int64
	Priority   Priority
	Data       []byte
	CreatedAt  time.Time
	Processed  bool
	Retries    int
	MaxRetries int
}

type QueueDB struct {
	db     *sql.DB
	mu     sync.RWMutex
	path   string
}

func NewQueueDB(path string) (*QueueDB, error) {
	db, err := sql.Open("sqlite", path+"?_journal=WAL&_sync=NORMAL")
	if err != nil {
		return nil, fmt.Errorf("failed to open SQLite: %w", err)
	}

	// Enable WAL mode
	if _, err := db.Exec("PRAGMA journal_mode=WAL"); err != nil {
		return nil, fmt.Errorf("failed to enable WAL: %w", err)
	}

	// Create schema
	schema := `
	CREATE TABLE IF NOT EXISTS queue (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		priority INTEGER NOT NULL,
		data BLOB NOT NULL,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		processed BOOLEAN DEFAULT 0,
		retries INTEGER DEFAULT 0,
		max_retries INTEGER DEFAULT 3,
		processed_at DATETIME
	);

	CREATE INDEX IF NOT EXISTS idx_queue_priority ON queue(priority, created_at);
	CREATE INDEX IF NOT EXISTS idx_queue_processed ON queue(processed);
	`

	if _, err := db.Exec(schema); err != nil {
		return nil, fmt.Errorf("failed to create schema: %w", err)
	}

	return &QueueDB{
		db:   db,
		path: path,
	}, nil
}

func (q *QueueDB) Close() error {
	return q.db.Close()
}

// Enqueue adds an item to the queue with the given priority
func (q *QueueDB) Enqueue(priority Priority, data []byte) (int64, error) {
	q.mu.Lock()
	defer q.mu.Unlock()

	result, err := q.db.Exec(
		"INSERT INTO queue (priority, data) VALUES (?, ?)",
		int(priority), data,
	)
	if err != nil {
		return 0, fmt.Errorf("failed to enqueue: %w", err)
	}

	return result.LastInsertId()
}

// Dequeue gets the highest priority item from the queue
func (q *QueueDB) Dequeue() (*QueueItem, error) {
	q.mu.Lock()
	defer q.mu.Unlock()

	tx, err := q.db.Begin()
	if err != nil {
		return nil, fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Get highest priority unprocessed item
	var item QueueItem
	err = tx.QueryRow(`
		SELECT id, priority, data, created_at, retries, max_retries
		FROM queue
		WHERE processed = 0
		ORDER BY priority DESC, created_at ASC
		LIMIT 1
	`).Scan(&item.ID, &item.Priority, &item.Data, &item.CreatedAt, &item.Retries, &item.MaxRetries)

	if err == sql.ErrNoRows {
		return nil, nil // No items
	}
	if err != nil {
		return nil, fmt.Errorf("failed to dequeue: %w", err)
	}

	// Mark as processed
	_, err = tx.Exec(
		"UPDATE queue SET processed = 1, processed_at = CURRENT_TIMESTAMP WHERE id = ?",
		item.ID,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to mark processed: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("failed to commit: %w", err)
	}

	item.Processed = true
	return &item, nil
}

// Peek returns the highest priority item without removing it
func (q *QueueDB) Peek() (*QueueItem, error) {
	q.mu.RLock()
	defer q.mu.RUnlock()

	var item QueueItem
	err := q.db.QueryRow(`
		SELECT id, priority, data, created_at, retries, max_retries
		FROM queue
		WHERE processed = 0
		ORDER BY priority DESC, created_at ASC
		LIMIT 1
	`).Scan(&item.ID, &item.Priority, &item.Data, &item.CreatedAt, &item.Retries, &item.MaxRetries)

	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("failed to peek: %w", err)
	}

	return &item, nil
}

// Count returns the number of items in the queue
func (q *QueueDB) Count(processed bool) (int64, error) {
	q.mu.RLock()
	defer q.mu.RUnlock()

	var count int64
	err := q.db.QueryRow(
		"SELECT COUNT(*) FROM queue WHERE processed = ?",
		processed,
	).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to count: %w", err)
	}
	return count, nil
}

// Retry increments retry count for an item
func (q *QueueDB) Retry(id int64) error {
	q.mu.Lock()
	defer q.mu.Unlock()

	result, err := q.db.Exec(
		"UPDATE queue SET retries = retries + 1, processed = 0 WHERE id = ? AND retries < max_retries",
		id,
	)
	if err != nil {
		return fmt.Errorf("failed to retry: %w", err)
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("item %d not found or max retries exceeded", id)
	}
	return nil
}
