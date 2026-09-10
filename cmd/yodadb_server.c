#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
#include <poll.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <time.h>

#include "kyber_btree.h"

#define YODA_SOCKET_PATH "/tmp/yodadb.sock"
#define YODA_PID_PATH "/tmp/yodadb-server.pid"
#define YODA_LOCK_PATH "yoda_storage.log.server.lock"

#define MAGIC_BYTE 0xAA
#define HEADER_SIZE 21
#define MAX_MSG (8 * 1024 * 1024)

typedef struct {
    int storage_fd;
    int lock_fd;
    int64_t current_offset;
    KyberBTree *kyber;
} ServerDB;

static volatile sig_atomic_t running = 1;

static void handle_signal(int sig) {
    (void)sig;
    running = 0;
}

static void log_msg(const char *msg) {
    time_t t = time(NULL);
    struct tm tm;
    localtime_r(&t, &tm);
    char buf[64];
    strftime(buf, sizeof buf, "%H:%M:%S", &tm);
    fprintf(stderr, "[%s] %s\n", buf, msg);
}

static void write_u32_be(uint8_t *p, uint32_t v) {
    p[0] = (uint8_t)(v >> 24);
    p[1] = (uint8_t)(v >> 16);
    p[2] = (uint8_t)(v >> 8);
    p[3] = (uint8_t)(v);
}

static void write_u64_be(uint8_t *p, uint64_t v) {
    p[0] = (uint8_t)(v >> 56);
    p[1] = (uint8_t)(v >> 48);
    p[2] = (uint8_t)(v >> 40);
    p[3] = (uint8_t)(v >> 32);
    p[4] = (uint8_t)(v >> 24);
    p[5] = (uint8_t)(v >> 16);
    p[6] = (uint8_t)(v >> 8);
    p[7] = (uint8_t)(v);
}

static int server_open(ServerDB *db, const char *storage_path, const char *kyber_path) {
    db->lock_fd = open(YODA_LOCK_PATH, O_RDWR | O_CREAT, 0644);
    if (db->lock_fd < 0) return -1;

    if (flock(db->lock_fd, LOCK_EX | LOCK_NB) != 0) {
        close(db->lock_fd);
        db->lock_fd = -1;
        return -2;
    }

    db->storage_fd = open(storage_path, O_RDWR | O_CREAT, 0644);
    if (db->storage_fd < 0) {
        flock(db->lock_fd, LOCK_UN);
        close(db->lock_fd);
        db->lock_fd = -1;
        return -1;
    }

    db->current_offset = lseek(db->storage_fd, 0, SEEK_END);

    KyberBTreeConfig cfg = {
        .use_wal = true,
        .read_only = false
    };

    db->kyber = kyber_btree_open(kyber_path, &cfg);
    if (!db->kyber) {
        close(db->storage_fd);
        flock(db->lock_fd, LOCK_UN);
        close(db->lock_fd);
        db->lock_fd = -1;
        db->storage_fd = -1;
        return -1;
    }

    return 0;
}

static void server_close(ServerDB *db) {
    if (!db) return;

    if (db->kyber) {
        kyber_btree_close(db->kyber);
        db->kyber = NULL;
    }

    if (db->storage_fd >= 0) {
        fsync(db->storage_fd);
        close(db->storage_fd);
        db->storage_fd = -1;
    }

    if (db->lock_fd >= 0) {
        flock(db->lock_fd, LOCK_UN);
        close(db->lock_fd);
        db->lock_fd = -1;
    }
}

static int server_put(ServerDB *db, uint32_t worker_id, uint32_t biome_id,
                      const uint8_t *payload, size_t plen) {
    uint8_t header[HEADER_SIZE];

    header[0] = MAGIC_BYTE;
    write_u32_be(header + 1, (uint32_t)time(NULL));
    write_u32_be(header + 5, worker_id);
    write_u32_be(header + 9, biome_id);
    write_u64_be(header + 13, (uint64_t)plen);

    if (write(db->storage_fd, header, HEADER_SIZE) != HEADER_SIZE) return -1;
    if (write(db->storage_fd, payload, plen) != (ssize_t)plen) return -1;

    int64_t rec_off = db->current_offset;
    db->current_offset += HEADER_SIZE + (int64_t)plen;

    const uint8_t *tab = memchr(payload, '\t', plen);
    if (!tab) return 0;

    size_t key_len = (size_t)(tab - payload);
    if (key_len == 0 || key_len > 4096) return 0;

    uint8_t off_bytes[8];
    write_u64_be(off_bytes, (uint64_t)rec_off);

    if (!kyber_btree_put(db->kyber, payload, key_len, off_bytes, 8)) {
        return -1;
    }

    return 0;
}

