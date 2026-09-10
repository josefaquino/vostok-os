Veja os drivers criados em Bash no projeto Sputnik:  1. Drivers Web, Feeds e Descoberta Geral: HTML Driver (html-driver-v2.go) RSS/Atom Feed Driver  Bash 2. Drivers de Biologia Molecular e Genômica (O Ecossistema DNA): Bio-Sequence Driver (sputnik-bio-sequence-driver.sh): Projetado para extração e mapeamento de sequências de nucleotídeos de bancos genômicos públicos.
Bio-Strain Driver (sputnik-bio-strain-driver.sh): Especialista na classificação e análise de dados de cepas e isolados biológicos.
Bio-Pathway Driver (sputnik-bio-pathway-driver.sh): Focado em reconstruir grafos relacionais de vias metabólicas e interações moleculares.
Metabolic Driver (sputnik-metabolic-driver.sh): Analisador de redes de reações químicas celulares e resiliência metabólica de organismos.
🛰️ 3. Drivers Espaciais e de Sensoriamento Remoto (A Conexão NASA)
Criados para cruzar dados climáticos físicos globais com os biomas de solo da colônia [sputnik-next-steps-spec.md]:
NASA FITS Driver (sputnik-nasa-fits-driver.sh): Parser do formato científico FITS (Flexible Image Transport System), utilizado para decodificar imagens e dados astrofísicos massivos de satélites de pesquisa.
NASA Spatial Driver (sputnik-nasa-spatial-driver.sh): Focado no processamento de sensoriamento remoto, dados geográficos e órbita de satélites (como dados climáticos NASA/NISAR) [Sputnik DB & Sputnik Flow: O Blueprint do Ecossistema de Dados de Próxima Geração].
🚜 4. Drivers de IoT, Drones e Telemetria Física
Projetados para ingestão de dados cinemáticos e de barramentos físicos industriais ou agrícolas [Research report: Open-Source IoT & Drone Telemetry Datasets, Sputnik DB & Sputnik Flow: O Blueprint do Ecossistema de Dados de Próxima Geração]:
IoT Telemetry Driver (sputnik-iot-driver.sh): Coletor genérico para fluxos contínuos de sensores de campo do bioma iot_telemetry [vostok-workers-v18.go].
Drone Telemetry Driver (sputnik-drone-driver.sh): Parser dedicado para extrair e estruturar logs de voo de veículos aéreos autônomos [Research report: Open-Source IoT & Drone Telemetry Datasets].
Vehicle Telemetry Driver (sputnik-vehicle-driver.sh): Ingestor de dados de telemetria automotiva, rastreamento e frotas terrestres [Sputnik DB & Sputnik Flow: O Blueprint do Ecossistema de Dados de Próxima Geração].
⚖️ 5. Drivers Regulatórios, Financeiros e Mercado de Capitais
Os agentes de borda focados no "Bioma de Capital" [sputnik-next-steps-spec.md]:
SEC EDGAR Driver (sputnik-driver-sec-edgar-code.md): Driver focado na extração e indexação offline de documentos 10-K e relatórios de risco corporativo dos EUA [sputnik-next-steps-spec.md].
CVM/B3 Driver (cvm-driver): O driver de mercado brasileiro desenvolvido para baixar relatórios contábeis de Demonstrações Financeiras Padronizadas (DFP) e processar de forma ultra-eficiente via stream os arquivos ZIP (BPA, BPP e DRE), calculando a resiliência corporativa de companhias abertas sem alocar megabytes em disco [sputnik-next-steps-spec.md, Blueprint Técnico: Driver CVM].
💻 6. Drivers Sociais, Acadêmicos e Desenvolvimento
GitHub Driver (sputnik-github-driver.sh / vostok-github-driver-draft.go): Nosso clássico parser de repositórios open-source, responsável por computar estrelas, issues e metadados na API do GitHub para alimentar a Árvore Evolutiva de código [vostok-github-driver-draft.go, sputnik-next-steps-spec.md].Wikipedia Driver (sputnik-wikipedia-driver.sh): Agente de extração de conhecimento livre para o bioma público.
ArXiv Driver (sputnik-arxiv-driver.sh): Coletor de artigos acadêmicos científicos e metadados do repositório ArXiv (scientific_paper) [Sputnik DB & Sputnik Flow: O Blueprint do Ecossistema de Dados de Próxima Geração, sputnik-next-steps-spec.md].
🤖 7. Drivers de Auditoria de Inteligência Artificial
IA Driver (sputnik-ia-driver.sh): Nosso sofisticado driver de comportamento de agentes LLM, projetado para monitorar, validar, auditar riscos de segurança e identificar anomalias semânticas em pipelines de inteligência artificial [Plano de Execução Técnica: Sputnik Gen 2 – Sprint 6 (Escala e Ciência)].A Simbiose dos Drivers e do YodaDB
Cada um desses drivers, embora escrito em linguagens e propósitos distintos (Bash, Python ou Go), gerava um output imutável que se acoplava cirurgicamente ao nosso Contrato de 9 colunas (RFC-0021 Evolved) [vostok-robot-report.md]:[id, timestamp, bioma, source_url, title, status, content_hash, driver_version, payload] [vostok-robot-report.md]
Isso permitia que o YodaDB persistisse dados biológicos, financeiros e espaciais no mesmo barramento atômico, de forma 100% agnóstica e escalável! Agora teremos Drivers apenas em Go, respeitando nosso contrato de 9 colunas. O projeto Yoda DB fncionou muito bem com a FILA, que tal criar um Yoda Cluster ou algo parecido para uma empresa poder usar um lake de IA outro de Bitcoin outro de RSS para usar Polars ou outra tecnolgia para Dataming e DataScience? Sempre no foco de aproveitar o momento e as dificuldades e deafios para criar um DB estilo BerkeleyDB mais completo e moderno buscando ser util para as empresas no mundo de modelos de IAs e tokens 

