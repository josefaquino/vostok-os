package kyber

/*
#cgo CFLAGS: -I${SRCDIR} -std=c11 -O2
#cgo LDFLAGS: -L${SRCDIR}/lib -lkyber
#include "kyber_btree.h"
#include <stdlib.h>
*/
import "C"
import (
	"fmt"
	"sync"
	"unsafe"
)

// KyberDB é um wrapper thread-safe para a B-tree C
type KyberDB struct {
	handle *C.KyberBTree
	mu     sync.RWMutex
}

// NewKyberDB abre ou cria um banco KyberDB
func NewKyberDB(path string) (*KyberDB, error) {
	cPath := C.CString(path)
	defer C.free(unsafe.Pointer(cPath))

	var cfg C.KyberBTreeConfig
	cfg.use_wal = C.bool(true)

	handle := C.kyber_btree_open(cPath, &cfg)
	if handle == nil {
		return nil, fmt.Errorf("falha ao abrir KyberDB em %s", path)
	}

	return &KyberDB{handle: handle}, nil
}

// Close fecha o banco de dados
func (k *KyberDB) Close() error {
	k.mu.Lock()
	defer k.mu.Unlock()

	if k.handle != nil {
		C.kyber_btree_close(k.handle)
		k.handle = nil
	}
	return nil
}

// Put insere ou atualiza uma chave-valor
// CORREÇÃO: Usa C.CBytes() para copiar dados ao heap C (evita GC mover memória Go)
func (k *KyberDB) Put(key, value []byte) error {
	k.mu.Lock()
	defer k.mu.Unlock()

	if k.handle == nil {
		return fmt.Errorf("banco fechado")
	}
	if len(key) == 0 {
		return fmt.Errorf("chave vazia")
	}

	// C.CBytes() aloca memória no heap C e copia os dados
	cKey := C.CBytes(key)
	defer C.free(cKey)

	var cVal unsafe.Pointer
	if len(value) > 0 {
		cVal = C.CBytes(value)
		defer C.free(cVal)
	}

	result := C.kyber_btree_put(
		k.handle,
		cKey, C.size_t(len(key)),
		cVal, C.size_t(len(value)),
	)

	if !result {
		errMsg := C.GoString(C.kyber_btree_last_error())
		return fmt.Errorf("kyber_put falhou: %s", errMsg)
	}
	return nil
}

// Get recupera o valor associado a uma chave
func (k *KyberDB) Get(key []byte) ([]byte, error) {
	k.mu.RLock()
	defer k.mu.RUnlock()

	if k.handle == nil {
		return nil, fmt.Errorf("banco fechado")
	}
	if len(key) == 0 {
		return nil, fmt.Errorf("chave vazia")
	}

	cKey := C.CBytes(key)
	defer C.free(cKey)

	var cVal unsafe.Pointer
	var cValLen C.size_t

	result := C.kyber_btree_get(
		k.handle,
		cKey, C.size_t(len(key)),
		&cVal, &cValLen,
	)

	if !result {
		return nil, fmt.Errorf("chave não encontrada")
	}
	if cVal == nil {
		return nil, nil
	}

	// Copiar dados do C para Go
	val := C.GoBytes(cVal, C.int(cValLen))
	C.free(cVal)

	return val, nil
}

// Delete remove uma chave do banco
func (k *KyberDB) Delete(key []byte) error {
	k.mu.Lock()
	defer k.mu.Unlock()

	if k.handle == nil {
		return fmt.Errorf("banco fechado")
	}
	if len(key) == 0 {
		return fmt.Errorf("chave vazia")
	}

	cKey := C.CBytes(key)
	defer C.free(cKey)

	result := C.kyber_btree_delete(
		k.handle,
		cKey, C.size_t(len(key)),
	)

	if !result {
		return fmt.Errorf("chave não encontrada")
	}
	return nil
}

// Stats retorna estatísticas do banco
type Stats struct {
	NumKeys  uint64
	NumPages uint64
	Depth    uint64
	FileSize uint64
}

func (k *KyberDB) Stats() (*Stats, error) {
	k.mu.RLock()
	defer k.mu.RUnlock()

	if k.handle == nil {
		return nil, fmt.Errorf("banco fechado")
	}

	var cStats C.KyberBTreeStats
	result := C.kyber_btree_stats(k.handle, &cStats)
	if !result {
		return nil, fmt.Errorf("falha ao obter stats")
	}

	return &Stats{
		NumKeys:  uint64(cStats.num_keys),
		NumPages: uint64(cStats.num_pages),
		Depth:    uint64(cStats.depth),
		FileSize: uint64(cStats.file_size),
	}, nil
}