static int server_get(ServerDB *db, const char *key, size_t klen,
                      uint8_t **out_payload, size_t *out_len) {
    void *v;
    size_t vlen;

    if (!kyber_btree_get(db->kyber, key, klen, &v, &vlen)) {
        return -1;
    }

    if (vlen != 8) {
        free(v);
        return -1;
    }

    uint64_t off = 0;
    uint8_t *p = (uint8_t*)v;
    for (int i = 0; i < 8; i++) off = (off << 8) | p[i];
    free(v);

    uint8_t header[HEADER_SIZE];
    if (pread(db->storage_fd, header, HEADER_SIZE, (off_t)off) != HEADER_SIZE) return -1;
    if (header[0] != MAGIC_BYTE) return -1;

    uint64_t plen = 0;
    for (int i = 0; i < 8; i++) plen = (plen << 8) | header[13 + i];

    uint8_t *payload = malloc(plen);
    if (!payload) return -1;

    if (pread(db->storage_fd, payload, plen, (off_t)(off + HEADER_SIZE)) != (ssize_t)plen) {
        free(payload);
        return -1;
    }

    *out_payload = payload;
    *out_len = (size_t)plen;
    return 0;
}

static int send_all(int fd, const void *buf, size_t len) {
    const uint8_t *p = buf;
    size_t sent = 0;
    while (sent < len) {
        ssize_t n = send(fd, p + sent, len - sent, MSG_NOSIGNAL);
        if (n <= 0) return -1;
        sent += (size_t)n;
    }
    return 0;
}

static int send_ok(int fd, const char *body) {
    char buf[512];
    int n = snprintf(buf, sizeof buf, "+%s\n", body ? body : "OK");
    return send_all(fd, buf, (size_t)n);
}

static int send_err(int fd, const char *msg) {
    char buf[512];
    int n = snprintf(buf, sizeof buf, "-%s\n", msg ? msg : "ERROR");
    return send_all(fd, buf, (size_t)n);
}

static int send_value(int fd, const uint8_t *payload, size_t len) {
    char header[64];
    int n = snprintf(header, sizeof header, "$%zu\n", len);
    if (send_all(fd, header, (size_t)n) != 0) return -1;
    if (len > 0 && send_all(fd, payload, len) != 0) return -1;
    return send_all(fd, "\n", 1);
}

/* Processa uma linha de comando já terminada com \n */
static void process_line(ServerDB *db, int fd, char *line, size_t len,
                         uint64_t *batch_count, int *in_batch) {
    if (len > 0 && line[len - 1] == '\n') line[len - 1] = '\0';

    if (strcmp(line, "PING") == 0) {
        send_ok(fd, "PONG");
        return;
    }

    if (strcmp(line, "STATS") == 0) {
        KyberBTreeStats st;
        if (kyber_btree_stats(db->kyber, &st)) {
            char body[256];
            snprintf(body, sizeof body,
                     "keys=%llu pages=%llu depth=%llu size=%llu",
                     (unsigned long long)st.num_keys,
                     (unsigned long long)st.num_pages,
                     (unsigned long long)st.depth,
                     (unsigned long long)st.file_size);
            send_ok(fd, body);
        } else {
            send_err(fd, "STATS_FAILED");
        }
        return;
    }

    if (strcmp(line, "BATCH_BEGIN") == 0) {
        *in_batch = 1;
        *batch_count = 0;
        send_ok(fd, "BATCH_READY");
        return;
    }

    if (strcmp(line, "BATCH_COMMIT") == 0) {
        if (!*in_batch) {
            send_err(fd, "NO_BATCH");
            return;
        }
        fsync(db->storage_fd);
        *in_batch = 0;
        char body[64];
        snprintf(body, sizeof body, "COMMITTED=%llu",
                 (unsigned long long)*batch_count);
        *batch_count = 0;
        send_ok(fd, body);
        return;
    }

    if (strncmp(line, "PUT\t", 4) == 0) {
        char *worker_s = line + 4;
        char *biome_s = strchr(worker_s, '\t');
        if (!biome_s) {
            send_err(fd, "BAD_PUT");
            return;
        }
        *biome_s++ = '\0';

        char *payload = strchr(biome_s, '\t');
        if (!payload) {
            send_err(fd, "BAD_PUT");
            return;
        }
        *payload++ = '\0';

        uint32_t worker_id = (uint32_t)strtoul(worker_s, NULL, 10);
        uint32_t biome_id = (uint32_t)strtoul(biome_s, NULL, 10);
        size_t plen = strlen(payload);

        if (server_put(db, worker_id, biome_id, (uint8_t*)payload, plen) == 0) {
            if (*in_batch) (*batch_count)++;
            send_ok(fd, "PUT");
        } else {
            send_err(fd, "PUT_FAILED");
        }
        return;
    }

    if (strncmp(line, "GET\t", 4) == 0) {
        char *key = line + 4;
        uint8_t *payload;
        size_t plen;
        if (server_get(db, key, strlen(key), &payload, &plen) == 0) {
            send_value(fd, payload, plen);
            free(payload);
        } else {
            send_err(fd, "NOT_FOUND");
        }
        return;
    }

    send_err(fd, "UNKNOWN_COMMAND");
}

