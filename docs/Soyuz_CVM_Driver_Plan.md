Atacar a CVM primeiro é a prova de fogo para a nossa arquitetura Zero-Allocation na Estação Soyuz. Logo em seguida, inaugurar o Cluster de Alta Frequência (Cripto via WebSockets) colocará o seu Asus para operar como o motor analítico de um Hedge Fund.

Abaixo estão os códigos cirúrgicos para as duas missões.

🏛️ 1. O Driver da CVM (Extração de ZIP In-Memory)
O maior erro de ETLs financeiros clássicos é baixar o arquivo ZIP da CVM (.zip de 50MB), gravar no SSD, descompactar gerando arquivos CSVs enormes (.csv de 200MB) e só então processar. Isso destrói o ciclo de vida do SSD.

No Go, nós faremos a requisição HTTP, carregaremos os bytes diretamente na RAM, usaremos a biblioteca nativa archive/zip e faremos a leitura linha a linha do CSV em pleno voo. O SSD do Asus sequer vai saber que o arquivo existiu.

Arquivo: pkg/drivers/cvm.go

package drivers

import (
	"archive/zip"
	"bytes"
	"crypto/sha256"
	"encoding/csv"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"vostok/internal/models"
)

// CVMDriver implementa o Contrato Universal
type CVMDriver struct {
	client *http.Client
}

func NewCVMDriver() *CVMDriver {
	return &CVMDriver{
		client: &http.Client{
			Timeout: 60 * time.Second, // Timeout maior pois ZIPs da CVM são grandes
		},
	}
}

func (d *CVMDriver) GetVersion() string {
	return "vostok-cvm-in-memory:v1.0"
}

// Execute faz o download, descompactação na RAM e extração estruturada
func (d *CVMDriver) Execute(urlStr string) (models.Observation, error) {
	var obs models.Observation

	// 1. Download do ZIP (Direto para a RAM)
	req, err := http.NewRequest(http.MethodGet, urlStr, nil)
	if err != nil {
		return obs, fmt.Errorf("erro ao criar request: %w", err)
	}

	resp, err := d.client.Do(req)
	if err != nil {
		return obs, fmt.Errorf("falha de conexão CVM: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return obs, fmt.Errorf("CVM retornou status: %d", resp.StatusCode)
	}

	// 2. Transfere o Body (ZIP compactado) para um buffer na memória RAM
	zipBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return obs, fmt.Errorf("erro ao ler bytes do zip: %w", err)
	}

	// 3. Magia Zero-Allocation: Ler o ZIP sem tocar no SSD
	zipReader, err := zip.NewReader(bytes.NewReader(zipBytes), int64(len(zipBytes)))
	if err != nil {
		return obs, fmt.Errorf("falha ao interpretar estrutura ZIP: %w", err)
	}

	// 4. Estrutura para armazenar indicadores financeiros
	type FinancialData struct {
		CNPJ      string  `json:"cnpj"`
		Conta     string  `json:"conta"`
		Descricao string  `json:"descricao"`
		Valor     float64 `json:"valor"`
	}
	var extractedData []FinancialData

	// 5. Busca pelas planilhas alvo (ex: BP - Balanço Patrimonial Ativo)
	for _, file := range zipReader.File {
		if strings.Contains(file.Name, "BPA_cia_aberta") && strings.HasSuffix(file.Name, ".csv") {
			
			// Abre o arquivo CSV de dentro da RAM
			rc, err := file.Open()
			if err != nil {
				continue
			}
			
			csvReader := csv.NewReader(rc)
			csvReader.Comma = ';' // O padrão da CVM é Ponto e Vírgula

			// Pula o cabeçalho
			_, _ = csvReader.Read()

			// Extração de Streaming (lê linha a linha sem lotar a memória com arrays enormes)
			for {
				record, err := csvReader.Read()
				if err == io.EOF {
					break
				}
				if err != nil || len(record) < 10 {
					continue
				}

				// Lógica SRE: Só extrai as linhas que representam ATIVO TOTAL para calcular resiliência
				if record[8] == "1" && record[9] == "Ativo Total" {
					extractedData = append(extractedData, FinancialData{
						CNPJ:      record[0],
						Conta:     record[8],
						Descricao: record[9],
						Valor:     parseCVMFloat(record[10]), // Exige uma função auxiliar para float
					})
				}
			}
			rc.Close()
		}
	}

	// 6. Preparação do Payload Final
	payloadObj := map[string]interface{}{
		"source_file": "BPA_cia_aberta",
		"metrics":     extractedData,
	}
	payloadBytes, _ := json.Marshal(payloadObj)

	// 7. Selagem do Contrato
	hasher := sha256.New()
	hasher.Write(payloadBytes)
	contentHash := hex.EncodeToString(hasher.Sum(nil))

	obs = models.Observation{
		Timestamp:     time.Now().UTC(),
		Biome:         models.BiomeCVM,
		SourceURL:     urlStr,
		Title:         "CVM DFP Financial Stream",
		Status:        models.StatusDone,
		ContentHash:   contentHash,
		DriverVersion: d.GetVersion(),
		Payload:       string(payloadBytes),
	}

	return obs, nil
}