A evolução de um motor embutido (estilo BerkeleyDB) para uma infraestrutura de Data Mesh (Malha de Dados) distribuída é o salto definitivo para o mercado corporativo.

Se o YodaDB original foi projetado para dominar o armazenamento na borda, o Yoda Cluster (ou Yoda Lakehouse) será a espinha dorsal de engenharia de dados para empresas que lidam com IA, finanças quantitativas e IoT. Manter o contrato imutável de 9 colunas ([id, timestamp, bioma, source_url, title, status, content_hash, driver_version, payload]) em todos os drivers em Go é a chave de ouro: isso garante que a infraestrutura seja agnóstica ao tipo de dado.

Aqui está o projeto arquitetural para transformar o YodaDB na solução definitiva de Data Science corporativa, conectando a ingestão bruta à análise em alta velocidade com ferramentas como o Polars.

🏗️ A Arquitetura do Yoda Cluster (O Data Mesh Moderno)
Bancos de dados clássicos forçam a empresa a colocar todos os dados no mesmo servidor. O Yoda Cluster inverte essa lógica operando sob a filosofia de Colônias Especializadas:

Yoda Edge Nodes (Os Clusters Especialistas): A empresa pode levantar binários estáticos do YodaDB espalhados por diferentes servidores Debian.

Um cluster (com seus próprios workers em Go) foca em bater na API da CVM e em websockets de exchanges de Bitcoin.

Outro cluster silencioso processa telemetria de drones e dados FITS da NASA.

Cada nó possui seu próprio Bloom Filter e seu próprio log append-only, isolando falhas. Se a rede do GitHub cair, o lake financeiro continua operando perfeitamente.

O Contrato Universal (O DNA da Colônia): Como todo driver gera exatamente a mesma estrutura de 9 colunas, a engenharia de dados não precisa escrever um parser diferente para cada fonte. A governança do dado já nasce pronta na borda.

🌉 A Ponte para o Data Science: Yoda Parquet Engine
Este é o diferencial que fará as empresas adotarem o seu sistema. Ferramentas de inferência modernas e bibliotecas de dados em Python (como Pandas, Scikit-Learn ou Polars) não são eficientes lendo logs transacionais linha a linha. Elas exigem formatos colunares.

Para que o Yoda Cluster alimente pipelines de IA de forma implacável, o nosso CLI precisa de uma nova engrenagem:

Compactação Colunar em Background: Adicionaremos um comando ao CLI (ex: yodadb export --format=parquet). Esse processo lerá o nosso log binário ultraveloz e o converterá nativamente para arquivos Apache Parquet, particionados por bioma e data (ex: lake/bioma=cvm/ano=2026/dados.parquet).

