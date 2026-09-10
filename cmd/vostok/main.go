package main

import (
	"embed"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"io/fs"
	"log"
	"net/http"
	"os"
	"time"

	"vostok/pkg/db" // Importa o nosso pacote integrado db/workers
)

//go:embed frontend/*
var frontendAssets embed.FS

var pool *db.WorkerPool

const (
	StoragePath = "yoda_storage.log"
	BloomPath   = "yoda_bloom.dat"
	MagicByte   = byte(0xAA)
	HeaderSize  = 18
)

func main() {
	log.Println("\033[0;32m🌅 [VOSTOK OS v13] Inicializando Cockpit Visual sob YodaDB Fusion 🔮🛡️\033[0m")
	log.Println("\033[0;34m[SRE] Acoplando o motor YodaDB (mmap Bloom Filter + Append-Only Log)...\033[0m")

	// 1. Inicializa o Worker Pool de 20 Seekers acoplado ao YodaDB v3
	var err error
	pool, err = db.NewWorkerPool(BloomPath, StoragePath, 20, "./drivers/html-driver-v2")
	if err != nil {
		log.Fatalf("❌ [FALHA CRÍTICA] Erro ao acoplar YodaDB ao Worker Pool: %v", err)
	}

	// 2. Alimenta a fila com algumas sementes iniciais se o arquivo de sementes existir
	bootstrapSeeds()

	// 3. Dá a partida oficial nos 20 Jedi Seekers e no despachador de prioridades em RAM
	pool.Start()
	defer pool.Stop()

	// 4. Definição das rotas de API do Cockpit
	http.HandleFunc("/api/observations", handleObservations)
	http.HandleFunc("/api/stats", handleStats)
	http.HandleFunc("/api/enqueue", handleEnqueue)

	// 5. Servidor de arquivos estáticos inteligente (Desacoplamento de UI)
	if _, err := os.Stat("vostok-core/frontend/index.html"); err == nil {
		log.Println("\033[0;33m🛠️  [DEV] Servindo interface física dinamicamente de vostok-core/frontend.\033[0m")
		http.Handle("/", http.FileServer(http.Dir("vostok-core/frontend")))
	} else if _, err := os.Stat("cmd/vostok/frontend/index.html"); err == nil {
		log.Println("\033[0;33m🛠️  [DEV] Servindo interface física de cmd/vostok/frontend.\033[0m")
		http.Handle("/", http.FileServer(http.Dir("cmd/vostok/frontend")))
	} else {
		publicFS, err := fs.Sub(frontendAssets, "frontend")
		if err != nil {
			log.Printf("⚠️  [WARN] Falha ao ler assets com go:embed. Fallback local ativo...")
			http.Handle("/", http.FileServer(http.Dir("./frontend")))
		} else {
			log.Println("✅ [EMBED] Assets front-end mapeados e embutidos no binário.")
			http.Handle("/", http.FileServer(http.FS(publicFS)))
		}
	}

	port := ":8080"
	log.Printf("🚀 [ONLINE] Cockpit sob YodaDB ativo! Sintonize em http://localhost%s", port)

	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatalf("❌ [FALHA CRÍTICA] Erro no barramento HTTP: %v", err)
	}
}

// bootstrapSeeds lê sementes locais se o banco estiver vazio para manter a colônia viva
func bootstrapSeeds() {
	seeds := []string{
		"https://hnrss.org/frontpage",
		"https://www.wikipedia.org",
		"https://news.ycombinator.com",
		"https://en.wikipedia.org/wiki/Main_Page",
		"https://www.eff.org/rss/updates.xml",
	}
	count := 0
	for _, seed := range seeds {
		if pool.ForceEnqueueJob(seed) {
			count++
		}
	}
	if count > 0 {
		log.Printf("🌱 [BOOTSTRAP] Injetadas %d sementes iniciais na fila prioritária em RAM!\033[0m\n", count)
	}
}

// readRecentObservations parses the binary log sequencial backwards or forwards to get the last N observations
func readRecentObservations(limit int) ([]db.Observation, error) {
	file, err := os.Open(StoragePath)
	if err != nil {
		if os.IsNotExist(err) {
			return []db.Observation{}, nil
		}
		return nil, err
	}
	defer file.Close()

	var list []db.Observation
	headerBuf := make([]byte, HeaderSize)
	payloadBuf := make([]byte, 1024*1024) // 1MB reusable buffer

	for {
		_, err := io.ReadFull(file, headerBuf)
		if err == io.EOF {
			break
		}
		if err != nil {
			break
		}

		if headerBuf[0] != MagicByte {
			break // Corrupção ou EOF parcial
		}

		payloadSize := binary.BigEndian.Uint32(headerBuf[14:18])

		if uint32(cap(payloadBuf)) < payloadSize {
			payloadBuf = make([]byte, payloadSize)
		} else {
			payloadBuf = payloadBuf[:payloadSize]
		}

		_, err = io.ReadFull(file, payloadBuf)
		if err != nil {
			break
		}

		var obs db.Observation
		if err := json.Unmarshal(payloadBuf, &obs); err == nil {
			list = append(list, obs)
		}
	}

	// Inverte a lista para retornar do mais recente ao mais antigo
	n := len(list)
	for i := 0; i < n/2; i++ {
		list[i], list[n-1-i] = list[n-1-i], list[i]
	}

	if len(list) > limit {
		list = list[:limit]
	}

	return list, nil
}

// Handler para listar as últimas observações diretamente do log binário do YodaDB
func handleObservations(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	list, err := readRecentObservations(100)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error": "Falha ao ler YodaDB storage: %v"}`, err), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(list)
}

// Stats estruturado para alimentar o Cockpit Visual em tempo real
type Stats struct {
	TotalGenes    int            `json:"total_genes"`
	ByBiome       map[string]int `json:"by_biome"`
	ByStatus      map[string]int `json:"by_status"`
	ActiveSeekers int            `json:"active_seekers"`
	Timestamp     time.Time      `json:"timestamp"`
}

func handleStats(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	stats := Stats{
		ByBiome:       make(map[string]int),
		ByStatus:      make(map[string]int),
		ActiveSeekers: 20,
		Timestamp:     time.Now().UTC(),
	}

	// Realiza um scan rápido em memória virtual das observações para compilar estatísticas agregadas
	list, err := readRecentObservations(50000) // Scan last 50k
	if err == nil {
		stats.TotalGenes = len(list)
		for _, obs := range list {
			stats.ByBiome[obs.Biome]++
			stats.ByStatus[obs.Status]++
		}
	}

	json.NewEncoder(w).Encode(stats)
}

// Handler para enfileirar novas sementes dinamicamente via POST request (Ponte SRE entre SQLite e Canais Go)
func handleEnqueue(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	if r.Method != http.MethodPost {
		http.Error(w, `{"error": "Método não permitido"}`, http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		URL string `json:"url"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error": "JSON inválido ou malformado"}`, http.StatusBadRequest)
		return
	}

	// Enfileira usando o método thread-safe do pool
	if pool.EnqueueJob(req.URL) {
		w.WriteHeader(http.StatusAccepted)
		w.Write([]byte(`{"status": "queued", "message": "URL enfileirada com sucesso!"}`))
	} else {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status": "skipped", "message": "URL ignorada pelo Bloom Filter ou Gatekeeper"}`))
	}
}