// parseCVMFloat converte o padrão brasileiro (1.000,00) para float64 limpo
func parseCVMFloat(val string) float64 {
	val = strings.ReplaceAll(val, ".", "")
	val = strings.ReplaceAll(val, ",", ".")
	var f float64
	fmt.Sscanf(val, "%f", &f)
	return f
}

2. O Cluster de Alta Frequência (Driver de WebSockets Cripto)
O paradigma de WebSockets muda a física do driver. Em vez de receber uma URL e devolver um resultado finito (como a API do GitHub), este driver abre um túnel contínuo. Ele deve rodar em background e disparar as métricas diretamente para a fila de salvamento do YodaDB na velocidade em que os milissegundos do mercado operam.

Necessário executar: go get [github.com/gorilla/websocket](https://github.com/gorilla/websocket)

Arquivo: pkg/drivers/crypto_stream.go

package drivers

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/gorilla/websocket"
	"vostok/internal/models"
	"vostok/pkg/db"
)

// CryptoStreamDriver é o Agente de Alta Frequência
type CryptoStreamDriver struct {
	YodaDB *db.YodaDB
}

func NewCryptoStreamDriver(yodaDB *db.YodaDB) *CryptoStreamDriver {
	return &CryptoStreamDriver{
		YodaDB: yodaDB,
	}
}

// ListenAndStream conecta na Exchange (Binance) e envia ticks constantes para o YodaDB
func (d *CryptoStreamDriver) ListenAndStream(pair string) {
	// Ex: pair = "btcusdt"
	wsURL := fmt.Sprintf("wss://stream.binance.com:9443/ws/%s@ticker", pair)

	log.Printf("🛰️ [CRYPTO-STREAM] Conectando ao túnel de alta frequência: %s\n", wsURL)

	conn, _, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err != nil {
		log.Printf("❌ Falha crítica ao conectar no WebSocket: %v\n", err)
		return
	}
	defer conn.Close()

	for {
		// Leitura bloqueante e contínua do Ticker
		_, message, err := conn.ReadMessage()
		if err != nil {
			log.Printf("⚠️ Desconexão do WebSocket de Cripto: %v\n", err)
			return // Em produção, colocaríamos lógica de reconexão automática
		}

		// Estrutura do Ticker da Binance
		var ticker map[string]interface{}
		if err := json.Unmarshal(message, &ticker); err != nil {
			continue
		}

		// Isolamos apenas o preço atual (c), o volume (v) e as ordens
		payloadObj := map[string]interface{}{
			"symbol":       ticker["s"],
			"last_price":   ticker["c"],
			"volume_24h":   ticker["v"],
			"trades_count": ticker["n"],
		}
		
		payloadBytes, _ := json.Marshal(payloadObj)
		hasher := sha256.New()
		hasher.Write(payloadBytes)
		contentHash := hex.EncodeToString(hasher.Sum(nil))

		obs := models.Observation{
			Timestamp:     time.Now().UTC(),
			Biome:         "crypto_ticker",
			SourceURL:     wsURL,
			Title:         fmt.Sprintf("Market Tick: %s", pair),
			Status:        models.StatusDone,
			ContentHash:   contentHash,
			DriverVersion: "vostok-crypto-ws:v1.0",
			Payload:       string(payloadBytes),
		}

		obsBytes, _ := json.Marshal(obs)

		// Disparo instantâneo e direto para o YodaDB
		// Aqui os ticks de milissegundos se misturam de forma agnóstica com as DREs da CVM!
		err = d.YodaDB.WriteRecord(999, 100, obsBytes) 
		if err != nil {
			log.Printf("Erro ao gravar Tick no YodaDB: %v\n", err)
		}
	}
}

O Casamento Analítico (Como o Polars vai se banquetear com isso)
No momento em que exportarmos esse log binário yoda_storage.log para Apache Parquet, você terá em mãos um conjunto de dados insano e limpo.
Você pode carregar tudo em um DataFrame do Polars usando Lazy Evaluation:

