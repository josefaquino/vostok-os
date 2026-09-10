package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"math"
	"os"
	"time"

	_ "modernc.org/sqlite" // Pure Go SQLite driver (CGO-free)
)

// Cores ANSI para stderr (Isolamento de Canal)
const (
	ClrReset   = "\033[0m"
	ClrInfo    = "\033[0;34m"
	ClrSuccess = "\033[0;32m"
	ClrWarn    = "\033[0;33m"
	ClrError   = "\033[0;31m"
)

// Observation representa a linha do SQLite WAL
type Observation struct {
	ID            string
	Timestamp     string
	Biome         string
	SourceURL     string
	Title         string
	Status        string
	ContentHash   string
	DriverVersion string
	Payload       string
}

// Log helpers
func logInfo(format string, v ...interface{}) {
	fmt.Fprintf(os.Stderr, "%s[INFO] %s - %s%s\n", ClrInfo, time.Now().Format("2006-01-02T15:04:05Z07:00"), fmt.Sprintf(format, v...), ClrReset)
}
func logSuccess(format string, v ...interface{}) {
	fmt.Fprintf(os.Stderr, "%s[SUCCESS] %s - %s%s\n", ClrSuccess, time.Now().Format("2006-01-02T15:04:05Z07:00"), fmt.Sprintf(format, v...), ClrReset)
}
func logWarn(format string, v ...interface{}) {
	fmt.Fprintf(os.Stderr, "%s[WARN] %s - %s%s\n", ClrWarn, time.Now().Format("2006-01-02T15:04:05Z07:00"), fmt.Sprintf(format, v...), ClrReset)
}
func logError(format string, v ...interface{}) {
	fmt.Fprintf(os.Stderr, "%s[ERROR] %s - %s%s\n", ClrError, time.Now().Format("2006-01-02T15:04:05Z07:00"), fmt.Sprintf(format, v...), ClrReset)
}

