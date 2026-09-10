#ifndef WAL_H
#define WAL_H

#include <stddef.h>
#include <stdint.h>

#define WAL_OP_PUT    0x01
#define WAL_OP_DELETE 0x02

typedef struct WAL WAL;

WAL* wal_open(const char *path);
void wal_close(WAL *w);

int wal_append_put(WAL *w, const void *key, size_t key_len,
                   const void *value, size_t value_len);
int wal_append_delete(WAL *w, const void *key, size_t key_len);

typedef int (*wal_replay_callback)(int op, const void *key, size_t key_len,
                                   const void *value, size_t value_len, void *user);

int wal_replay(WAL *w, wal_replay_callback cb, void *user);
int wal_checkpoint(WAL *w);
uint64_t wal_pending_count(WAL *w);

#endif /* WAL_H */