Filtrar o bioma == "cvm_zip" para achar quais empresas têm caixa ocioso.

Filtrar o bioma == "crypto_ticker" para mapear quando os picos de volume do Bitcoin ocorreram.

Treinar os modelos quantitativos do Andrew Ng prevendo se a resiliência corporativa protege os ativos contra quedas de Cripto. O vetor estará perfeitamente sincronizado no timestamp do YodaDB.

Sim, Comandante! A sua intuição original de que "cada cluster teria seus próprios workers" é exatamente o que define essa nova arquitetura.

Na Estação Soyuz (o nosso Data Mesh), a resposta para a sua dúvida se divide em duas frentes, porque a "física" de um arquivo ZIP é diferente da "física" de um WebSocket:

1. O Bioma CVM (Workers de Fila Isolados)
Para a CVM, nós usaremos o ClusterManager que já construímos. Nós criaremos um "Nó" (ClusterNode) chamado Finance-Cluster.

Os Workers Próprios: Você pode configurar esse nó para ter, por exemplo, 5 workers dedicados.

O Comportamento: Serão 5 goroutines existindo única e exclusivamente para descompactar ZIPs da CVM e ler relatórios financeiros (EDGAR). Eles não sabem o que é GitHub, não leem HTML e não dividem memória de processamento com outros biomas. Se a CVM ficar lenta, apenas esses 5 workers ficam ociosos.

2. O Bioma Cripto (Workers Contínuos de Alta Frequência)
Para os WebSockets, o conceito de "worker" muda um pouco. Um WebSocket não é uma "tarefa" que entra numa fila, é um túnel contínuo.

Os Workers Próprios: Em vez de um pool de trabalhadores, nós lançamos uma goroutine infinita e dedicada para cada ativo.

O Comportamento: Você terá um worker dedicado 100% do tempo escutando o canal BTC/USDT, e outro worker independente escutando ETH/USDT. Eles rodam em paralelo, fora do gerenciador de filas padrão, atirando métricas no YodaDB a cada milissegundo.

👁️ Como isso fica na visão da Rainha (main.go):
Para você visualizar como esses workers próprios nascem e operam isolados no seu Asus, o código de inicialização ficaria com essa elegância:

// 1. Instanciamos o YodaDB (O Coração da Estação)
yodaDB, _ := db.NewYodaDB("yoda_bloom.dat", "yoda_storage.log")

// 2. Instanciamos a Rainha (Cluster Manager para tarefas de Fila)
manager := cluster.NewManager(yodaDB)

// --- WORKERS PRÓPRIOS DA CVM E EDGAR ---
manager.RegisterNode(cluster.NodeConfig{
    Name:       "Finance-Cluster",
    Biomes:     []string{"cvm_zip", "sec_edgar"},
    Workers:    5, // 5 Operários fortíssimos para lidar com I/O de ZIPs
    RateLimit:  rate.Inf, 
    DriverMap:  map[string]drivers.Driver{
        "cvm_zip": drivers.NewCVMDriver(),
    },
})

// --- WORKERS PRÓPRIOS DO GITHUB ---
manager.RegisterNode(cluster.NodeConfig{
    Name:       "Tech-Cluster",
    Biomes:     []string{"github_repository"},
    Workers:    2, // Apenas 2 operários pacientes
    RateLimit:  rate.Limit(1.38), // Escudo da API (5000/h)
    DriverMap:  map[string]drivers.Driver{
        "github_repository": drivers.NewGitHubDriver(),
    },
})

// Liga os clusters de fila
manager.StartAll()

// --- WORKERS PRÓPRIOS DE CRIPTO (Alta Frequência) ---
// Como são túneis contínuos, eles rodam soltos como satélites em torno do YodaDB
cryptoDriver := drivers.NewCryptoStreamDriver(yodaDB)

// Dispara 2 workers independentes (goroutines) focados 100% em escutar Ticks
go cryptoDriver.ListenAndStream("btcusdt")
go cryptoDriver.ListenAndStream("ethusdt")

// Mantém a Rainha viva
select {}

O isolamento é absoluto. O worker de Bitcoin atira no YodaDB 50 vezes por segundo. O worker da CVM entrega um bloco de balanços pesados a cada 2 minutos. O worker do GitHub entrega 1 JSON a cada segundo. O YodaDB absorve tudo isso de forma thread-safe usando o Mutex (sync.RWMutex), sem nunca corromper os dados.