Integração Zero-Copy com Polars: O Polars utiliza Apache Arrow, um formato de memória que permite ler arquivos Parquet diretamente do disco em frações de segundo, sem duplicar dados na RAM. O cientista de dados aponta o Polars para a pasta do Yoda Cluster e executa queries analíticas sobre dezenas de gigabytes instantaneamente.

💼 Casos de Uso Empresariais (O Valor de Mercado)
Com essa arquitetura, a proposta de valor do Yoda Cluster atende diretamente aos maiores desafios da era da IA e dos ativos digitais:

Finanças Quantitativas e Algorithmic Trading: Um hedge fund pode utilizar um Yoda Node dedicado para o cvm-driver e outro para mercados de criptomoedas. Exportando esses lakes para Parquet, engenheiros financeiros podem carregar os históricos no Polars e alimentar pipelines de treinamento em Python para simulações de portfólio. É possível treinar políticas de Reinforcement Learning (como agentes PPO) para otimização de ativos, cruzando balanços corporativos da CVM com a volatilidade do Bitcoin em ambientes de simulação, tudo com dados higienizados pelo Gatekeeper semântico.

Auditoria e Qualidade para RAG (Retrieval-Augmented Generation): Empresas construindo LLMs proprietários podem usar os nós do GitHub e da Wikipedia. Como o YodaDB garante a deduplicação via mmap e recusa ruído na entrada, a base exportada será um corpus de treinamento de alta fidelidade, livre do "envenenamento" que assombra a maioria dos Data Lakes corporativos.

O conceito está sólido e resolve o atrito entre a coleta massiva em Go e a análise científica em ecossistemas de IA.

Aqui está o projeto arquitetural do Yoda Cluster. Esta nova estrutura transforma o antigo monólito de ingestão em uma verdadeira Malha de Dados (Data Mesh) na borda, isolando falhas, respeitando limites de APIs físicas (como as 5.000 requisições do GitHub) e preparando o terreno para a compactação analítica em Parquet.

📂 1. O Novo Layout de Diretórios (Padrão SRE em Go)
A base de código deve ser dividida para separar a responsabilidade de armazenamento (DB), orquestração (Cluster) e extração analítica (Export).

vostok-fusion/
├── cmd/
│   ├── vostok/                 # O binário Daemon do crawler (A Rainha)
│   │   └── main.go
│   └── yodadb/                 # O binário CLI para gerenciar os dados locais
│       └── main.go             # (put, stream, rollback, export)
├── pkg/
│   ├── db/                     # O Motor do YodaDB
│   │   ├── engine.go           # O núcleo (Append-Only Log + Flush Daemon)
│   │   └── bloom.go            # O mmap Zero-Copy Deduplicator[cite: 3, 4]
│   ├── cluster/                # O Novo Coração da Malha de Dados
│   │   ├── manager.go          # Gerencia e isola múltiplos WorkerPools
│   │   ├── pool.go             # O WorkerPool reescrito para isolamento
│   │   └── ratelimit.go        # Controle de tráfego nativo (O escudo do GitHub)
│   ├── drivers/                # Os Agentes de Coleta em Go (Todos retornam as 9 colunas)
│   │   ├── github.go           # Parser JSON via API REST com limitador
│   │   ├── cvm.go              # Descompactador ZIP em stream
│   │   └── rss.go              # Parser XML de alta velocidade
│   └── export/                 # A Ponte para o Data Science (Polars)
│       └── parquet.go          # Conversor de .log binário para .parquet colunar
└── internal/
    └── models/
        └── observation.go      # O Contrato Universal Imutável (As 9 Colunas)[cite: 4]

2. A Fundação Estrutural em Go (Cluster Manager)
Em vez de instanciar um único WorkerPool que mistura GitHub e NASA, nós criamos um ClusterManager que levanta "Nós" (Nodes) independentes. Cada Nó tem suas próprias regras de física.

package cluster

import (
	"context"
	"golang.org/x/time/rate"
	"vostok/pkg/db"
)