int main(int argc, char **argv) {
    const char *storage_path = "yoda_storage.log";
    const char *kyber_path = "yoda_storage.log.kyber";

    if (argc > 1) storage_path = argv[1];
    if (argc > 2) kyber_path = argv[2];

    signal(SIGINT, handle_signal);
    signal(SIGTERM, handle_signal);
    signal(SIGPIPE, SIG_IGN);

    ServerDB db = { .storage_fd = -1, .lock_fd = -1, .kyber = NULL, .current_offset = 0 };

    int rc = server_open(&db, storage_path, kyber_path);
    if (rc == -2) {
        fprintf(stderr, "Erro: outro daemon já está ativo.\n");
        return 1;
    }
    if (rc != 0) {
        fprintf(stderr, "Erro: falha ao abrir banco.\n");
        return 1;
    }

    unlink(YODA_SOCKET_PATH);

    int sfd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sfd < 0) {
        perror("socket");
        server_close(&db);
        return 1;
    }

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof addr);
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, YODA_SOCKET_PATH, sizeof addr.sun_path - 1);

    if (bind(sfd, (struct sockaddr*)&addr, sizeof addr) < 0) {
        perror("bind");
        close(sfd);
        server_close(&db);
        return 1;
    }

    chmod(YODA_SOCKET_PATH, 0600);

    if (listen(sfd, 64) < 0) {
        perror("listen");
        close(sfd);
        server_close(&db);
        return 1;
    }

    FILE *pf = fopen(YODA_PID_PATH, "w");
    if (pf) {
        fprintf(pf, "%d\n", getpid());
        fclose(pf);
    }

    log_msg("daemon iniciado");

    struct pollfd fds[65];
    int nfds = 1;
    fds[0].fd = sfd;
    fds[0].events = POLLIN;

    static char bufs[64][MAX_MSG];
    static size_t lens[64];
    static uint64_t batch_counts[64];
    static int in_batches[64];

    while (running) {
        int rv = poll(fds, (nfds_t)nfds, 500);
        if (rv < 0) {
            if (errno == EINTR) continue;
            break;
        }

        if (fds[0].revents & POLLIN) {
            int cfd = accept(sfd, NULL, NULL);
            if (cfd >= 0) {
                if (nfds < 65) {
                    int idx = nfds - 1;
                    fds[nfds].fd = cfd;
                    fds[nfds].events = POLLIN;
                    lens[idx] = 0;
                    batch_counts[idx] = 0;
                    in_batches[idx] = 0;
                    nfds++;
                } else {
                    close(cfd);
                }
            }
        }

        for (int i = 1; i < nfds && running; i++) {
            if (fds[i].revents & (POLLIN | POLLHUP | POLLERR)) {
                int idx = i - 1;
                ssize_t n = recv(fds[i].fd, bufs[idx] + lens[idx],
                                 MAX_MSG - lens[idx] - 1, 0);
                if (n <= 0) {
                    close(fds[i].fd);
                    fds[i] = fds[nfds - 1];
                    if (i - 1 != nfds - 2) {
                        memcpy(bufs[i - 1], bufs[nfds - 2], lens[nfds - 2]);
                        lens[i - 1] = lens[nfds - 2];
                        batch_counts[i - 1] = batch_counts[nfds - 2];
                        in_batches[i - 1] = in_batches[nfds - 2];
                    }
                    nfds--;
                    i--;
                    continue;
                }

                lens[idx] += (size_t)n;
                bufs[idx][lens[idx]] = '\0';

                char *start = bufs[idx];
                char *nl;
                while ((nl = strchr(start, '\n')) != NULL) {
                    size_t line_len = (size_t)(nl - start + 1);
                    process_line(&db, fds[i].fd, start, line_len,
                                 &batch_counts[idx], &in_batches[idx]);
                    start = nl + 1;
                }

                size_t remaining = lens[idx] - (size_t)(start - bufs[idx]);
                if (remaining > 0) memmove(bufs[idx], start, remaining);
                lens[idx] = remaining;
            }
        }
    }

    log_msg("encerrando daemon");

    for (int i = 1; i < nfds; i++) close(fds[i].fd);
    close(sfd);
    unlink(YODA_SOCKET_PATH);
    unlink(YODA_PID_PATH);

    server_close(&db);
    return 0;
}