func main() {
	logInfo("Iniciando Yoda Health Engine v1.1 (RFC-0030 - Transaction-Batched)...")

	dbPath := "data/frontier.db"
	if _, err := os.Stat(dbPath); os.IsNotExist(err) {
		logError("Banco de dados %s não encontrado! Certifique-se de executar na raiz do Vostok.", dbPath)
		os.Exit(1)
	}

	// Adicionado busy_timeout=30000 (30 segundos) para mitigar SQLITE_BUSY de concorrência com o daemon do Vostok
	dsn := dbPath + "?_pragma=journal_mode(WAL)&_pragma=busy_timeout(30000)"
	db, err := sql.Open("sqlite", dsn)
	if err != nil {
		logError("Erro ao conectar no SQLite: %v", err)
		os.Exit(1)
	}
	defer db.Close()

	// Query de leitura das observações completadas ou processadas
	query := `
		SELECT id, timestamp, biome, source_url, title, status, content_hash, driver_version, payload 
		FROM observations 
		WHERE status NOT IN ('QUEUED', 'PROCESSING')
	`
	rows, err := db.Query(query)
	if err != nil {
		logError("Erro ao executar consulta: %v", err)
		os.Exit(1)
	}
	defer rows.Close()

	var observations []Observation
	for rows.Next() {
		var obs Observation
		err := rows.Scan(&obs.ID, &obs.Timestamp, &obs.Biome, &obs.SourceURL, &obs.Title, &obs.Status, &obs.ContentHash, &obs.DriverVersion, &obs.Payload)
		if err != nil {
			logWarn("Erro ao ler linha: %v", err)
			continue
		}
		observations = append(observations, obs)
	}

	totalObs := len(observations)
	logInfo("Encontradas %d observações qualificadas para cálculo de Health Score.", totalObs)

	countDone := 0
	countFailed := 0
	statsByBiome := make(map[string]map[string]int)

	// Lógica de Lotes (Batching) com Transações para otimização massiva e evitar bloqueio de banco
	batchSize := 5000
	for i := 0; i < totalObs; i += batchSize {
		end := i + batchSize
		if end > totalObs {
			end = totalObs
		}

		tx, err := db.Begin()
		if err != nil {
			logError("Falha ao iniciar transação no lote %d-%d: %v", i, end, err)
			countFailed += (end - i)
			continue
		}

		stmt, err := tx.Prepare("UPDATE observations SET payload = ? WHERE id = ?")
		if err != nil {
			logError("Falha ao preparar statement para transação: %v", err)
			tx.Rollback()
			countFailed += (end - i)
			continue
		}

		for _, obs := range observations[i:end] {
			// Inicializa mapa de estatísticas para o bioma
			if _, exists := statsByBiome[obs.Biome]; !exists {
				statsByBiome[obs.Biome] = map[string]int{
					"VIABLE":     0,
					"DEGRADED":   0,
					"NON_VIABLE": 0,
				}
			}

			score, label := calculateHealth(obs)

			// Atualiza o JSON do Payload original injetando as novas chaves
			var payloadMap map[string]interface{}
			err := json.Unmarshal([]byte(obs.Payload), &payloadMap)
			if err != nil {
				payloadMap = make(map[string]interface{})
			}

			payloadMap["health_score"] = score
			payloadMap["viability_label"] = label

			newPayloadBytes, err := json.Marshal(payloadMap)
			if err != nil {
				logWarn("Falha ao serializar payload modificado para ID %s: %v", obs.ID, err)
				continue
			}

			_, err = stmt.Exec(string(newPayloadBytes), obs.ID)
			if err != nil {
				logWarn("Falha ao acumular update para ID %s: %v", obs.ID, err)
			} else {
				statsByBiome[obs.Biome][label]++
				countDone++
			}
		}

		stmt.Close()
		if err := tx.Commit(); err != nil {
			logError("Falha ao comitar transação para lote %d-%d (desfazendo lote): %v", i, end, err)
			countFailed += (end - i)
		} else {
			logInfo("Lote de %d observações gravado com sucesso (%d/%d)...", end-i, end, totalObs)
		}
	}

	// Relatório de Encerramento (stdout puro para SRE)
	fmt.Println("\n=========================================================================")
	fmt.Println("             YODA HEALTH ENGINE v1.1 — TABELA DE CONSOLIDADO             ")
	fmt.Println("=========================================================================")
	fmt.Printf("Sucesso: %-10d | Falhas de Persistência: %-10d\n", countDone, countFailed)
	fmt.Println("-------------------------------------------------------------------------")
	fmt.Printf("%-22s | %-12s | %-12s | %-12s\n", "Bioma", "VIABLE", "DEGRADED", "NON_VIABLE")
	fmt.Println("-------------------------------------------------------------------------")
	for biome, labels := range statsByBiome {
		fmt.Printf("%-22s | %-12d | %-12d | %-12d\n", biome, labels["VIABLE"], labels["DEGRADED"], labels["NON_VIABLE"])
	}
	fmt.Println("=========================================================================\n")

	logSuccess("Yoda Health Engine concluído! Todos os payloads foram enriquecidos com sucesso.")
}