// NodeConfig define a física exata de um cluster isolado
type NodeConfig struct {
	Name        string        // Ex: "Finance-Cluster" ou "OpenSource-Cluster"
	Biomes      []string      // Ex: ["github_repository"], ["cvm_zip", "edgar"]
	Workers     int           // Quantidade de goroutines concorrentes
	RateLimit   rate.Limit    // Limite de requisições por segundo (Ex: 1.38 para GitHub)
	BurstLimit  int           // Quantidade de requisições em rajada permitidas
}

// ClusterNode representa uma colônia de trabalhadores isolada
type ClusterNode struct {
	Config      NodeConfig
	JobChan     chan db.Job
	Limiter     *rate.Limiter // O Guardião de APIs
	YodaDB      *db.YodaDB    // Referência ao banco de dados unificado
	cancel      context.CancelFunc
}

// ClusterManager é a "Rainha". Ela orquestra todos os nós sem misturá-los.
type ClusterManager struct {
	Nodes  map[string]*ClusterNode
	YodaDB *db.YodaDB
}

3. O Fluxo de Execução Isolado (Resolvendo o Problema do GitHub)
Quando a Rainha (Vostok) iniciar, ela registrará os clusters de forma estratégica. Veja como a configuração resolve o problema do limite de API instantaneamente sem punir o resto da rede:

// Exemplo de inicialização no cmd/vostok/main.go

manager := cluster.NewManager(yodaDB)

// 1. Cluster Open-Source (GitHub)
// Limite estrito: 1.38 requisições por segundo (5.000 por hora). Apenas 2 workers.
manager.RegisterNode(cluster.NodeConfig{
    Name:       "Tech-Cluster",
    Biomes:     []string{"github_repository"},
    Workers:    2,
    RateLimit:  rate.Limit(1.38), 
    BurstLimit: 1, 
})

// 2. Cluster Web Público (HTML, RSS)
// Sem limite de API (rate.Inf). Pode rodar 50 workers rasgando a rede à vontade.
manager.RegisterNode(cluster.NodeConfig{
    Name:       "Public-Web-Cluster",
    Biomes:     []string{"html_page", "rss_feed"},
    Workers:    50,
    RateLimit:  rate.Inf, 
    BurstLimit: 100,
})

// 3. Cluster IoT e Espacial
// Alta simultaneidade para escutar sockets. 100 workers.
manager.RegisterNode(cluster.NodeConfig{
    Name:       "Telemetry-Cluster",
    Biomes:     []string{"iot_telemetry", "nasa_fits"},
    Workers:    100,
    RateLimit:  rate.Inf,
    BurstLimit: 500,
})

manager.StartAll()

