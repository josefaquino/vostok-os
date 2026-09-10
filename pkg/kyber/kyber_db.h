#ifndef KYBER_DB_H
#define KYBER_DB_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct kyber_db kyber_db_t;

kyber_db_t* kyber_open(const char* path);
void kyber_close(kyber_db_t* db);
int kyber_put(kyber_db_t* db, const void* key, size_t key_len,
              const void* value, size_t value_len);
void* kyber_get(kyber_db_t* db, const void* key, size_t key_len,
                size_t* value_len);
int kyber_delete(kyber_db_t* db, const void* key, size_t key_len);
int kyber_exists(kyber_db_t* db, const void* key, size_t key_len);

#ifdef __cplusplus
}
#endif

#endif // KYBER_DB_H
