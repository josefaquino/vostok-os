package metrics

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	// IngestedRecords total de registros salvos
	IngestedRecords = promauto.NewCounter(prometheus.CounterOpts{
		Name: "yodadb_ingested_records_total",
		Help: "Total number of records successfully ingested",
	})

	// SkippedRecords total de registros descartados (Bloom Filter)
	SkippedRecords = promauto.NewCounter(prometheus.CounterOpts{
		Name: "yodadb_skipped_records_total",
		Help: "Total number of records skipped by Bloom Filter",
	})

	// QueueDepth profundidade atual da fila SQLite
	QueueDepth = promauto.NewGauge(prometheus.GaugeOpts{
		Name: "vostok_queue_depth",
		Help: "Current depth of the VostokDB queue",
	})

	// QueueLatency latência de operações na fila
	QueueLatency = promauto.NewHistogram(prometheus.HistogramOpts{
		Name:    "vostok_queue_latency_seconds",
		Help:    "Latency of queue operations",
		Buckets: []float64{.001, .005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5, 10},
	})

	// TokenBucketAvailable tokens disponíveis no rate limiter
	TokenBucketAvailable = promauto.NewGauge(prometheus.GaugeOpts{
		Name: "token_bucket_tokens_available",
		Help: "Available tokens in the rate limiter",
	})

	// RecordSize tamanho dos registros
	RecordSize = promauto.NewHistogram(prometheus.HistogramOpts{
		Name:    "yodadb_record_size_bytes",
		Help:    "Size of ingested records in bytes",
		Buckets: []float64{64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536},
	})
)