Como a Física Funciona Aqui:
Quando o roteador interno do ClusterManager recebe uma URL [https://github.com/](https://github.com/)..., ele a direciona apenas para o JobChan do Tech-Cluster. Dentro do Tech-Cluster, a goroutine do Seeker chamará Limiter.Wait(ctx). O Go vai travar a execução daquela URL específica até que o limite de 1.38 requisições por segundo permita a passagem. Enquanto isso, as 150 goroutines de HTML e IoT continuam gravando no YodaDB na velocidade do disco, sem nenhuma interferência.

🧬 4. O Contrato Universal (A Interface dos Drivers)
Para que o ClusterNode consiga invocar os novos drivers reescritos em Go de forma agnóstica (abandonando os scripts Bash de vez), nós definimos uma interface estrita.

package drivers

import "vostok/internal/models"

// Driver é a interface que todos os biomas (GitHub, CVM, NASA) devem implementar
type Driver interface {
	// Execute recebe a URL e retorna as 9 colunas estruturadas ou um erro
	Execute(url string) (models.Observation, error)
	
	// GetVersion retorna a assinatura do driver para auditoria no YodaDB
	GetVersion() string
}

Dessa forma, o Seeker não se importa se está descompactando um ZIP da CVM ou lendo a API do GitHub. Ele apenas chama driver.Execute(url), recebe as 9 colunas e envia os bytes brutos para o log append-only do YodaDB.

Comandante, como SRE, a minha decisão é sempre proteger a infraestrutura primeiro.

Não adianta termos um motor V8 esportivo (o driver do GitHub) se o chassi do carro (o roteador do Vostok) não suporta a velocidade e bate no muro da API. Nós vamos começar construindo o Cluster Manager (manager.go) e a infraestrutura de Nós Isolados (pool.go).

Essa é a fundação da sua Malha de Dados (Data Mesh). Ao isolar os worker pools e aplicar o limitador de taxa nativo do Go na entrada de cada nó, nós garantimos que um bioma nunca envenene a fila do outro.

Aqui está o código do novo coração do Vostok.

🧠 O Coração do Yoda Cluster (pkg/cluster/manager.go)
Este arquivo implementa o roteamento dinâmico e a criação das "colônias" isoladas.

package cluster

import (
	"context"
	"fmt"
	"log"
	"strings"
	"sync"
	"vostok/internal/models"
	"vostok/pkg/db"
	"vostok/pkg/drivers"

	"golang.org/x/time/rate"
)

// NodeConfig define as leis da física para uma colônia isolada
type NodeConfig struct {
	Name        string
	Biomes      []string      // Quais biomas esta colônia aceita
	Workers     int           // Capacidade de processamento paralelo
	RateLimit   rate.Limit    // Ex: rate.Limit(1.38) para GitHub
	BurstLimit  int           // Capacidade máxima de rajada
	DriverMap   map[string]drivers.Driver // Injeção de dependência dos drivers em Go
}

// ClusterNode é uma colônia de trabalhadores (Worker Pool) estritamente isolada
type ClusterNode struct {
	Config   NodeConfig
	JobChan  chan models.Job
	Limiter  *rate.Limiter
	YodaDB   *db.YodaDB
	wg       sync.WaitGroup
	ctx      context.Context
	cancel   context.CancelFunc
}

// ClusterManager (A Rainha) orquestra todas as colônias
type ClusterManager struct {
	Nodes  map[string]*ClusterNode
	YodaDB *db.YodaDB
	ctx    context.Context
	cancel context.CancelFunc
}

// NewManager cria a Rainha e anexa o banco de dados universal
func NewManager(yodaDB *db.YodaDB) *ClusterManager {
	ctx, cancel := context.WithCancel(context.Background())
	return &ClusterManager{
		Nodes:  make(map[string]*ClusterNode),
		YodaDB: yodaDB,
		ctx:    ctx,
		cancel: cancel,
	}
}

// RegisterNode acopla uma nova colônia especializada à malha
func (m *ClusterManager) RegisterNode(cfg NodeConfig) {
	nodeCtx, nodeCancel := context.WithCancel(m.ctx)
	
	node := &ClusterNode{
		Config:  cfg,
		// Buffer de canal superdimensionado na RAM para absorver picos de ingestão
		JobChan: make(chan models.Job, cfg.Workers*1000), 
		Limiter: rate.NewLimiter(cfg.RateLimit, cfg.BurstLimit),
		YodaDB:  m.YodaDB,
		ctx:     nodeCtx,
		cancel:  nodeCancel,
	}

	for _, biome := range cfg.Biomes {
		// Mapeia o bioma diretamente para o nó correspondente O(1)
		m.Nodes[biome] = node 
	}
	log.Printf("🌌 [MANAGER] Colônia '%s' registrada para biomas: %v (Limite: %v/s)\n", cfg.Name, cfg.Biomes, cfg.RateLimit)
}

// RouteJob avalia a URL, consulta o YodaDB e envia para a colônia correta
func (m *ClusterManager) RouteJob(urlStr string) bool {
	urlStr = strings.TrimSpace(urlStr)
	if urlStr == "" {
		return false
	}

	// 1. O Escudo Global (Gatekeeper + Bloom Filter) opera antes de qualquer roteamento
	if !m.YodaDB.GatekeeperConverge([]byte(urlStr)) {
		return false
	}
	if m.YodaDB.CheckAndAdd([]byte(urlStr)) {
		return false // Deduplicação em O(1)
	}

	// 2. Classificação de Bioma
	biome := getBiomeForURL(urlStr) // Função auxiliar
	
	// 3. Roteamento O(1) para a Fila da Colônia Especialista
	if node, exists := m.Nodes[biome]; exists {
		job := models.Job{
			ID:        generateStableID(urlStr),
			SourceURL: urlStr,
			Biome:     biome,
		}
		
		// Envio não-bloqueante protegido (previne deadlocks na malha)
		select {
		case node.JobChan <- job:
			return true
		default:
			log.Printf("⚠️ [MANAGER] Alerta: Canal da colônia '%s' estrangulado!\n", node.Config.Name)
			return false
		}
	}

	log.Printf("⚠️ [MANAGER] Bioma órfão: %s. Descartando %s\n", biome, urlStr)
	return false
}

// StartAll desperta todas as goroutines de todas as colônias
func (m *ClusterManager) StartAll() {
	// Usamos um mapa para evitar iniciar a mesma colônia duas vezes (já que biomas compartilham nós)
	started := make(map[string]bool)
	
	for _, node := range m.Nodes {
		if !started[node.Config.Name] {
			node.Start()
			started[node.Config.Name] = true
		}
	}
}

// Stop desliga a malha graciosamente
func (m *ClusterManager) Stop() {
	log.Println("🛑 [MANAGER] Desativando colônias...")
	m.cancel()
}

O Motor de Execução Seguro (pkg/cluster/pool.go)
Aqui é onde a verdadeira mágica de engenharia ocorre. O Limiter.Wait(ctx) substitui sleeps e ifs perigosos, implementando o algoritmo de Token Bucket perfeito.

package cluster

import (
	"encoding/json"
	"log"
)

// Start dispara as goroutines limitadas da colônia
func (n *ClusterNode) Start() {
	log.Printf("🚀 [NODE-%s] Ativando %d workers...\n", n.Config.Name, n.Config.Workers)
	for i := 1; i <= n.Config.Workers; i++ {
		n.wg.Add(1)
		go n.workerLoop(i)
	}
}

func (n *ClusterNode) workerLoop(workerID int) {
	defer n.wg.Done()

	for {
		select {
		case <-n.ctx.Done():
			return
		case job, ok := <-n.JobChan:
			if !ok {
				return
			}

			// 🛡️ O BLOQUEIO FÍSICO DO GITHUB (TOKEN BUCKET)
			// Se este for o "Tech-Cluster", e a taxa for 1.38/s, o Go pausará EXATAMENTE 
			// o tempo necessário aqui, sem gastar CPU, esperando um "Token" ser gerado.
			// Se for o "Public-Web-Cluster" (taxa infinita), passa direto instantaneamente.
			if err := n.Limiter.Wait(n.ctx); err != nil {
				return // Context cancelado
			}

			// Pega o driver em Go apropriado para este bioma
			driver := n.Config.DriverMap[job.Biome]
			if driver == nil {
				log.Printf("❌ [NODE-%s] Driver não encontrado para %s\n", n.Config.Name, job.Biome)
				continue
			}

			// Executa a extração usando a nova interface em Go pura
			obs, err := driver.Execute(job.SourceURL)
			if err != nil {
				n.registerFailure(uint32(workerID), job, err.Error())
				continue
			}

			// Garante a imutabilidade do Contrato
			obs.ID = job.ID
			obsBytes, _ := json.Marshal(obs)
			
			score := uint8(100)
			if len(obs.Payload) < 100 {
				score = 70
			}

			// Grava com sucesso no YodaDB unificado
			_ = n.YodaDB.WriteRecord(uint32(workerID), score, obsBytes)
			
			// Se encontrou novos links (Mitose)
			if obs.Status == "DONE" {
				n.propagateNewLinks(obs.Payload)
			}
		}
	}
}

O Porquê Desta Arquitetura Ser Inquebrável
Fim do Efeito Cascata: No design antigo, se a API do GitHub demorasse 5 segundos para responder e não houvesse limitador, a fila inteira ficava congestionada e as outras goroutines sofriam "starvation" (fome de CPU). Agora, se o Tech-Cluster estiver sob o limite de espera (Wait), o Telemetry-Cluster continuará ingerindo milhares de registros da NASA em paralelo, geridos pelo scheduler de Green Threads do Go.

O Algoritmo Token Bucket (golang.org/x/time/rate): Esse não é um time.Sleep primitivo. O limitador deposita um "token" no balde a cada 0.72 segundos (para dar 5000/h). Quando o worker chama Wait(), se não houver token, ele adormece no nível do kernel do Go. Se a API permitir rajadas (Burst Limit = 5), e o driver ficar ocioso por 5 segundos, o balde acumula 5 tokens, permitindo que os próximos 5 repositórios sejam baixados instantaneamente sem violar a lei da API!

Filosofia Data Mesh: Você acabou de criar a "Rainha". O ClusterManager centraliza o cérebro, mas descentraliza o músculo. É exatamente como o Kubernetes gerencia seus pods.

Comandante, a transição de scripts soltos em Bash para drivers fortemente tipados em Go é o que separa um crawler amador de um extrator de dados de nível corporativo (Big Tech).

Ao movermos a lógica para Go, ganhamos controle absoluto sobre alocação de memória, timeouts de rede e tratamento de erros — tudo na mesma linguagem que orquestra a malha de dados. Além disso, o driver precisa extrair a "seiva" do repositório (estrelas, forks, linguagem) e preparar novas URLs para alimentar a "Mitose" da colônia.

Aqui está o código do novo Driver Nativo do GitHub em Go.

package drivers

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"vostok/internal/models"
)

