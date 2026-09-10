/*
 * yodadb_client.c - Client para daemon YodaDB
 * 
 * Uso:
 *   cat data.tsv | yodadb-client put [worker_id]
 *   yodadb-client get <key>
 *   yodadb-client stats
 *   yodadb-client ping
 * 
 * Integração com GNU Parallel:
 *   cat data.tsv | parallel --pipe -N 5000 './yodadb-client put 1'
 */

#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <errno.h>

#define YODA_SOCKET_PATH "/tmp/yodadb.sock"
#define BUF_SIZE (256 * 1024)

static int connect_to_server(void) {
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) return -1;

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof addr);
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, YODA_SOCKET_PATH, sizeof addr.sun_path - 1);

    if (connect(fd, (struct sockaddr*)&addr, sizeof addr) < 0) {
        close(fd);
        return -1;
    }

    return fd;
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

static int send_line(int fd, const char *line) {
    size_t len = strlen(line);
    return send_all(fd, line, len);
}

static ssize_t recv_line(int fd, char *buf, size_t buf_size) {
    size_t pos = 0;
    while (pos < buf_size - 1) {
        char c;
        ssize_t n = recv(fd, &c, 1, 0);
        if (n <= 0) return -1;
        buf[pos++] = c;
        if (c == '\n') {
            buf[pos] = '\0';
            return (ssize_t)pos;
        }
    }
    return -1;
}

static int cmd_ping(void) {
    int fd = connect_to_server();
    if (fd < 0) {
        fprintf(stderr, "❌ Daemon não está rodando\n");
        return 1;
    }

    send_line(fd, "PING\n");

    char buf[256];
    if (recv_line(fd, buf, sizeof buf) > 0) {
        printf("%s", buf);
    }

    close(fd);
    return 0;
}

static int cmd_stats(void) {
    int fd = connect_to_server();
    if (fd < 0) {
        fprintf(stderr, "❌ Daemon não está rodando\n");
        return 1;
    }

    send_line(fd, "STATS\n");

    char buf[512];
    if (recv_line(fd, buf, sizeof buf) > 0) {
        printf("%s", buf);
    }

    close(fd);
    return 0;
}

static int cmd_get(const char *key) {
    int fd = connect_to_server();
    if (fd < 0) {
        fprintf(stderr, "❌ Daemon não está rodando\n");
        return 1;
    }

    char cmd[512];
    snprintf(cmd, sizeof cmd, "GET\t%s\n", key);
    send_line(fd, cmd);

    char buf[512];
    if (recv_line(fd, buf, sizeof buf) > 0) {
        if (buf[0] == '$') {
            size_t len = 0;
            sscanf(buf + 1, "%zu", &len);

            char *payload = malloc(len + 1);
            if (!payload) {
                close(fd);
                return 1;
            }

            size_t received = 0;
            while (received < len) {
                ssize_t n = recv(fd, payload + received, len - received, 0);
                if (n <= 0) {
                    free(payload);
                    close(fd);
                    return 1;
                }
                received += (size_t)n;
            }

            /* Ler o \n final */
            char nl;
            recv(fd, &nl, 1, 0);

            payload[len] = '\0';
            printf("%s\n", payload);
            free(payload);
        } else {
            printf("%s", buf);
        }
    }

    close(fd);
    return 0;
}

static int cmd_put(uint32_t worker_id) {
    int fd = connect_to_server();
    if (fd < 0) {
        fprintf(stderr, "❌ Daemon não está rodando\n");
        return 1;
    }

    /* Iniciar batch */
    send_line(fd, "BATCH_BEGIN\n");

    char buf[256];
    if (recv_line(fd, buf, sizeof buf) <= 0 || strncmp(buf, "+BATCH_READY", 12) != 0) {
        fprintf(stderr, "❌ Falha ao iniciar batch\n");
        close(fd);
        return 1;
    }

    /* Ler stdin e enviar PUTs */
    char line[BUF_SIZE];
    uint64_t count = 0;
    uint64_t errors = 0;

    while (fgets(line, sizeof line, stdin)) {
        size_t len = strlen(line);
        if (len > 0 && line[len - 1] == '\n') {
            line[len - 1] = '\0';
            len--;
        }

        if (len == 0) continue;

        /* Formato: PUT\t<worker_id>\t100\t<payload>\n */
        char cmd[BUF_SIZE + 64];
        int n = snprintf(cmd, sizeof cmd, "PUT\t%u\t100\t%s\n", worker_id, line);

        if (send_all(fd, cmd, (size_t)n) != 0) {
            fprintf(stderr, "❌ Falha ao enviar PUT\n");
            errors++;
            continue;
        }

        if (recv_line(fd, buf, sizeof buf) <= 0) {
            fprintf(stderr, "❌ Falha ao receber resposta\n");
            errors++;
            continue;
        }

        if (strncmp(buf, "+PUT", 4) == 0) {
            count++;
        } else {
            errors++;
        }

        /* Progresso a cada 10k */
        if (count % 10000 == 0 && count > 0) {
            fprintf(stderr, "   ... %llu registros enviados\n", (unsigned long long)count);
        }
    }

    /* Commit do batch */
    send_line(fd, "BATCH_COMMIT\n");

    if (recv_line(fd, buf, sizeof buf) > 0) {
        if (strncmp(buf, "+COMMITTED", 10) == 0) {
            /* Sucesso */
        } else {
            fprintf(stderr, "❌ Falha no commit: %s", buf);
            errors++;
        }
    }

    close(fd);

    fprintf(stderr, "✅ %llu registros enviados (%llu erros)\n",
            (unsigned long long)count, (unsigned long long)errors);

    return errors > 0 ? 1 : 0;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Uso:\n");
        fprintf(stderr, "  cat data.tsv | yodadb-client put [worker_id]\n");
        fprintf(stderr, "  yodadb-client get <key>\n");
        fprintf(stderr, "  yodadb-client stats\n");
        fprintf(stderr, "  yodadb-client ping\n");
        return 1;
    }

    if (strcmp(argv[1], "ping") == 0) {
        return cmd_ping();
    }

    if (strcmp(argv[1], "stats") == 0) {
        return cmd_stats();
    }

    if (strcmp(argv[1], "get") == 0) {
        if (argc < 3) {
            fprintf(stderr, "Uso: yodadb-client get <key>\n");
            return 1;
        }
        return cmd_get(argv[2]);
    }

    if (strcmp(argv[1], "put") == 0) {
        uint32_t worker_id = 1;
        if (argc > 2) {
            worker_id = (uint32_t)strtoul(argv[2], NULL, 10);
        }
        return cmd_put(worker_id);
    }

    fprintf(stderr, "❌ Comando desconhecido: %s\n", argv[1]);
    return 1;
}
