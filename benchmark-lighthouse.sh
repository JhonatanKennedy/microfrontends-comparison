#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
RUNS=5
RESULTS_DIR="reports/lighthouse"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_FILE="$RESULTS_DIR/lighthouse_benchmark_${TIMESTAMP}.md"
JSON_DIR="$RESULTS_DIR/json_${TIMESTAMP}"

# Diretórios dos projetos
MFE_RSBUILD_DIR="mf-module-federation"
MFE_SINGLE_SPA_DIR="mf-single-spa"

# Docker Compose
DOCKER_COMPOSE_FILE="docker-compose.yml"
DOCKER_COMPOSE_UP_WAIT=10  # segundos para aguardar containers subirem

# URLs dos microfrontends
MFE_RSBUILD_URL="http://localhost:9000"
MFE_SINGLE_SPA_URL="http://localhost:9000"

# Nomes para identificação
MFE_RSBUILD_NAME="Rsbuild (Module Federation)"
MFE_SINGLE_SPA_NAME="Single-SPA"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Lighthouse Benchmark Microfrontends${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Verificar e instalar lighthouse se necessário
if ! command -v lighthouse &> /dev/null; then
    echo -e "${YELLOW}Lighthouse não está instalado. Instalando...${NC}"
    
    # Verificar se npm está disponível
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}Erro: npm não está instalado${NC}"
        echo -e "${YELLOW}Instale Node.js e npm primeiro${NC}"
        exit 1
    fi
    
    # Instalar lighthouse globalmente
    npm install -g lighthouse
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erro ao instalar Lighthouse${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Lighthouse instalado com sucesso!${NC}\n"
else
    echo -e "${GREEN}Lighthouse já está instalado ($(lighthouse --version))${NC}\n"
fi

# Verificar se docker compose está disponível
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Erro: Docker não está instalado${NC}"
    exit 1
fi

# Verificar se diretórios existem
if [ ! -d "$MFE_RSBUILD_DIR" ]; then
    echo -e "${RED}Erro: Diretório $MFE_RSBUILD_DIR não encontrado${NC}"
    exit 1
fi

if [ ! -d "$MFE_SINGLE_SPA_DIR" ]; then
    echo -e "${RED}Erro: Diretório $MFE_SINGLE_SPA_DIR não encontrado${NC}"
    exit 1
fi

# Verificar se docker-compose.yml existe nos diretórios
if [ ! -f "$MFE_RSBUILD_DIR/$DOCKER_COMPOSE_FILE" ]; then
    echo -e "${RED}Erro: $DOCKER_COMPOSE_FILE não encontrado em $MFE_RSBUILD_DIR${NC}"
    exit 1
fi

if [ ! -f "$MFE_SINGLE_SPA_DIR/$DOCKER_COMPOSE_FILE" ]; then
    echo -e "${RED}Erro: $DOCKER_COMPOSE_FILE não encontrado em $MFE_SINGLE_SPA_DIR${NC}"
    exit 1
fi

# Criar diretórios
mkdir -p "$RESULTS_DIR"
mkdir -p "$JSON_DIR"

# Inicializar arquivo de resultados
cat > "$RESULT_FILE" << EOF
# Lighthouse Benchmark Microfrontends - $(date '+%Y-%m-%d %H:%M:%S')

## Configuração
- Número de execuções por URL: $RUNS
- Sistema: $(uname -s) $(uname -r)
- Node: $(node --version)
- Lighthouse: $(lighthouse --version)

**Métricas coletadas:**
- FCP (First Contentful Paint)
- LCP (Largest Contentful Paint)
- Performance Score

**Estatísticas:**
- Média, Desvio Padrão, Min, Max

---

EOF

# Função para subir containers
start_containers() {
    local project_dir=$1
    local project_name=$2
    
    echo -e "${YELLOW}Iniciando containers de $project_name...${NC}"
    cd "$project_dir"
    docker compose -f "$DOCKER_COMPOSE_FILE" up -d
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erro ao iniciar containers de $project_name${NC}"
        cd - > /dev/null
        exit 1
    fi
    
    cd - > /dev/null
    echo -e "${GREEN}Containers de $project_name iniciados!${NC}"
    echo -e "${YELLOW}Aguardando ${DOCKER_COMPOSE_UP_WAIT}s para containers estarem prontos...${NC}\n"
    sleep $DOCKER_COMPOSE_UP_WAIT
}

# Função para parar containers
stop_containers() {
    local project_dir=$1
    local project_name=$2
    
    echo -e "\n${YELLOW}Parando containers de $project_name...${NC}"
    cd "$project_dir"
    docker compose -f "$DOCKER_COMPOSE_FILE" down
    cd - > /dev/null
    echo -e "${GREEN}Containers de $project_name parados!${NC}\n"
}

# Função para calcular desvio padrão
calculate_std_dev() {
    local values=("$@")
    local n=${#values[@]}
    
    # Calcular média
    local sum=0
    for val in "${values[@]}"; do
        sum=$(echo "$sum + $val" | bc)
    done
    local mean=$(echo "scale=6; $sum / $n" | bc)
    
    # Calcular variância
    local variance_sum=0
    for val in "${values[@]}"; do
        local diff=$(echo "$val - $mean" | bc)
        local sq=$(echo "$diff * $diff" | bc)
        variance_sum=$(echo "$variance_sum + $sq" | bc)
    done
    local variance=$(echo "scale=6; $variance_sum / $n" | bc)
    
    # Calcular desvio padrão (raiz quadrada da variância)
    local std_dev=$(echo "scale=6; sqrt($variance)" | bc)
    
    echo "$std_dev"
}

# Função para extrair métricas do JSON do Lighthouse
extract_metrics() {
    local json_file=$1
    
    # Usar Node.js para extrair métricas (não precisa de jq)
    node -e "
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync('$json_file', 'utf8'));
    const fcp = data.audits['first-contentful-paint'].numericValue;
    const lcp = data.audits['largest-contentful-paint'].numericValue;
    const perf = data.categories.performance.score * 100;
    console.log(\`\${fcp}|\${lcp}|\${perf}\`);
    "
}

# Função para verificar se URL está acessível
check_url() {
    local url=$1
    if curl -s --head --request GET "$url" | grep "200\|301\|302" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Função para executar Lighthouse benchmark
run_lighthouse_benchmark() {
    local url=$1
    local name=$2
    
    echo -e "\n${GREEN}===== Benchmark: $name =====${NC}"
    echo -e "${YELLOW}URL: $url${NC}\n"
    
    # Verificar se URL está acessível
    if ! check_url "$url"; then
        echo -e "${RED}Erro: URL $url não está acessível${NC}"
        echo -e "${YELLOW}Certifique-se de que o servidor está rodando${NC}\n"
        return 1
    fi
    
    local fcp_values=()
    local lcp_values=()
    local perf_values=()
    
    local total_fcp=0
    local total_lcp=0
    local total_perf=0
    
    for i in $(seq 1 $RUNS); do
        echo -e "${YELLOW}Rodada $i/$RUNS - $name${NC}"
        
        local json_output="$JSON_DIR/${name// /_}_run${i}.json"
        
        # Executar Lighthouse
        echo -e "${BLUE}  Executando Lighthouse em $url...${NC}"
        
        LIGHTHOUSE_OUTPUT=$(lighthouse "$url" \
            --output=json \
            --output-path="$json_output" \
            --only-categories=performance \
            --chrome-flags="--headless --no-sandbox --disable-gpu" \
            2>&1)
        
        LIGHTHOUSE_EXIT_CODE=$?
        
        if [ $LIGHTHOUSE_EXIT_CODE -ne 0 ]; then
            echo -e "${RED}Erro ao executar Lighthouse na rodada $i (Exit code: $LIGHTHOUSE_EXIT_CODE)${NC}"
            echo -e "${YELLOW}Output:${NC}"
            echo "$LIGHTHOUSE_OUTPUT" | grep -v "WARNING" | tail -20
            continue
        fi
        
        # Verificar se o arquivo JSON foi criado
        if [ ! -f "$json_output" ]; then
            echo -e "${RED}Erro: Arquivo JSON não foi criado${NC}"
            echo -e "${YELLOW}Output do Lighthouse:${NC}"
            echo "$LIGHTHOUSE_OUTPUT" | grep -v "WARNING" | tail -20
            continue
        fi
        
        # Extrair métricas
        METRICS=$(extract_metrics "$json_output")
        FCP=$(echo "$METRICS" | cut -d'|' -f1)
        LCP=$(echo "$METRICS" | cut -d'|' -f2)
        PERF=$(echo "$METRICS" | cut -d'|' -f3)
        
        # Converter para segundos para exibição
        FCP_SEC=$(echo "scale=3; $FCP / 1000" | bc)
        LCP_SEC=$(echo "scale=3; $LCP / 1000" | bc)
        
        fcp_values+=($FCP)
        lcp_values+=($LCP)
        perf_values+=($PERF)
        
        total_fcp=$(echo "$total_fcp + $FCP" | bc)
        total_lcp=$(echo "$total_lcp + $LCP" | bc)
        total_perf=$(echo "$total_perf + $PERF" | bc)
        
        echo -e "  FCP: ${FCP_SEC}s | LCP: ${LCP_SEC}s | Performance: ${PERF}"
        
        sleep 3
    done
    
    # Calcular médias
    local avg_fcp=$(echo "scale=3; $total_fcp / $RUNS / 1000" | bc)
    local avg_lcp=$(echo "scale=3; $total_lcp / $RUNS / 1000" | bc)
    local avg_perf=$(echo "scale=1; $total_perf / $RUNS" | bc)
    
    # Calcular desvio padrão
    local std_fcp=$(calculate_std_dev "${fcp_values[@]}")
    local std_lcp=$(calculate_std_dev "${lcp_values[@]}")
    local std_perf=$(calculate_std_dev "${perf_values[@]}")
    
    # Converter desvio padrão para segundos
    std_fcp=$(echo "scale=3; $std_fcp / 1000" | bc)
    std_lcp=$(echo "scale=3; $std_lcp / 1000" | bc)
    std_perf=$(echo "scale=1; $std_perf" | bc)
    
    # Min e Max
    local min_fcp=$(printf '%s\n' "${fcp_values[@]}" | sort -n | head -1)
    local max_fcp=$(printf '%s\n' "${fcp_values[@]}" | sort -n | tail -1)
    local min_lcp=$(printf '%s\n' "${lcp_values[@]}" | sort -n | head -1)
    local max_lcp=$(printf '%s\n' "${lcp_values[@]}" | sort -n | tail -1)
    
    min_fcp=$(echo "scale=3; $min_fcp / 1000" | bc)
    max_fcp=$(echo "scale=3; $max_fcp / 1000" | bc)
    min_lcp=$(echo "scale=3; $min_lcp / 1000" | bc)
    max_lcp=$(echo "scale=3; $max_lcp / 1000" | bc)
    
    # Escrever resultados
    cat >> "$RESULT_FILE" << EOF
## $name

**URL:** \`$url\`

| Métrica | Média | Desvio Padrão | Min | Max |
|---------|-------|---------------|-----|-----|
| **FCP** | ${avg_fcp}s | ${std_fcp}s | ${min_fcp}s | ${max_fcp}s |
| **LCP** | ${avg_lcp}s | ${std_lcp}s | ${min_lcp}s | ${max_lcp}s |
| **Performance Score** | ${avg_perf} | ${std_perf} | - | - |

### Valores individuais (FCP / LCP em segundos)
EOF
    
    for i in $(seq 0 $((${#fcp_values[@]} - 1))); do
        fcp_s=$(echo "scale=3; ${fcp_values[$i]} / 1000" | bc)
        lcp_s=$(echo "scale=3; ${lcp_values[$i]} / 1000" | bc)
        echo "- Run $((i+1)): FCP ${fcp_s}s / LCP ${lcp_s}s / Score ${perf_values[$i]}" >> "$RESULT_FILE"
    done
    
    echo -e "\n---\n" >> "$RESULT_FILE"
    
    # Exibir resumo no terminal
    echo -e "\n${GREEN}Resultados $name:${NC}"
    echo -e "  FCP: ${avg_fcp}s (±${std_fcp}s)"
    echo -e "  LCP: ${avg_lcp}s (±${std_lcp}s)"
    echo -e "  Performance Score: ${avg_perf} (±${std_perf})"
}

# Executar benchmarks
echo -e "${BLUE}Iniciando benchmark do Module Federation (Rsbuild)...${NC}\n"
start_containers "$MFE_RSBUILD_DIR" "$MFE_RSBUILD_NAME"
run_lighthouse_benchmark "$MFE_RSBUILD_URL" "$MFE_RSBUILD_NAME"
stop_containers "$MFE_RSBUILD_DIR" "$MFE_RSBUILD_NAME"

echo -e "${BLUE}Iniciando benchmark do Single-SPA...${NC}\n"
start_containers "$MFE_SINGLE_SPA_DIR" "$MFE_SINGLE_SPA_NAME"
run_lighthouse_benchmark "$MFE_SINGLE_SPA_URL" "$MFE_SINGLE_SPA_NAME"
stop_containers "$MFE_SINGLE_SPA_DIR" "$MFE_SINGLE_SPA_NAME"

# Finalizar
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}  Benchmark Completo!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "\nResultados salvos em:"
echo -e "  ${GREEN}$RESULT_FILE${NC}"
echo -e "  ${GREEN}$JSON_DIR/${NC} (JSONs detalhados)\n"

# Exibir resumo
cat "$RESULT_FILE"