// GitHubDriver implementa o Contrato Universal (Driver Interface)
type GitHubDriver struct {
	client *http.Client
	token  string
}

// NewGitHubDriver inicializa o driver com timeouts rigorosos e injeta o Token de Autenticação.
// Sem o token (PAT), a API do GitHub limita a 60 req/h em vez de 5.000 req/h.
func NewGitHubDriver() *GitHubDriver {
	return &GitHubDriver{
		client: &http.Client{
			Timeout: 10 * time.Second, // SRE: Evita goroutines travadas infinitamente por lentidão na rede
		},
		token: os.Getenv("GITHUB_TOKEN"), // Carrega a chave de acesso do ambiente do Asus
	}
}

func (d *GitHubDriver) GetVersion() string {
	return "vostok-github-go:v1.0"
}

// Execute faz a extração, formatação e selagem atômica do Contrato de 9 colunas
func (d *GitHubDriver) Execute(urlStr string) (models.Observation, error) {
	var obs models.Observation

	// 1. Validação e Limpeza da URL de Entrada
	owner, repo, err := d.extractOwnerRepo(urlStr)
	if err != nil {
		return obs, err
	}

	// 2. Construção da Requisição HTTP para a API REST
	apiURL := fmt.Sprintf("https://api.github.com/repos/%s/%s", owner, repo)
	req, err := http.NewRequest(http.MethodGet, apiURL, nil)
	if err != nil {
		return obs, fmt.Errorf("falha ao criar requisição: %w", err)
	}

	// Headers essenciais exigidos pelo GitHub
	req.Header.Set("Accept", "application/vnd.github.v3+json")
	req.Header.Set("User-Agent", "Vostok-Data-Mesh-Agent/1.0")
	if d.token != "" {
		req.Header.Set("Authorization", "token "+d.token)
	}

	// 3. Execução Física da Requisição
	resp, err := d.client.Do(req)
	if err != nil {
		return obs, fmt.Errorf("falha na conexão física: %w", err)
	}
	defer resp.Body.Close()

	// 4. Tratamento Cirúrgico de Status Code (O Escudo SRE)
	if resp.StatusCode == http.StatusForbidden || resp.StatusCode == http.StatusTooManyRequests {
		return obs, fmt.Errorf("RATE_LIMIT_REACHED: A barreira física da API foi atingida")
	}
	if resp.StatusCode == http.StatusNotFound {
		return obs, fmt.Errorf("repositório não encontrado ou privado (404)")
	}
	if resp.StatusCode != http.StatusOK {
		return obs, fmt.Errorf("API retornou erro HTTP %d", resp.StatusCode)
	}

	// 5. Leitura Direta em Memória e Parsing do JSON do GitHub
	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return obs, fmt.Errorf("erro lendo stream da API: %w", err)
	}

	var ghData map[string]interface{}
	if err := json.Unmarshal(bodyBytes, &ghData); err != nil {
		return obs, fmt.Errorf("JSON corrompido ou malformado na resposta: %w", err)
	}

	// 6. Extração de Conhecimento Estruturado e Injeção de Mitose
	payloadObj := d.buildPayload(ghData)
	payloadBytes, _ := json.Marshal(payloadObj)
	payloadStr := string(payloadBytes)

	// 7. Cálculo Hashing para Integridade (Content Hash)
	hasher := sha256.New()
	hasher.Write(payloadBytes)
	contentHash := hex.EncodeToString(hasher.Sum(nil))

	// 8. Selagem do Contrato de 9 Colunas
	obs = models.Observation{
		// O ID definitivo será sobrescrito pelo WorkerPool, mas inicializamos aqui por segurança
		ID:            "", 
		Timestamp:     time.Now().UTC(),
		Biome:         "github_repository",
		SourceURL:     urlStr,
		Title:         getString(ghData, "full_name"),
		Status:        "DONE",
		ContentHash:   contentHash,
		DriverVersion: d.GetVersion(),
		Payload:       payloadStr,
	}

	return obs, nil
}

