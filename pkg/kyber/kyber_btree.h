#ifndef KYBER_BTREE_H
#define KYBER_BTREE_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#define KYBER_BTREE_MAGIC       0x4B594252u
#define KYBER_BTREE_VERSION     1
#define KYBER_BTREE_PAGE_SIZE   4096

typedef struct KyberBTree KyberBTree;
typedef struct KyberBTreeIter KyberBTreeIter;

typedef struct {
    uint32_t page_size;
    uint32_t fill_factor;
    bool     use_wal;
    bool     read_only;   /* se true: nao faz replay/checkpoint */
    uint32_t wal_sync_interval;
} KyberBTreeConfig;

typedef struct {
    uint64_t num_keys;
    uint64_t num_pages;
    uint64_t depth;
    uint64_t file_size;
} KyberBTreeStats;

/* Ciclo de vida */
KyberBTree* kyber_btree_open(const char *path, const KyberBTreeConfig *cfg);
void        kyber_btree_close(KyberBTree *t);

/* Operações */
bool kyber_btree_put(KyberBTree *t, const void *key, size_t klen,
                     const void *val, size_t vlen);
bool kyber_btree_get(KyberBTree *t, const void *key, size_t klen,
                     void **val, size_t *vlen);
bool kyber_btree_delete(KyberBTree *t, const void *key, size_t klen);

/* Transações (stubs no momento) */
bool kyber_btree_begin(KyberBTree *t);
bool kyber_btree_commit(KyberBTree *t);
void kyber_btree_abort(KyberBTree *t);

/* Stats e erro */
bool        kyber_btree_stats(KyberBTree *t, KyberBTreeStats *out);
const char* kyber_btree_last_error(void);

/* Iterador (em ordem de chave) */
KyberBTreeIter* kyber_btree_iter_open(KyberBTree *t);
bool kyber_btree_iter_next(KyberBTreeIter *it,
                           const void **key, size_t *klen,
                           const void **val, size_t *vlen);
void kyber_btree_iter_close(KyberBTreeIter *it);

#endif
