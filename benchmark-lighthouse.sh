#!/bin/bash

VERMELHO='\033[0;31m'
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
CIANO='\033[0;36m'
SEM_COR='\033[0m'

# Configuração baseada nas recomendações de Jain
EXECUCOES_AQUECIMENTO=3           # Execuções de aquecimento para estabilizar o sistema
EXECUCOES_MEDICAO=10              # Mínimo de 30 execuções para significância estatística (Jain, Capítulo 20)
NIVEL_CONFIANCA=95                # Intervalo de confiança de 95%
DELAY_ENTRE_EXECUCOES=5           # Segundos entre execuções para evitar interferência
TEMPO_ESPERA_CONTAINER=20         # Tempo de espera para estabilização do container

DIRETORIO_RESULTADOS="reports/lighthouse"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARQUIVO_RESULTADO="$DIRETORIO_RESULTADOS/lighthouse_benchmark_${TIMESTAMP}.md"
DIRETORIO_JSON="$DIRETORIO_RESULTADOS/json_${TIMESTAMP}"

DIRETORIO_MODULE_FEDERATION="mf-module-federation"
DIRETORIO_SINGLE_SPA="mf-single-spa"
ARQUIVO_DOCKER_COMPOSE="docker-compose.yml"

URL_MODULE_FEDERATION="http://localhost:9000"
URL_SINGLE_SPA="http://localhost:9000"
NOME_MODULE_FEDERATION="Rsbuild Module Federation"
NOME_SINGLE_SPA="Single SPA"

# Funções estatísticas baseadas na metodologia de Jain