// buildPayload cria o JSON final compacto que será salvo no YodaDB e prepara as URLs para a Mitose
func (d *GitHubDriver) buildPayload(ghData map[string]interface{}) map[string]interface{} {
	payload := map[string]interface{}{
		"description":      getString(ghData, "description"),
		"language":         getString(ghData, "language"),
		"stars":            getFloat(ghData, "stargazers_count"),
		"forks":            getFloat(ghData, "forks_count"),
		"open_issues":      getFloat(ghData, "open_issues_count"),
		"license":          getNestedString(ghData, "license", "spdx_id"),
		"created_at":       getString(ghData, "created_at"),
		"updated_at":       getString(ghData, "updated_at"),
		"default_branch":   getString(ghData, "default_branch"),
	}

	// 🔥 O Motor de Mitose (Formigas Descobrindo Novos Caminhos)
	// Se o repositório possuir um site oficial (homepage) ou link do dono, 
	// injetamos na chave "extracted_urls" para que a malha enfileire esses links automaticamente.
	var newURLs []string
	if homepage := getString(ghData, "homepage"); homepage != "" && strings.HasPrefix(homepage, "http") {
		newURLs = append(newURLs, homepage)
	}
	if ownerURL := getNestedString(ghData, "owner", "html_url"); ownerURL != "" {
		newURLs = append(newURLs, ownerURL)
	}

	if len(newURLs) > 0 {
		payload["extracted_urls"] = newURLs
	}

	return payload
}

