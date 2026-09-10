package pipeline

import (
	"vostok/pkg/db"
	"vostok/pkg/queue"
)

// Pipeline integra o YodaDB (persistência) com o VostokDB (fila)
type Pipeline struct {
	Storage *db.YodaDB   // Exportado para testes
	Queue   *queue.QueueManager // Exportado para testes
}

// NewPipeline cria um novo pipeline com os componentes
func NewPipeline(bloomPath, storagePath, queuePath string) (*Pipeline, error) {
	// Inicializa o YodaDB
	storage, err := db.NewYodaDB(bloomPath, storagePath)
	if err != nil {
		return nil, err
	}

	// Inicializa o QueueManager
	qm, err := queue.NewQueueManager(queuePath)
	if err != nil {
		storage.Close()
		return nil, err
	}

	return &Pipeline{
		Storage: storage,
		Queue:   qm,
	}, nil
}

// Close fecha todos os componentes
func (p *Pipeline) Close() error {
	if p.Storage != nil {
		p.Storage.Close()
	}
	if p.Queue != nil {
		return p.Queue.Close()
	}
	return nil
}

// Ingest enfileira um item para processamento
// O item passará pelo Gatekeeper antes de ser persistido
func (p *Pipeline) Ingest(workerID uint32, data []byte) error {
	// Aplica o Gatekeeper (filtro semântico)
	if !p.Storage.GatekeeperConverge(data) {
		// Dado descartado (não enfileira)
		return nil
	}

	// Enfileira com prioridade média (padrão)
	_, err := p.Queue.Enqueue(queue.PriorityMedium, data)
	return err
}

// ProcessNext consome o próximo item da fila e persiste no YodaDB
func (p *Pipeline) ProcessNext() error {
	item, err := p.Queue.Dequeue()
	if err != nil {
		return err
	}
	if item == nil {
		return nil // Fila vazia
	}

	// Persiste no YodaDB
	return p.Storage.WriteRecord(1, 100, item.Data)
}

// ProcessAll processa todos os itens da fila até esvaziar
func (p *Pipeline) ProcessAll() (int, error) {
	count := 0
	for {
		item, err := p.Queue.Dequeue()
		if err != nil {
			return count, err
		}
		if item == nil {
			break
		}
		if err := p.Storage.WriteRecord(1, 100, item.Data); err != nil {
			return count, err
		}
		count++
	}
	return count, nil
}