calcular_media() {
    local valores=("$@")
    local soma=0
    local quantidade=${#valores[@]}
    
    for valor in "${valores[@]}"; do
        soma=$(echo "$soma + $valor" | bc -l)
    done
    
    local resultado=$(echo "scale=6; $soma / $quantidade" | bc -l)
    if [[ $resultado =~ ^\. ]]; then
        resultado="0$resultado"
    fi
    echo "$resultado"
}

calcular_desvio_padrao() {
    local media=$1
    shift
    local valores=("$@")
    local quantidade=${#valores[@]}
    
    local soma_variancia=0
    for valor in "${valores[@]}"; do
        local diferenca=$(echo "$valor - $media" | bc -l)
        local quadrado=$(echo "$diferenca * $diferenca" | bc -l)
        soma_variancia=$(echo "$soma_variancia + $quadrado" | bc -l)
    done
    
    local variancia=$(echo "scale=6; $soma_variancia / ($quantidade - 1)" | bc -l)
    local resultado=$(echo "scale=6; sqrt($variancia)" | bc -l)
    if [[ $resultado =~ ^\. ]]; then
        resultado="0$resultado"
    fi
    echo "$resultado"
}

calcular_coeficiente_variacao() {
    local media=$1
    local desvio_padrao=$2
    
    if (( $(echo "$media == 0" | bc -l) )); then
        echo "0"
    else
        local resultado=$(echo "scale=4; ($desvio_padrao / $media) * 100" | bc -l)
        if [[ $resultado =~ ^\. ]]; then
            resultado="0$resultado"
        fi
        echo "$resultado"
    fi
}

calcular_intervalo_confianca() {
    local media=$1
    local desvio_padrao=$2
    local quantidade=$3
    local nivel_confianca=$4
    
    # Valor t para 95% de confiança (aproximado para n=30: 2.045, n=∞: 1.96)
    local valor_t="2.045"
    if [ $quantidade -ge 100 ]; then
        valor_t="1.96"
    fi
    
    local erro_padrao=$(echo "scale=6; $desvio_padrao / sqrt($quantidade)" | bc -l)
    local margem=$(echo "scale=6; $valor_t * $erro_padrao" | bc -l)
    
    if [[ $margem =~ ^\. ]]; then
        margem="0$margem"
    fi
    echo "$margem"
}

detectar_outliers_amplitude_interquartil() {
    local valores=("$@")
    local quantidade=${#valores[@]}
    
    # Ordenar valores
    IFS=$'\n' ordenados=($(sort -n <<<"${valores[*]}"))
    unset IFS
    
    # Calcular primeiro quartil e terceiro quartil
    local posicao_primeiro_quartil=$(echo "($quantidade + 1) * 0.25" | bc -l | xargs printf "%.0f")
    local posicao_terceiro_quartil=$(echo "($quantidade + 1) * 0.75" | bc -l | xargs printf "%.0f")
    
    local primeiro_quartil=${ordenados[$((posicao_primeiro_quartil - 1))]}
    local terceiro_quartil=${ordenados[$((posicao_terceiro_quartil - 1))]}
    local amplitude_interquartil=$(echo "$terceiro_quartil - $primeiro_quartil" | bc -l)
    
    local limite_inferior=$(echo "$primeiro_quartil - (1.5 * $amplitude_interquartil)" | bc -l)
    local limite_superior=$(echo "$terceiro_quartil + (1.5 * $amplitude_interquartil)" | bc -l)
    
    # Retornar valores que não são outliers
    local valores_limpos=()
    for valor in "${valores[@]}"; do
        if (( $(echo "$valor >= $limite_inferior && $valor <= $limite_superior" | bc -l) )); then
            valores_limpos+=($valor)
        fi
    done
    
    echo "${valores_limpos[@]}"
}

echo -e "${AZUL}================================================================${SEM_COR}"
echo -e "${AZUL}  Benchmark de Performance com Lighthouse${SEM_COR}"
echo -e "${AZUL}  Baseado na Metodologia Estatística de Raj Jain${SEM_COR}"
echo -e "${AZUL}================================================================${SEM_COR}\n"

# Verificar dependências
if ! command -v lighthouse &> /dev/null; then
    echo -e "${AMARELO}Instalando Lighthouse...${SEM_COR}"
    npm install -g lighthouse || exit 1
    echo -e "${VERDE}Lighthouse instalado com sucesso!${SEM_COR}\n"
fi

if ! command -v docker &> /dev/null; then
    echo -e "${VERMELHO}Erro: Docker não está instalado${SEM_COR}"
    exit 1
fi

# Obter versão do Lighthouse
VERSAO_LIGHTHOUSE=$(lighthouse --version 2>&1)

# Verificar diretórios
for diretorio in "$DIRETORIO_MODULE_FEDERATION" "$DIRETORIO_SINGLE_SPA"; do
    if [ ! -d "$diretorio" ]; then
        echo -e "${VERMELHO}Erro: Diretório $diretorio não encontrado${SEM_COR}"
        exit 1
    fi
done

mkdir -p "$DIRETORIO_RESULTADOS" "$DIRETORIO_JSON"

# Arrays para armazenar resultados para comparação
declare -A aplicacao_tempo_primeira_renderizacao_media aplicacao_tempo_primeira_renderizacao_intervalo_confianca aplicacao_tempo_primeira_renderizacao_coeficiente_variacao
declare -A aplicacao_tempo_maior_renderizacao_media aplicacao_tempo_maior_renderizacao_intervalo_confianca aplicacao_tempo_maior_renderizacao_coeficiente_variacao
declare -A aplicacao_pontuacao_performance_media aplicacao_pontuacao_performance_intervalo_confianca aplicacao_pontuacao_performance_coeficiente_variacao

# Documentar ambiente do sistema (Jain: Capítulo 2 - Caracterização do Sistema)
cat > "$ARQUIVO_RESULTADO" << EOF
# Relatório de Benchmark de Performance com Lighthouse
**Gerado em:** $(date '+%Y-%m-%d %H:%M:%S %Z')

## Design Experimental (Metodologia Raj Jain)

### Configuração Estatística
- **Execuções de aquecimento:** $EXECUCOES_AQUECIMENTO (excluídas da análise)
- **Execuções de medição:** $EXECUCOES_MEDICAO por aplicação
- **Nível de confiança:** ${NIVEL_CONFIANCA}%
- **Delay entre execuções:** ${DELAY_ENTRE_EXECUCOES}s
- **Detecção de outliers:** Método da Amplitude Interquartil (1.5 × Amplitude Interquartil)

### Ambiente do Sistema
- **Sistema Operacional:** $(uname -s) $(uname -r)
- **Arquitetura:** $(uname -m)
- **Node.js:** $(node --version)
- **Lighthouse:** $VERSAO_LIGHTHOUSE
- **Docker:** $(docker --version | head -n1)
- **Memória Disponível:** $(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "N/A") 
- **Processador:** $(lscpu 2>/dev/null | grep "Model name" | cut -d: -f2 | xargs || sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "N/A")
- **Núcleos do Processador:** $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "N/A")

### Métricas Coletadas
- **First Contentful Paint (Tempo da Primeira Renderização de Conteúdo):** Tempo até a primeira renderização de conteúdo
- **Largest Contentful Paint (Tempo da Maior Renderização de Conteúdo):** Tempo até a maior renderização de conteúdo
- **Performance Score (Pontuação de Performance):** Pontuação geral do Lighthouse (0-100)

### Análise Estatística
Para cada métrica, reportamos:
- **Média:** Valor médio
- **Desvio Padrão:** Medida de variabilidade
- **Coeficiente de Variação:** Desvio Padrão / Média × 100% (menor é melhor, menos de 10% é excelente)
- **Intervalo de Confiança ${NIVEL_CONFIANCA}%:** Faixa onde a média verdadeira provavelmente está
- **Mínimo/Máximo:** Faixa observada
- **Outliers Removidos:** Usando método da Amplitude Interquartil

---

EOF

iniciar_containers() {
    local diretorio_projeto=$1
    local nome_projeto=$2
    
    echo -e "${CIANO}┌─────────────────────────────────────────────┐${SEM_COR}"
    echo -e "${CIANO}│ Iniciando: $nome_projeto${SEM_COR}"
    echo -e "${CIANO}└─────────────────────────────────────────────┘${SEM_COR}"
    
    cd "$diretorio_projeto"
    docker compose -f "$ARQUIVO_DOCKER_COMPOSE" down &> /dev/null
    docker compose -f "$ARQUIVO_DOCKER_COMPOSE" up -d
    
    if [ $? -ne 0 ]; then
        echo -e "${VERMELHO}Erro ao iniciar containers${SEM_COR}"
        cd - > /dev/null
        exit 1
    fi
    
    cd - > /dev/null
    echo -e "${VERDE}✓ Containers iniciados${SEM_COR}"
    echo -e "${AMARELO}⏳ Aguardando ${TEMPO_ESPERA_CONTAINER}s para estabilização...${SEM_COR}"
    sleep $TEMPO_ESPERA_CONTAINER
}

parar_containers() {
    local diretorio_projeto=$1
    local nome_projeto=$2
    
    echo -e "${AMARELO}Parando containers...${SEM_COR}"
    cd "$diretorio_projeto"
    docker compose -f "$ARQUIVO_DOCKER_COMPOSE" down > /dev/null 2>&1
    cd - > /dev/null
    echo -e "${VERDE}✓ Containers parados${SEM_COR}\n"
}

extrair_metricas() {
    local arquivo_json=$1
    
    node -e "
    const fs = require('fs');
    try {
        const dados = JSON.parse(fs.readFileSync('$arquivo_json', 'utf8'));
        
        // Extrair First Contentful Paint (Tempo da Primeira Renderização de Conteúdo)
        let tempo_primeira_renderizacao = dados.audits['first-contentful-paint']?.numericValue || 0;
        
        // Extrair Largest Contentful Paint (Tempo da Maior Renderização de Conteúdo)
        let tempo_maior_renderizacao = dados.audits['largest-contentful-paint']?.numericValue || 0;
        
        // Extrair Performance Score (Pontuação de Performance)
        const pontuacao_performance = (dados.categories?.performance?.score || 0) * 100;
        
        console.log(\`\${tempo_primeira_renderizacao}|\${tempo_maior_renderizacao}|\${pontuacao_performance}\`);
        
        // Informação de debug (não interfere no parsing)
        if (tempo_primeira_renderizacao === 0) {
            console.error('AVISO: First Contentful Paint é 0 ou está faltando');
        }
    } catch (erro) {
        console.error('Erro ao fazer parsing do JSON:', erro.message);
        process.exit(1);
    }
    " 2>&1
}

verificar_url() {
    local url=$1
    local tentativas_maximas=5
    local tentativa=1
    
    echo -e "${AMARELO}Verificando acessibilidade da URL...${SEM_COR}"
    
    while [ $tentativa -le $tentativas_maximas ]; do
        if curl -s --head --request GET "$url" --max-time 10 | grep -q "200\|301\|302"; then
            echo -e "${VERDE}✓ URL está acessível${SEM_COR}"
            return 0
        fi
        
        echo -e "${AMARELO}Tentativa $tentativa/$tentativas_maximas falhou, tentando novamente...${SEM_COR}"
        sleep 3
        tentativa=$((tentativa + 1))
    done
    
    return 1
}

executar_benchmark_lighthouse() {
    local url=$1
    local nome=$2
    
    echo -e "\n${VERDE}═══════════════════════════════════════════════════${SEM_COR}"
    echo -e "${VERDE}  Executando Benchmark: $nome${SEM_COR}"
    echo -e "${VERDE}═══════════════════════════════════════════════════${SEM_COR}"
    echo -e "${AMARELO}URL: $url${SEM_COR}\n"
    
    if ! verificar_url "$url"; then
        echo -e "${VERMELHO}✗ Erro: URL não acessível após múltiplas tentativas${SEM_COR}\n"
        return 1
    fi
    
    local valores_tempo_primeira_renderizacao=()
    local valores_tempo_maior_renderizacao=()
    local valores_pontuacao_performance=()
    
    # Fase 1: Execuções de aquecimento (não incluídas na análise)
    echo -e "${CIANO}Fase 1: Execuções de Aquecimento (${EXECUCOES_AQUECIMENTO} execuções)${SEM_COR}"
    for indice in $(seq 1 $EXECUCOES_AQUECIMENTO); do
        echo -e "${AMARELO}  Aquecimento $indice/$EXECUCOES_AQUECIMENTO${SEM_COR}"
        
        local saida_json="$DIRETORIO_JSON/${nome// /_}_aquecimento${indice}.json"
        
        lighthouse "$url" \
            --output=json \
            --output-path="$saida_json" \
            --only-categories=performance \
            --chrome-flags="--headless --no-sandbox --disable-gpu --disable-dev-shm-usage --disable-software-rasterizer --disable-extensions" \
            --throttling-method=provided \
            --throttling.cpuSlowdownMultiplier=1 \
            --emulated-form-factor=desktop \
            --screenEmulation.disabled \
            --max-wait-for-load=60000 \
            --quiet > /dev/null 2>&1
        
        if [ -f "$saida_json" ]; then
            echo -e "${VERDE}    ✓ Execução de aquecimento completa${SEM_COR}"
        else
            echo -e "${AMARELO}    ⚠ Execução de aquecimento pode ter problemas${SEM_COR}"
        fi
        
        sleep $DELAY_ENTRE_EXECUCOES
    done
    echo -e "${VERDE}✓ Aquecimento completo${SEM_COR}\n"
    
    # Fase 2: Execuções de medição
    echo -e "${CIANO}Fase 2: Execuções de Medição (${EXECUCOES_MEDICAO} execuções)${SEM_COR}"
    for indice in $(seq 1 $EXECUCOES_MEDICAO); do
        printf "${AMARELO}  Execução %2d/%d${SEM_COR}" $indice $EXECUCOES_MEDICAO
        
        local saida_json="$DIRETORIO_JSON/${nome// /_}_execucao${indice}.json"
        
        lighthouse "$url" \
            --output=json \
            --output-path="$saida_json" \
            --only-categories=performance \
            --chrome-flags="--headless --no-sandbox --disable-gpu --disable-dev-shm-usage --disable-software-rasterizer --disable-extensions" \
            --throttling-method=provided \
            --throttling.cpuSlowdownMultiplier=1 \
            --emulated-form-factor=desktop \
            --screenEmulation.disabled \
            --max-wait-for-load=60000 \
            --quiet > /dev/null 2>&1
        
        if [ $? -ne 0 ] || [ ! -f "$saida_json" ]; then
            echo -e " ${VERMELHO}✗ Falhou${SEM_COR}"
            continue
        fi
        
        METRICAS=$(extrair_metricas "$saida_json")
        if [ $? -ne 0 ]; then
            echo -e " ${VERMELHO}✗ Falhou ao extrair métricas${SEM_COR}"
            continue
        fi
        
        TEMPO_PRIMEIRA_RENDERIZACAO=$(echo "$METRICAS" | cut -d'|' -f1)
        TEMPO_MAIOR_RENDERIZACAO=$(echo "$METRICAS" | cut -d'|' -f2)
        PONTUACAO_PERFORMANCE=$(echo "$METRICAS" | cut -d'|' -f3)
        
        # Validar métricas
        if [ -z "$TEMPO_PRIMEIRA_RENDERIZACAO" ] || [ "$TEMPO_PRIMEIRA_RENDERIZACAO" = "0" ]; then
            echo -e " ${AMARELO}⚠ First Contentful Paint é 0 ou vazio, pulando execução${SEM_COR}"
            continue
        fi
        
        valores_tempo_primeira_renderizacao+=($TEMPO_PRIMEIRA_RENDERIZACAO)
        valores_tempo_maior_renderizacao+=($TEMPO_MAIOR_RENDERIZACAO)
        valores_pontuacao_performance+=($PONTUACAO_PERFORMANCE)
        
        TEMPO_PRIMEIRA_RENDERIZACAO_SEGUNDOS=$(echo "scale=3; $TEMPO_PRIMEIRA_RENDERIZACAO / 1000" | bc -l)
        TEMPO_MAIOR_RENDERIZACAO_SEGUNDOS=$(echo "scale=3; $TEMPO_MAIOR_RENDERIZACAO / 1000" | bc -l)
        
        # Formatar saída para 3 casas decimais
        TEMPO_PRIMEIRA_RENDERIZACAO_SEGUNDOS_FORMATADO=$(LC_NUMERIC=C printf "%.3f" $TEMPO_PRIMEIRA_RENDERIZACAO_SEGUNDOS 2>/dev/null || echo "0.000")
        TEMPO_MAIOR_RENDERIZACAO_SEGUNDOS_FORMATADO=$(LC_NUMERIC=C printf "%.3f" $TEMPO_MAIOR_RENDERIZACAO_SEGUNDOS 2>/dev/null || echo "0.000")
        PONTUACAO_PERFORMANCE_FORMATADA=$(LC_NUMERIC=C printf "%.1f" $PONTUACAO_PERFORMANCE 2>/dev/null || echo "0.0")

        printf " - Primeira Renderização: ${TEMPO_PRIMEIRA_RENDERIZACAO_SEGUNDOS_FORMATADO}s | Maior Renderização: ${TEMPO_MAIOR_RENDERIZACAO_SEGUNDOS_FORMATADO}s | Pontuação: ${PONTUACAO_PERFORMANCE_FORMATADA}\n"
        
        sleep $DELAY_ENTRE_EXECUCOES
    done
    
    echo -e "\n${CIANO}Fase 3: Análise Estatística${SEM_COR}"
    
    # Verificar se temos medições válidas suficientes
    if [ ${#valores_tempo_primeira_renderizacao[@]} -lt 10 ]; then
        echo -e "${VERMELHO}✗ Medições válidas insuficientes (${#valores_tempo_primeira_renderizacao[@]} coletadas, mínimo 10 necessárias)${SEM_COR}"
        echo -e "${AMARELO}Por favor, verifique a saída do Lighthouse e tente novamente${SEM_COR}\n"
        return 1
    fi
    
    echo -e "${VERDE}✓ Coletadas ${#valores_tempo_primeira_renderizacao[@]} medições válidas${SEM_COR}"
    
    # Remover outliers usando método da Amplitude Interquartil
    local valores_tempo_primeira_renderizacao_limpos=($(detectar_outliers_amplitude_interquartil "${valores_tempo_primeira_renderizacao[@]}"))
    local valores_tempo_maior_renderizacao_limpos=($(detectar_outliers_amplitude_interquartil "${valores_tempo_maior_renderizacao[@]}"))
    local valores_pontuacao_performance_limpos=($(detectar_outliers_amplitude_interquartil "${valores_pontuacao_performance[@]}"))
    
    local outliers_primeira_renderizacao=$((${#valores_tempo_primeira_renderizacao[@]} - ${#valores_tempo_primeira_renderizacao_limpos[@]}))
    local outliers_maior_renderizacao=$((${#valores_tempo_maior_renderizacao[@]} - ${#valores_tempo_maior_renderizacao_limpos[@]}))
    local outliers_pontuacao=$((${#valores_pontuacao_performance[@]} - ${#valores_pontuacao_performance_limpos[@]}))
    
    echo -e "${AMARELO}  Outliers removidos: Primeira Renderização=$outliers_primeira_renderizacao, Maior Renderização=$outliers_maior_renderizacao, Pontuação=$outliers_pontuacao${SEM_COR}"
    
    # Calcular estatísticas
    local media_primeira_renderizacao=$(calcular_media "${valores_tempo_primeira_renderizacao_limpos[@]}")
    local media_maior_renderizacao=$(calcular_media "${valores_tempo_maior_renderizacao_limpos[@]}")
    local media_pontuacao=$(calcular_media "${valores_pontuacao_performance_limpos[@]}")
    
    local desvio_padrao_primeira_renderizacao=$(calcular_desvio_padrao "$media_primeira_renderizacao" "${valores_tempo_primeira_renderizacao_limpos[@]}")
    local desvio_padrao_maior_renderizacao=$(calcular_desvio_padrao "$media_maior_renderizacao" "${valores_tempo_maior_renderizacao_limpos[@]}")
    local desvio_padrao_pontuacao=$(calcular_desvio_padrao "$media_pontuacao" "${valores_pontuacao_performance_limpos[@]}")
    
    local coeficiente_variacao_primeira_renderizacao=$(calcular_coeficiente_variacao "$media_primeira_renderizacao" "$desvio_padrao_primeira_renderizacao")
    local coeficiente_variacao_maior_renderizacao=$(calcular_coeficiente_variacao "$media_maior_renderizacao" "$desvio_padrao_maior_renderizacao")
    local coeficiente_variacao_pontuacao=$(calcular_coeficiente_variacao "$media_pontuacao" "$desvio_padrao_pontuacao")
    
    local intervalo_confianca_primeira_renderizacao=$(calcular_intervalo_confianca "$media_primeira_renderizacao" "$desvio_padrao_primeira_renderizacao" "${#valores_tempo_primeira_renderizacao_limpos[@]}" "$NIVEL_CONFIANCA")
    local intervalo_confianca_maior_renderizacao=$(calcular_intervalo_confianca "$media_maior_renderizacao" "$desvio_padrao_maior_renderizacao" "${#valores_tempo_maior_renderizacao_limpos[@]}" "$NIVEL_CONFIANCA")
    local intervalo_confianca_pontuacao=$(calcular_intervalo_confianca "$media_pontuacao" "$desvio_padrao_pontuacao" "${#valores_pontuacao_performance_limpos[@]}" "$NIVEL_CONFIANCA")
    
    # Converter para segundos para exibição e armazenamento
    media_primeira_renderizacao_segundos=$(echo "scale=6; $media_primeira_renderizacao / 1000" | bc -l)
    media_maior_renderizacao_segundos=$(echo "scale=6; $media_maior_renderizacao / 1000" | bc -l)
    desvio_padrao_primeira_renderizacao_segundos=$(echo "scale=6; $desvio_padrao_primeira_renderizacao / 1000" | bc -l)
    desvio_padrao_maior_renderizacao_segundos=$(echo "scale=6; $desvio_padrao_maior_renderizacao / 1000" | bc -l)
    intervalo_confianca_primeira_renderizacao_segundos=$(echo "scale=6; $intervalo_confianca_primeira_renderizacao / 1000" | bc -l)
    intervalo_confianca_maior_renderizacao_segundos=$(echo "scale=6; $intervalo_confianca_maior_renderizacao / 1000" | bc -l)
    
    # Mínimo/Máximo (Em Milissegundos)
    local minimo_primeira_renderizacao=$(printf '%s\n' "${valores_tempo_primeira_renderizacao_limpos[@]}" | sort -n | head -1)
    local maximo_primeira_renderizacao=$(printf '%s\n' "${valores_tempo_primeira_renderizacao_limpos[@]}" | sort -n | tail -1)
    local minimo_maior_renderizacao=$(printf '%s\n' "${valores_tempo_maior_renderizacao_limpos[@]}" | sort -n | head -1)
    local maximo_maior_renderizacao=$(printf '%s\n' "${valores_tempo_maior_renderizacao_limpos[@]}" | sort -n | tail -1)
    local minimo_pontuacao=$(printf '%s\n' "${valores_pontuacao_performance_limpos[@]}" | sort -n | head -1)
    local maximo_pontuacao=$(printf '%s\n' "${valores_pontuacao_performance_limpos[@]}" | sort -n | tail -1)
    
    # --- Formatação Explícita dos Valores em SEGUNDOS e PONTUAÇÃO (Locale C para ponto decimal) ---
    
    # First Contentful Paint (Média, DP, IC, Min, Max)
    media_primeira_renderizacao_segundos_formatada=$(LC_NUMERIC=C printf "%.3f" $media_primeira_renderizacao_segundos 2>/dev/null || echo "0.000")
    desvio_padrao_primeira_renderizacao_segundos_formatado=$(LC_NUMERIC=C printf "%.3f" $desvio_padrao_primeira_renderizacao_segundos 2>/dev/null || echo "0.000")
    intervalo_confianca_primeira_renderizacao_segundos_formatado=$(LC_NUMERIC=C printf "%.3f" $intervalo_confianca_primeira_renderizacao_segundos 2>/dev/null || echo "0.000")
    minimo_primeira_renderizacao_segundos_formatado=$(LC_NUMERIC=C printf "%.3f" $(echo "scale=3; $minimo_primeira_renderizacao / 1000" | bc -l) 2>/dev/null || echo "0.000")
    maximo_primeira_renderizacao_segundos_formatado=$(LC_NUMERIC=C printf "%.3f" $(echo "scale=3; $maximo_primeira_renderizacao / 1000" | bc -l) 2>/dev/null || echo "0.000")

    # Largest Contentful Paint (Média, DP, IC, Min, Max)
    media_maior_renderizacao_segundos_formatada=$(LC_NUMERIC=C printf "%.3f" $media_maior_renderizacao_segundos 2>/dev/null || echo "0.000")
    desvio_padrao_maior_renderizacao_segundos_formatado=$(LC_NUMERIC=C printf "%.3f" $desvio_padrao_maior_renderizacao_segundos 2>/dev/null || echo "0.000")
    intervalo_confianca_maior_renderizacao_segundos_formatado=$(LC_NUMERIC=C printf "%.3f" $intervalo_confianca_maior_renderizacao_segundos 2>/dev/null || echo "0.000")
    minimo_maior_renderizacao_segundos_formatado=$(LC_NUMERIC=C printf "%.3f" $(echo "scale=3; $minimo_maior_renderizacao / 1000" | bc -l) 2>/dev/null || echo "0.000")
    maximo_maior_renderizacao_segundos_formatado=$(LC_NUMERIC=C printf "%.3f" $(echo "scale=3; $maximo_maior_renderizacao / 1000" | bc -l) 2>/dev/null || echo "0.000")

    # Performance Score (Média, DP, IC, CV, Min, Max)
    media_pontuacao_formatada=$(LC_NUMERIC=C printf "%.1f" $media_pontuacao 2>/dev/null || echo "0.0")
    desvio_padrao_pontuacao_formatado=$(LC_NUMERIC=C printf "%.2f" $desvio_padrao_pontuacao 2>/dev/null || echo "0.00")
    intervalo_confianca_pontuacao_formatado=$(LC_NUMERIC=C printf "%.2f" $intervalo_confianca_pontuacao 2>/dev/null || echo "0.00")
    coeficiente_variacao_pontuacao_formatado=$(LC_NUMERIC=C printf "%.2f" $coeficiente_variacao_pontuacao 2>/dev/null || echo "0.00")
    minimo_pontuacao_formatado=$(LC_NUMERIC=C printf "%.1f" $minimo_pontuacao 2>/dev/null || echo "0.0")
    maximo_pontuacao_formatado=$(LC_NUMERIC=C printf "%.1f" $maximo_pontuacao 2>/dev/null || echo "0.0")

    # Coeficiente de Variação (Manter o formato original de 4 casas decimais do calculo)
    coeficiente_variacao_primeira_renderizacao_formatado=$(LC_NUMERIC=C printf "%.2f" $coeficiente_variacao_primeira_renderizacao 2>/dev/null || echo "0.00")
    coeficiente_variacao_maior_renderizacao_formatado=$(LC_NUMERIC=C printf "%.2f" $coeficiente_variacao_maior_renderizacao 2>/dev/null || echo "0.00")
    
    # Armazenar resultados para análise comparativa
    # Usar variáveis de segundos com precisão total (não a formatada para 3 casas) para o cálculo de diferença
    aplicacao_tempo_primeira_renderizacao_media["$nome"]=$media_primeira_renderizacao_segundos
    aplicacao_tempo_primeira_renderizacao_intervalo_confianca["$nome"]=$intervalo_confianca_primeira_renderizacao_segundos
    aplicacao_tempo_primeira_renderizacao_coeficiente_variacao["$nome"]=$coeficiente_variacao_primeira_renderizacao

    aplicacao_tempo_maior_renderizacao_media["$nome"]=$media_maior_renderizacao_segundos
    aplicacao_tempo_maior_renderizacao_intervalo_confianca["$nome"]=$intervalo_confianca_maior_renderizacao_segundos
    aplicacao_tempo_maior_renderizacao_coeficiente_variacao["$nome"]=$coeficiente_variacao_maior_renderizacao

    aplicacao_pontuacao_performance_media["$nome"]=$media_pontuacao_formatada
    aplicacao_pontuacao_performance_intervalo_confianca["$nome"]=$intervalo_confianca_pontuacao_formatado
    aplicacao_pontuacao_performance_coeficiente_variacao["$nome"]=$coeficiente_variacao_pontuacao_formatado
    
    # Escrever no relatório
    cat >> "$ARQUIVO_RESULTADO" << EOF
## $nome

**URL:** \`$url\`  
**Medições válidas:** ${#valores_tempo_primeira_renderizacao_limpos[@]} (${outliers_primeira_renderizacao} outliers removidos)

### Estatísticas Resumidas

| Métrica | Média | Desvio Padrão | Coeficiente de Variação (%) | Intervalo de Confiança ${NIVEL_CONFIANCA}% | Mínimo | Máximo |
|--------|------|-------------|--------|-----------|-----|-----|
| **First Contentful Paint (segundos)** | ${media_primeira_renderizacao_segundos_formatada} | ${desvio_padrao_primeira_renderizacao_segundos_formatado} | ${coeficiente_variacao_primeira_renderizacao_formatado} | ±${intervalo_confianca_primeira_renderizacao_segundos_formatado} | ${minimo_primeira_renderizacao_segundos_formatado} | ${maximo_primeira_renderizacao_segundos_formatado} |
| **Largest Contentful Paint (segundos)** | ${media_maior_renderizacao_segundos_formatada} | ${desvio_padrao_maior_renderizacao_segundos_formatado} | ${coeficiente_variacao_maior_renderizacao_formatado} | ±${intervalo_confianca_maior_renderizacao_segundos_formatado} | ${minimo_maior_renderizacao_segundos_formatado} | ${maximo_maior_renderizacao_segundos_formatado} |
| **Performance Score** | ${media_pontuacao_formatada} | ${desvio_padrao_pontuacao_formatado} | ${coeficiente_variacao_pontuacao_formatado} | ±${intervalo_confianca_pontuacao_formatado} | ${minimo_pontuacao_formatado} | ${maximo_pontuacao_formatado} |

**Interpretação:**
- Valores médios com intervalos de confiança de ${NIVEL_CONFIANCA}%
- Coeficiente de Variação: menor é melhor, menos de 10% = excelente, 10-20% = bom, maior que 20% = alta variabilidade
- Valores menores de First Contentful Paint e Largest Contentful Paint e pontuações maiores de Performance são melhores

---

EOF
    
    echo -e "${VERDE}✓ Análise completa${SEM_COR}\n"
    echo -e "${CIANO}Resumo dos Resultados:${SEM_COR}"
    echo -e "  First Contentful Paint: ${media_primeira_renderizacao_segundos_formatada}s ± ${intervalo_confianca_primeira_renderizacao_segundos_formatado}s (Coeficiente de Variação: ${coeficiente_variacao_primeira_renderizacao_formatado}%)"
    echo -e "  Largest Contentful Paint: ${media_maior_renderizacao_segundos_formatada}s ± ${intervalo_confianca_maior_renderizacao_segundos_formatado}s (Coeficiente de Variação: ${coeficiente_variacao_maior_renderizacao_formatado}%)"
    echo -e "  Performance: ${media_pontuacao_formatada} ± ${intervalo_confianca_pontuacao_formatado} (Coeficiente de Variação: ${coeficiente_variacao_pontuacao_formatado}%)"
}

# Execução principal
echo -e "${AZUL}Iniciando sequência de benchmark...${SEM_COR}\n"

iniciar_containers "$DIRETORIO_MODULE_FEDERATION" "$NOME_MODULE_FEDERATION"
executar_benchmark_lighthouse "$URL_MODULE_FEDERATION" "$NOME_MODULE_FEDERATION"
parar_containers "$DIRETORIO_MODULE_FEDERATION" "$NOME_MODULE_FEDERATION"

iniciar_containers "$DIRETORIO_SINGLE_SPA" "$NOME_SINGLE_SPA"
executar_benchmark_lighthouse "$URL_SINGLE_SPA" "$NOME_SINGLE_SPA"
parar_containers "$DIRETORIO_SINGLE_SPA" "$NOME_SINGLE_SPA"

# Gerar análise comparativa
echo -e "\n${CIANO}Gerando análise comparativa...${SEM_COR}"

nome_module_federation="$NOME_MODULE_FEDERATION"
nome_single_spa="$NOME_SINGLE_SPA"

# Usar a precisão total para calcular as diferenças
diferenca_primeira_renderizacao=$(echo "${aplicacao_tempo_primeira_renderizacao_media[$nome_module_federation]} - ${aplicacao_tempo_primeira_renderizacao_media[$nome_single_spa]}" | bc -l)
diferenca_maior_renderizacao=$(echo "${aplicacao_tempo_maior_renderizacao_media[$nome_module_federation]} - ${aplicacao_tempo_maior_renderizacao_media[$nome_single_spa]}" | bc -l)
diferenca_pontuacao=$(echo "${aplicacao_pontuacao_performance_media[$nome_module_federation]} - ${aplicacao_pontuacao_performance_media[$nome_single_spa]}" | bc -l)

# Formatar diferenças para 3 casas decimais (segundos) e 1 casa decimal (pontuação)
diferenca_primeira_renderizacao_formatada=$(LC_NUMERIC=C printf "%.3f" ${diferenca_primeira_renderizacao#-} 2>/dev/null || echo "0.000")
diferenca_maior_renderizacao_formatada=$(LC_NUMERIC=C printf "%.3f" ${diferenca_maior_renderizacao#-} 2>/dev/null || echo "0.000")
diferenca_pontuacao_formatada=$(LC_NUMERIC=C printf "%.1f" ${diferenca_pontuacao#-} 2>/dev/null || echo "0.0")

# Determinar vencedor e significância estatística
vencedor_primeira_renderizacao=""
vencedor_maior_renderizacao=""
vencedor_pontuacao=""
significancia_primeira_renderizacao=""
significancia_maior_renderizacao=""
significancia_pontuacao=""

# Análise First Contentful Paint
soma_intervalo_confianca_primeira_renderizacao=$(echo "${aplicacao_tempo_primeira_renderizacao_intervalo_confianca[$nome_module_federation]} + ${aplicacao_tempo_primeira_renderizacao_intervalo_confianca[$nome_single_spa]}" | bc -l)
if (( $(echo "${diferenca_primeira_renderizacao#-} > $soma_intervalo_confianca_primeira_renderizacao" | bc -l) )); then
    significancia_primeira_renderizacao="✓ Estatisticamente significativo"
    if (( $(echo "$diferenca_primeira_renderizacao < 0" | bc -l) )); then
        vencedor_primeira_renderizacao="**Vencedor: $nome_module_federation** (${diferenca_primeira_renderizacao_formatada}s mais rápido)"
    else
        vencedor_primeira_renderizacao="**Vencedor: $nome_single_spa** (${diferenca_primeira_renderizacao_formatada}s mais rápido)"
    fi
else
    significancia_primeira_renderizacao="✗ Não estatisticamente significativo (intervalos de confiança se sobrepõem)"
    vencedor_primeira_renderizacao="Sem vencedor claro"
fi

# Verificar significância prática para First Contentful Paint
pratico_primeira_renderizacao=""
if (( $(echo "${diferenca_primeira_renderizacao#-} < 0.1" | bc -l) )); then
    pratico_primeira_renderizacao="⚠️ Diferença menor que 0.1 segundos (provavelmente não perceptível aos usuários)"
fi

# Análise Largest Contentful Paint
soma_intervalo_confianca_maior_renderizacao=$(echo "${aplicacao_tempo_maior_renderizacao_intervalo_confianca[$nome_module_federation]} + ${aplicacao_tempo_maior_renderizacao_intervalo_confianca[$nome_single_spa]}" | bc -l)
if (( $(echo "${diferenca_maior_renderizacao#-} > $soma_intervalo_confianca_maior_renderizacao" | bc -l) )); then
    significancia_maior_renderizacao="✓ Estatisticamente significativo"
    if (( $(echo "$diferenca_maior_renderizacao < 0" | bc -l) )); then
        vencedor_maior_renderizacao="**Vencedor: $nome_module_federation** (${diferenca_maior_renderizacao_formatada}s mais rápido)"
    else
        vencedor_maior_renderizacao="**Vencedor: $nome_single_spa** (${diferenca_maior_renderizacao_formatada}s mais rápido)"
    fi
else
    significancia_maior_renderizacao="✗ Não estatisticamente significativo (intervalos de confiança se sobrepõem)"
    vencedor_maior_renderizacao="Sem vencedor claro"
fi

# Verificar significância prática para Largest Contentful Paint
pratico_maior_renderizacao=""
if (( $(echo "${diferenca_maior_renderizacao#-} < 0.2" | bc -l) )); then
    pratico_maior_renderizacao="⚠️ Diferença menor que 0.2 segundos (provavelmente não perceptível aos usuários)"
fi

# Análise Performance Score
soma_intervalo_confianca_pontuacao=$(echo "${aplicacao_pontuacao_performance_intervalo_confianca[$nome_module_federation]} + ${aplicacao_pontuacao_performance_intervalo_confianca[$nome_single_spa]}" | bc -l)
if (( $(echo "${diferenca_pontuacao#-} > $soma_intervalo_confianca_pontuacao" | bc -l) )); then
    significancia_pontuacao="✓ Estatisticamente significativo"
    if (( $(echo "$diferenca_pontuacao > 0" | bc -l) )); then
        vencedor_pontuacao="**Vencedor: $nome_module_federation** (+${diferenca_pontuacao_formatada} pontos)"
    else
        vencedor_pontuacao="**Vencedor: $nome_single_spa** (+${diferenca_pontuacao_formatada} pontos)"
    fi
else
    significancia_pontuacao="✗ Não estatisticamente significativo (intervalos de confiança se sobrepõem)"
    vencedor_pontuacao="Sem vencedor claro"
fi

# Análise de consistência
mais_consistente_primeira_renderizacao=""
if (( $(echo "${aplicacao_tempo_primeira_renderizacao_coeficiente_variacao[$nome_module_federation]} < ${aplicacao_tempo_primeira_renderizacao_coeficiente_variacao[$nome_single_spa]}" | bc -l) )); then
    mais_consistente_primeira_renderizacao="$nome_module_federation (Coeficiente de Variação: $(LC_NUMERIC=C printf "%.2f" ${aplicacao_tempo_primeira_renderizacao_coeficiente_variacao[$nome_module_federation]} 2>/dev/null || echo "0.00")% versus $(LC_NUMERIC=C printf "%.2f" ${aplicacao_tempo_primeira_renderizacao_coeficiente_variacao[$nome_single_spa]} 2>/dev/null || echo "0.00")%)"
else
    mais_consistente_primeira_renderizacao="$nome_single_spa (Coeficiente de Variação: $(LC_NUMERIC=C printf "%.2f" ${aplicacao_tempo_primeira_renderizacao_coeficiente_variacao[$nome_single_spa]} 2>/dev/null || echo "0.00")% versus $(LC_NUMERIC=C printf "%.2f" ${aplicacao_tempo_primeira_renderizacao_coeficiente_variacao[$nome_module_federation]} 2>/dev/null || echo "0.00")%)"
fi

mais_consistente_maior_renderizacao=""
if (( $(echo "${aplicacao_tempo_maior_renderizacao_coeficiente_variacao[$nome_module_federation]} < ${aplicacao_tempo_maior_renderizacao_coeficiente_variacao[$nome_single_spa]}" | bc -l) )); then
    mais_consistente_maior_renderizacao="$nome_module_federation (Coeficiente de Variação: $(LC_NUMERIC=C printf "%.2f" ${aplicacao_tempo_maior_renderizacao_coeficiente_variacao[$nome_module_federation]} 2>/dev/null || echo "0.00")% versus $(LC_NUMERIC=C printf "%.2f" ${aplicacao_tempo_maior_renderizacao_coeficiente_variacao[$nome_single_spa]} 2>/dev/null || echo "0.00")%)"
else
    mais_consistente_maior_renderizacao="$nome_single_spa (Coeficiente de Variação: $(LC_NUMERIC=C printf "%.2f" ${aplicacao_tempo_maior_renderizacao_coeficiente_variacao[$nome_single_spa]} 2>/dev/null || echo "0.00")% versus $(LC_NUMERIC=C printf "%.2f" ${aplicacao_tempo_maior_renderizacao_coeficiente_variacao[$nome_module_federation]} 2>/dev/null || echo "0.00")%)"
fi

mais_consistente_pontuacao=""
coef_var_module_federation="${aplicacao_pontuacao_performance_coeficiente_variacao[$nome_module_federation]}"
coef_var_single_spa="${aplicacao_pontuacao_performance_coeficiente_variacao[$nome_single_spa]}"

# Comparação correta: menor coeficiente de variação = mais consistente
if (( $(echo "$coef_var_module_federation < $coef_var_single_spa" | bc -l) )); then
    mais_consistente_pontuacao="$nome_module_federation (Coeficiente de Variação: ${coef_var_module_federation}% versus ${coef_var_single_spa}%)"
else
    mais_consistente_pontuacao="$nome_single_spa (Coeficiente de Variação: ${coef_var_single_spa}% versus ${coef_var_module_federation}%)"
fi

# Resumo final
cat >> "$ARQUIVO_RESULTADO" << EOF
## Análise Comparativa

### First Contentful Paint (Tempo da Primeira Renderização de Conteúdo)

| Aplicação | Média | Intervalo de Confiança 95% | Coeficiente de Variação |
|-------------|------|--------|-----|
| $nome_module_federation | $(LC_NUMERIC=C printf "%.3f" ${aplicacao_tempo_primeira_renderizacao_media[$nome_module_federation]} 2>/dev/null || echo "0.000")s | ±$(LC_NUMERIC=C printf "%.3f" ${aplicacao_tempo_primeira_renderizacao_intervalo_confianca[$nome_module_federation]} 2>/dev/null || echo "0.000")s | $(LC_NUMERIC=C printf "%.2f" ${aplicacao_tempo_primeira_renderizacao_coeficiente_variacao[$nome_module_federation]} 2>/dev/null || echo "0.00")% |
| $nome_single_spa | $(LC_NUMERIC=C printf "%.3f" ${aplicacao_tempo_primeira_renderizacao_media[$nome_single_spa]} 2>/dev/null || echo "0.000")s | ±$(LC_NUMERIC=C printf "%.3f" ${aplicacao_tempo_primeira_renderizacao_intervalo_confianca[$nome_single_spa]} 2>/dev/null || echo "0.000")s | $(LC_NUMERIC=C printf "%.2f" ${aplicacao_tempo_primeira_renderizacao_coeficiente_variacao[$nome_single_spa]} 2>/dev/null || echo "0.00")% |

**Diferença:** ${diferenca_primeira_renderizacao_formatada}s  
**$significancia_primeira_renderizacao** $vencedor_primeira_renderizacao  
$pratico_primeira_renderizacao

**Mais consistente:** $mais_consistente_primeira_renderizacao

---

### Largest Contentful Paint (Tempo da Maior Renderização de Conteúdo)

| Aplicação | Média | Intervalo de Confiança 95% | Coeficiente de Variação |
|-------------|------|--------|-----|
| $nome_module_federation | $(LC_NUMERIC=C printf "%.3f" ${aplicacao_tempo_maior_renderizacao_media[$nome_module_federation]} 2>/dev/null || echo "0.000")s | ±$(LC_NUMERIC=C printf "%.3f" ${aplicacao_tempo_maior_renderizacao_intervalo_confianca[$nome_module_federation]} 2>/dev/null || echo "0.000")s | $(LC_NUMERIC=C printf "%.2f" ${aplicacao_tempo_maior_renderizacao_coeficiente_variacao[$nome_module_federation]} 2>/dev/null || echo "0.00")% |
| $nome_single_spa | $(LC_NUMERIC=C printf "%.3f" ${aplicacao_tempo_maior_renderizacao_media[$nome_single_spa]} 2>/dev/null || echo "0.000")s | ±$(LC_NUMERIC=C printf "%.3f" ${aplicacao_tempo_maior_renderizacao_intervalo_confianca[$nome_single_spa]} 2>/dev/null || echo "0.000")s | $(LC_NUMERIC=C printf "%.2f" ${aplicacao_tempo_maior_renderizacao_coeficiente_variacao[$nome_single_spa]} 2>/dev/null || echo "0.00")% |

**Diferença:** ${diferenca_maior_renderizacao_formatada}s  
**$significancia_maior_renderizacao** $vencedor_maior_renderizacao  
$pratico_maior_renderizacao

**Mais consistente:** $mais_consistente_maior_renderizacao

---

### Performance Score (Pontuação de Performance)

| Aplicação | Média | Intervalo de Confiança 95% | Coeficiente de Variação |
|-------------|------|--------|-----|
| $nome_module_federation | ${aplicacao_pontuacao_performance_media[$nome_module_federation]} | ±${aplicacao_pontuacao_performance_intervalo_confianca[$nome_module_federation]} | ${aplicacao_pontuacao_performance_coeficiente_variacao[$nome_module_federation]}% |
| $nome_single_spa | ${aplicacao_pontuacao_performance_media[$nome_single_spa]} | ±${aplicacao_pontuacao_performance_intervalo_confianca[$nome_single_spa]} | ${aplicacao_pontuacao_performance_coeficiente_variacao[$nome_single_spa]}% |

**Diferença:** ${diferenca_pontuacao_formatada} pontos  
**$significancia_pontuacao** $vencedor_pontuacao

**Mais consistente:** $mais_consistente_pontuacao

---

### Recomendação Geral

Baseado na análise estatística acima:

1. **Significância Estatística:** Resultados marcados com ✓ indicam diferenças que provavelmente não são devidas ao acaso
2. **Significância Prática:** Mesmo se estatisticamente significativo, pequenas diferenças podem não impactar a experiência do usuário
3. **Consistência:** Coeficiente de Variação menor indica performance mais previsível e estável

**Guia de Interpretação:**
- Intervalos de confiança que não se sobrepõem = forte evidência de diferença real
- Coeficiente de Variação menor que 10% = consistência excelente
- Coeficiente de Variação 10-20% = boa consistência  
- Coeficiente de Variação maior que 20% = alta variabilidade (considere re-testar)

---

EOF

# Resumo final
echo -e "\n${AZUL}================================================================${SEM_COR}"
echo -e "${AZUL}  Benchmark Completo!${SEM_COR}"
echo -e "${AZUL}================================================================${SEM_COR}\n"
echo -e "${VERDE}Resultados salvos em:${SEM_COR}"
echo -e "  📊 Relatório: ${CIANO}$ARQUIVO_RESULTADO${SEM_COR}"
echo -e "  📁 Dados JSON: ${CIANO}$DIRETORIO_JSON/${SEM_COR}\n"

echo -e "${AMARELO}Próximos passos:${SEM_COR}"
echo -e "  1. Revisar o relatório para significância estatística"
echo -e "  2. Verificar valores do Coeficiente de Variação para consistência de performance"
echo -e "  3. Analisar dados JSON para padrões"
echo -e "  4. Re-executar se alta variabilidade detectada (Coeficiente de Variação maior que 20%)\n"