// calculateHealth avalia os genes de cada bioma e retorna o Health Score (0-100) e a Categoria (Viable, Degraded, Non-Viable)
func calculateHealth(obs Observation) (int, string) {
	// Se a tarefa falhou ou foi descartada de antemão, ou se o status original for FAILED
	if obs.Status == "FAILED" || obs.Status == "INVALID" || obs.Status == "SKIPPED" {
		return 0, "NON_VIABLE"
	}

	var payload map[string]interface{}
	if err := json.Unmarshal([]byte(obs.Payload), &payload); err != nil {
		return 0, "NON_VIABLE"
	}

	// Verifica se há alguma mensagem de erro capturada pelo driver
	if errMsg, exists := payload["error_message"]; exists {
		if str, ok := errMsg.(string); ok && str != "" {
			return 0, "NON_VIABLE"
		}
	}

	var score float64 = 0.0

	switch obs.Biome {
	case "github_repository":
		// 1. Gene Social: estrelas (stargazers_count)
		var stars float64 = 0.0
		if val, ok := payload["repo_stars"]; ok {
			if f, ok := val.(float64); ok {
				stars = f
			}
		}
		sStars := 0.0
		if stars > 0 {
			sStars = math.Log1p(stars) / math.Log1p(100000.0)
			if sStars > 1.0 {
				sStars = 1.0
			}
		}

		// 2. Gene de Atividade: urls de issues extraídas
		sActive := 0.0
		if val, ok := payload["extracted_urls"]; ok {
			if arr, ok := val.([]interface{}); ok {
				sActive = float64(len(arr)) / 5.0
				if sActive > 1.0 {
					sActive = 1.0
				}
			}
		}

		// 3. Gene Estrutural: readme hash
		sReadme := 0.0
		if val, ok := payload["readme_hash"]; ok {
			if hashStr, ok := val.(string); ok && hashStr != "N/A" && hashStr != "" {
				sReadme = 1.0
			}
		}

		// 4. Gene de Performance: latência da API
		var latency float64 = 0.0
		if val, ok := payload["latency_ms"]; ok {
			if f, ok := val.(float64); ok {
				latency = f
			}
		}
		sLatency := 1.0 - (latency / 2000.0)
		if sLatency < 0.0 {
			sLatency = 0.0
		}

		// Fórmula Combinada GitHub
		score = (0.40 * sStars) + (0.30 * sActive) + (0.20 * sReadme) + (0.10 * sLatency)

	case "rss_feed":
		// 1. Gene de Validade: magic_bytes == "Valid XML Feed"
		sValid := 0.0
		if val, ok := payload["magic_bytes"]; ok {
			if str, ok := val.(string); ok && str == "Valid XML Feed" {
				sValid = 1.0
			}
		}

		// 2. Gene de Fertilidade: items_count
		var items float64 = 0.0
		if val, ok := payload["items_count"]; ok {
			if f, ok := val.(float64); ok {
				items = f
			}
		}
		sFertility := items / 20.0
		if sFertility > 1.0 {
			sFertility = 1.0
		}

		// 3. Gene de Performance: latency_ms
		var latency float64 = 0.0
		if val, ok := payload["latency_ms"]; ok {
			if f, ok := val.(float64); ok {
				latency = f
			}
		}
		sLatency := 1.0 - (latency / 5000.0)
		if sLatency < 0.0 {
			sLatency = 0.0
		}

		// Fórmula Combinada RSS
		score = (0.50 * sValid) + (0.30 * sFertility) + (0.20 * sLatency)

	case "html_page":
		sValid := 1.0 // Por estar DONE e sem error_message ativo

		// 1. Gene de Conectividade: links extraídos (se houver extração)
		sConnect := 0.0
		if val, ok := payload["extracted_urls"]; ok {
			if arr, ok := val.([]interface{}); ok {
				sConnect = float64(len(arr)) / 10.0
				if sConnect > 1.0 {
					sConnect = 1.0
				}
			}
		}

		// 2. Gene de Performance: latency_ms
		var latency float64 = 0.0
		if val, ok := payload["latency_ms"]; ok {
			if f, ok := val.(float64); ok {
				latency = f
			}
		}
		sLatency := 1.0 - (latency / 10000.0)
		if sLatency < 0.0 {
			sLatency = 0.0
		}

		// 3. Gene Estrutural: tamanho do arquivo
		var size float64 = 0.0
		if val, ok := payload["content_length"]; ok {
			if f, ok := val.(float64); ok {
				size = f
			}
		}
		sSize := 0.0
		if size > 0 {
			if size >= 5000.0 && size <= 500000.0 {
				sSize = 1.0
			} else if size > 500000.0 {
				sSize = 1.0 - (size / 2000000.0)
				if sSize < 0.1 {
					sSize = 0.1
				}
			} else {
				sSize = 0.5 // Páginas pequenas demais
			}
		}

		// Fórmula Combinada HTML
		score = (0.40 * sValid) + (0.30 * sConnect) + (0.20 * sLatency) + (0.10 * sSize)

	default:
		score = 0.50
	}

	finalScore := int(math.Round(score * 100.0))
	if finalScore < 0 {
		finalScore = 0
	}
	if finalScore > 100 {
		finalScore = 100
	}

	// Classificação semântica
	label := "NON_VIABLE"
	if finalScore >= 80 {
		label = "VIABLE"
	} else if finalScore >= 50 {
		label = "DEGRADED"
	}

	return finalScore, label
}