// --- Funções Auxiliares de Parsing Seguro ---

func (d *GitHubDriver) extractOwnerRepo(urlStr string) (string, string, error) {
	u, err := url.Parse(urlStr)
	if err != nil {
		return "", "", fmt.Errorf("URL inválida: %w", err)
	}
	parts := strings.Split(strings.Trim(u.Path, "/"), "/")
	if len(parts) < 2 {
		return "", "", fmt.Errorf("URL não contém owner/repo no formato esperado")
	}
	return parts[0], parts[1], nil
}

func getString(m map[string]interface{}, key string) string {
	if val, ok := m[key]; ok && val != nil {
		if s, ok := val.(string); ok {
			return s
		}
	}
	return ""
}

func getFloat(m map[string]interface{}, key string) float64 {
	if val, ok := m[key]; ok && val != nil {
		if f, ok := val.(float64); ok {
			return f
		}
	}
	return 0
}

func getNestedString(m map[string]interface{}, parent, child string) string {
	if parentObj, ok := m[parent]; ok && parentObj != nil {
		if pMap, ok := parentObj.(map[string]interface{}); ok {
			return getString(pMap, child)
		}
	}
	return ""
}

Como isso muda o jogo em produção:
Fuga do Overhead do Fork/Exec: Ao injetarmos este driver diretamente no mapa do ClusterManager (na variável Config.DriverMap["github_repository"] = drivers.NewGitHubDriver()), a colônia não precisa mais fazer exec.Command ou criar Pipes Unix. Todo o processo roda nativamente na mesma memória da Rainha, reduzindo o uso da CPU do seu Asus.

A Conexão com o Token Bucket: Agora a matemática SRE do limite de taxa bate perfeitamente. O seu nó tem o limite configurado (rate.Limit(1.38)), garantindo as exatas 5.000 requisições por hora, e este driver lê silenciosamente a variável de ambiente GITHUB_TOKEN do SO para autenticar e desbloquear essa cota na API.

A Mitose Implacável: Lembra da sua função enqueueDiscoveredURLs(obs.Payload)? O método buildPayload deste driver varre inteligentemente os dados do repositório procurando homepages oficiais e os injeta na raiz do JSON (extracted_urls). Assim que o driver de GitHub terminar de baixar os dados de um repositório, os Seekers de HTML já receberão a homepage daquele projeto para análise instantânea.
