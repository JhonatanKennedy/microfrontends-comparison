#!/bin/bash

# ============================================================================
# Clean Build Benchmark - Microfrontends Performance Analysis
# Baseado na Metodologia Estatística de Raj Jain
# ============================================================================

set -e

# ============================================================================
# Configuração de Cores
# ============================================================================

readonly VERMELHO='\033[0;31m'
readonly VERDE='\033[0;32m'
readonly AMARELO='\033[1;33m'
readonly AZUL='\033[0;34m'
readonly CIANO='\033[0;36m'
readonly SEM_COR='\033[0m'

# ============================================================================
# Configuração Baseada nas Recomendações de Jain
# ============================================================================

readonly EXECUCOES_AQUECIMENTO=3      # Execuções de aquecimento para estabilizar o sistema
readonly EXECUCOES_MEDICAO=30         # Mínimo recomendado para significância estatística (Jain, Capítulo 20)
readonly NIVEL_CONFIANCA=95           # Intervalo de confiança de 95%
readonly DELAY_ENTRE_EXECUCOES=3      # Segundos entre execuções para evitar interferência

readonly DIRETORIO_RESULTADOS="reports/build"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)
readonly ARQUIVO_RESULTADO="${DIRETORIO_RESULTADOS}/benchmark_${TIMESTAMP}.md"

readonly PROJETOS=(
    "mf-module-federation/shell-app"
    "mf-module-federation/checkout-app"
    "mf-module-federation/home-app"
    "mf-module-federation/ui-utils"
    "mf-single-spa/shell-app"
    "mf-single-spa/checkout-app"
    "mf-single-spa/home-app"
    "mf-single-spa/ui-utils"
)

# Arrays associativos para armazenar resultados - usar chaves únicas com arquitetura
declare -A projeto_build_time_media projeto_build_time_intervalo_confianca projeto_build_time_coeficiente_variacao
declare -A projeto_bundle_size_media projeto_bundle_size_intervalo_confianca projeto_bundle_size_coeficiente_variacao
declare -A projeto_total_files_media projeto_total_files_intervalo_confianca projeto_total_files_coeficiente_variacao
declare -A projeto_js_chunks_media projeto_js_chunks_intervalo_confianca projeto_js_chunks_coeficiente_variacao
declare -A projeto_build_time_desvio_padrao projeto_build_time_minimo projeto_build_time_maximo

# ============================================================================
# Funções Estatísticas Baseadas na Metodologia de Jain
# ============================================================================

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
    
    if [ $quantidade -lt 2 ]; then
        echo "0"
        return
    fi
    
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
    
    if [ $quantidade -lt 2 ]; then
        echo "0"
        return
    fi
    
    # Valor t para 95% de confiança (aproximado para n=10: 2.262, n=30: 2.045, n=∞: 1.96)
    local valor_t="2.262"
    if [ $quantidade -ge 30 ]; then
        valor_t="2.045"
    elif [ $quantidade -ge 100 ]; then
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
    
    if [ $quantidade -lt 4 ]; then
        echo "${valores[@]}"
        return
    fi
    
    # Ordenar valores
    IFS=$'\n' ordenados=($(sort -n <<<"${valores[*]}"))
    unset IFS
    
    # Calcular quartis
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

# ============================================================================
# Funções de Conversão de Tamanho
# ============================================================================

convert_to_kb() {
    local size=$1
    local value=${size//[^0-9.]/}
    local unit=${size//[0-9.]/}
    
    case $unit in
        K|k) echo "$value" ;;
        M|m) echo "scale=2; $value * 1024" | bc -l ;;
        G|g) echo "scale=2; $value * 1024 * 1024" | bc -l ;;
        *) echo "$value" ;;
    esac
}

format_size() {
    local kb=$1
    
    if (( $(echo "$kb < 1024" | bc -l) )); then
        printf "%.2fK" $kb
    elif (( $(echo "$kb < 1048576" | bc -l) )); then
        printf "%.2fM" $(echo "scale=2; $kb / 1024" | bc -l)
    else
        printf "%.2fG" $(echo "scale=2; $kb / 1024 / 1024" | bc -l)
    fi
}

# ============================================================================
# Função para Calcular Diferenças
# ============================================================================

calculate_difference() {
    local value1=$1
    local value2=$2
    local unit=$3
    
    local diff=$(echo "$value1 - $value2" | bc -l)
    local diff_abs=$(echo "scale=6; sqrt($diff * $diff)" | bc -l)
    
    if (( $(echo "$diff_abs < 0.001" | bc -l) )); then
        echo "≈ 0"
        return
    fi
    
    local diff_fmt=""
    case $unit in
        "s")
            diff_fmt=$(LC_NUMERIC=C printf "%.3f" $diff_abs)
            if (( $(echo "$diff < 0" | bc -l) )); then
                echo "-${diff_fmt}s"
            else
                echo "+${diff_fmt}s"
            fi
            ;;
        "%")
            diff_fmt=$(LC_NUMERIC=C printf "%.2f" $diff_abs)
            if (( $(echo "$diff < 0" | bc -l) )); then
                echo "-${diff_fmt}%"
            else
                echo "+${diff_fmt}%"
            fi
            ;;
        "size")
            diff_fmt=$(format_size "$diff_abs")
            if (( $(echo "$diff < 0" | bc -l) )); then
                echo "-${diff_fmt}"
            else
                echo "+${diff_fmt}"
            fi
            ;;
        "files"|"chunks")
            diff_fmt=$(LC_NUMERIC=C printf "%.0f" $diff_abs)
            if (( $(echo "$diff < 0" | bc -l) )); then
                echo "-${diff_fmt}"
            else
                echo "+${diff_fmt}"
            fi
            ;;
        *)
            diff_fmt=$(LC_NUMERIC=C printf "%.3f" $diff_abs)
            if (( $(echo "$diff < 0" | bc -l) )); then
                echo "-${diff_fmt}"
            else
                echo "+${diff_fmt}"
            fi
            ;;
    esac
}

# ============================================================================
# Funções de Logging
# ============================================================================

log_info() {
    echo -e "${AZUL}[INFO]${SEM_COR} $1" >&2
}

log_success() {
    echo -e "${VERDE}[SUCCESS]${SEM_COR} $1" >&2
}

log_warning() {
    echo -e "${AMARELO}[WARNING]${SEM_COR} $1" >&2
}

log_error() {
    echo -e "${VERMELHO}[ERROR]${SEM_COR} $1" >&2
}

write_to_file() {
    echo "$1" >> "$ARQUIVO_RESULTADO"
}

# ============================================================================
# Informações do Sistema
# ============================================================================

get_cpu_info() {
    if [ -f /proc/cpuinfo ]; then
        grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs
    else
        sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown"
    fi
}

get_memory_info() {
    if command -v free &> /dev/null; then
        free -h | grep Mem | awk '{print $2}'
    else
        sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.1fG", $1/1024/1024/1024}' || echo "Unknown"
    fi
}

get_os_info() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$NAME $VERSION"
    else
        sw_vers -productName 2>/dev/null && sw_vers -productVersion 2>/dev/null | tr '\n' ' ' || uname -s
    fi
}

get_cpu_cores() {
    nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "Unknown"
}

# ============================================================================
# Limpeza de Cache
# ============================================================================

clean_build_cache() {
    local project_path=$1
    
    cd "$project_path"
    
    # Remove build outputs
    [ -d "dist" ] && rm -rf dist
    [ -d "build" ] && rm -rf build
    
    # Remove cache directories
    [ -d "node_modules/.cache" ] && rm -rf node_modules/.cache
    [ -d ".rsbuild" ] && rm -rf .rsbuild
    [ -d ".rspack" ] && rm -rf .rspack
    [ -d ".webpack" ] && rm -rf .webpack
    [ -d "node_modules/.vite" ] && rm -rf node_modules/.vite
    [ -d ".next" ] && rm -rf .next
    [ -d ".turbo" ] && rm -rf .turbo
    
    # Clean npm cache
    npm cache clean --force > /dev/null 2>&1 || true
    
    # Verify dist is removed
    if [ -d "dist" ]; then
        sudo rm -rf dist 2>/dev/null || true
    fi
    
    cd - > /dev/null
    sleep 1
}

# ============================================================================
# Medição de Build
# ============================================================================

measure_build() {
    local project_path=$1
    local run_number=$2
    
    cd "$project_path"
    
    # Verificar estado limpo
    if [ -d "dist" ] || [ -d "build" ]; then
        log_error "Build directory exists before build!"
        cd - > /dev/null
        echo "ERROR|0|0|0|0"
        return
    fi
    
    local build_log="/tmp/build_output_$$.log"
    local error_log="/tmp/build_error_$$.log"
    
    # Medir tempo de build
    local start_ms=$(date +%s%3N)
    
    set +e
    npm run build > "$build_log" 2> "$error_log"
    local exit_code=$?
    set -e
    
    local end_ms=$(date +%s%3N)
    local duration_ms=$((end_ms - start_ms))
    local duration_s=$(awk -v ms="$duration_ms" 'BEGIN {printf "%.3f", ms / 1000}')
    
    # Verificar sucesso do build
    if [ $exit_code -ne 0 ]; then
        rm -f "$build_log" "$error_log"
        cd - > /dev/null
        echo "ERROR|0|0|0|0"
        return
    fi
    
    # Encontrar diretório de saída
    local output_dir=""
    if [ -d "dist" ]; then
        output_dir="dist"
    elif [ -d "build" ]; then
        output_dir="build"
    else
        rm -f "$build_log" "$error_log"
        cd - > /dev/null
        echo "ERROR|0|0|0|0"
        return
    fi
    
    # Coletar métricas
    local bundle_size=$(du -sk "$output_dir" 2>/dev/null | cut -f1 || echo "0")
    local total_files=$(find "$output_dir" -type f 2>/dev/null | wc -l | xargs)
    local js_chunks=$(find "$output_dir" -type f \( -name "*.js" -o -name "*.mjs" \) 2>/dev/null | wc -l | xargs)
    
    rm -f "$build_log" "$error_log"
    cd - > /dev/null
    
    echo "$duration_s|$bundle_size|$total_files|$js_chunks"
}

# ============================================================================
# Benchmark de Projeto
# ============================================================================

benchmark_project() {
    local project_path=$1
    local project_name=$(basename "$project_path")
    local architecture=$(basename $(dirname "$project_path"))
    
    echo -e "\n${VERDE}═══════════════════════════════════════════════════${SEM_COR}"
    echo -e "${VERDE}  Executando Benchmark: $architecture/$project_name${SEM_COR}"
    echo -e "${VERDE}═══════════════════════════════════════════════════${SEM_COR}\n"
    
    # Validar projeto
    if [ ! -d "$project_path" ]; then
        log_error "Project not found: $project_path"
        return
    fi
    
    if [ ! -f "$project_path/package.json" ]; then
        log_error "package.json not found in $project_path"
        return
    fi
    
    # Instalar dependências se necessário
    if [ ! -d "$project_path/node_modules" ]; then
        log_warning "Installing dependencies..."
        cd "$project_path"
        npm install > /dev/null 2>&1
        cd - > /dev/null
    fi
    
    local build_times=()
    local bundle_sizes=()
    local total_files_array=()
    local js_chunks_array=()
    
    # Fase 1: Execuções de Aquecimento
    echo -e "${CIANO}Fase 1: Execuções de Aquecimento (${EXECUCOES_AQUECIMENTO} execuções)${SEM_COR}"
    for i in $(seq 1 $EXECUCOES_AQUECIMENTO); do
        echo -e "${AMARELO}  Aquecimento $i/$EXECUCOES_AQUECIMENTO${SEM_COR}"
        
        clean_build_cache "$project_path"
        local result=$(measure_build "$project_path" "$i")
        
        IFS='|' read -r time size files chunks <<< "$result"
        
        if [ "$time" != "ERROR" ]; then
            echo -e "${VERDE}    ✓ Execução de aquecimento completa: ${time}s${SEM_COR}"
        else
            echo -e "${AMARELO}    ⚠ Execução de aquecimento falhou${SEM_COR}"
        fi
        
        sleep $DELAY_ENTRE_EXECUCOES
    done
    echo -e "${VERDE}✓ Aquecimento completo${SEM_COR}\n"
    
    # Fase 2: Execuções de Medição
    echo -e "${CIANO}Fase 2: Execuções de Medição (${EXECUCOES_MEDICAO} execuções)${SEM_COR}"
    for i in $(seq 1 $EXECUCOES_MEDICAO); do
        printf "${AMARELO}  Execução %2d/%d${SEM_COR}" $i $EXECUCOES_MEDICAO
        
        clean_build_cache "$project_path"
        local result=$(measure_build "$project_path" "$i")
        
        IFS='|' read -r time size files chunks <<< "$result"
        
        if [ "$time" != "ERROR" ]; then
            build_times+=("$time")
            bundle_sizes+=("$size")
            total_files_array+=("$files")
            js_chunks_array+=("$chunks")
            
            local size_formatted=$(format_size "$size")
            printf " - Tempo: ${time}s | Tamanho: ${size_formatted} | Arquivos: ${files} | JS Chunks: ${chunks}\n"
        else
            printf " ${VERMELHO}✗ Falhou${SEM_COR}\n"
        fi
        
        sleep $DELAY_ENTRE_EXECUCOES
    done
    
    echo -e "\n${CIANO}Fase 3: Análise Estatística${SEM_COR}"
    
    # Verificar medições válidas
    if [ ${#build_times[@]} -lt 5 ]; then
        echo -e "${VERMELHO}✗ Medições válidas insuficientes (${#build_times[@]} coletadas, mínimo 5 necessárias)${SEM_COR}\n"
        write_to_file "## $architecture - $project_name"
        write_to_file ""
        write_to_file "**Status:** ❌ Falhou (medições insuficientes)"
        write_to_file ""
        write_to_file "---"
        write_to_file ""
        return
    fi
    
    echo -e "${VERDE}✓ Coletadas ${#build_times[@]} medições válidas${SEM_COR}"
    
    # Remover outliers para todas as métricas
    local build_times_limpos=($(detectar_outliers_amplitude_interquartil "${build_times[@]}"))
    local bundle_sizes_limpos=($(detectar_outliers_amplitude_interquartil "${bundle_sizes[@]}"))
    local total_files_limpos=($(detectar_outliers_amplitude_interquartil "${total_files_array[@]}"))
    local js_chunks_limpos=($(detectar_outliers_amplitude_interquartil "${js_chunks_array[@]}"))
    
    local outliers_time=$((${#build_times[@]} - ${#build_times_limpos[@]}))
    local outliers_size=$((${#bundle_sizes[@]} - ${#bundle_sizes_limpos[@]}))
    local outliers_files=$((${#total_files_array[@]} - ${#total_files_limpos[@]}))
    local outliers_chunks=$((${#js_chunks_array[@]} - ${#js_chunks_limpos[@]}))
    
    echo -e "${AMARELO}  Outliers removidos: Tempo=$outliers_time, Tamanho=$outliers_size, Arquivos=$outliers_files, Chunks=$outliers_chunks${SEM_COR}"
    
    # Calcular estatísticas para Build Time
    local time_media=$(calcular_media "${build_times_limpos[@]}")
    local time_desvio=$(calcular_desvio_padrao "$time_media" "${build_times_limpos[@]}")
    local time_coef_var=$(calcular_coeficiente_variacao "$time_media" "$time_desvio")
    local time_ic=$(calcular_intervalo_confianca "$time_media" "$time_desvio" "${#build_times_limpos[@]}")
    local time_min=$(printf '%s\n' "${build_times_limpos[@]}" | sort -n | head -1)
    local time_max=$(printf '%s\n' "${build_times_limpos[@]}" | sort -n | tail -1)
    
    # Calcular estatísticas para Bundle Size
    local size_media=$(calcular_media "${bundle_sizes_limpos[@]}")
    local size_desvio=$(calcular_desvio_padrao "$size_media" "${bundle_sizes_limpos[@]}")
    local size_coef_var=$(calcular_coeficiente_variacao "$size_media" "$size_desvio")
    local size_ic=$(calcular_intervalo_confianca "$size_media" "$size_desvio" "${#bundle_sizes_limpos[@]}")
    local size_min=$(printf '%s\n' "${bundle_sizes_limpos[@]}" | sort -n | head -1)
    local size_max=$(printf '%s\n' "${bundle_sizes_limpos[@]}" | sort -n | tail -1)
    
    # Calcular estatísticas para Total Files
    local files_media=$(calcular_media "${total_files_limpos[@]}")
    local files_desvio=$(calcular_desvio_padrao "$files_media" "${total_files_limpos[@]}")
    local files_coef_var=$(calcular_coeficiente_variacao "$files_media" "$files_desvio")
    local files_ic=$(calcular_intervalo_confianca "$files_media" "$files_desvio" "${#total_files_limpos[@]}")
    local files_min=$(printf '%s\n' "${total_files_limpos[@]}" | sort -n | head -1)
    local files_max=$(printf '%s\n' "${total_files_limpos[@]}" | sort -n | tail -1)
    
    # Calcular estatísticas para JS Chunks
    local chunks_media=$(calcular_media "${js_chunks_limpos[@]}")
    local chunks_desvio=$(calcular_desvio_padrao "$chunks_media" "${js_chunks_limpos[@]}")
    local chunks_coef_var=$(calcular_coeficiente_variacao "$chunks_media" "$chunks_desvio")
    local chunks_ic=$(calcular_intervalo_confianca "$chunks_media" "$chunks_desvio" "${#js_chunks_limpos[@]}")
    local chunks_min=$(printf '%s\n' "${js_chunks_limpos[@]}" | sort -n | head -1)
    local chunks_max=$(printf '%s\n' "${js_chunks_limpos[@]}" | sort -n | tail -1)
    
    # Formatação
    local time_media_fmt=$(LC_NUMERIC=C printf "%.3f" $time_media)
    local time_desvio_fmt=$(LC_NUMERIC=C printf "%.3f" $time_desvio)
    local time_coef_var_fmt=$(LC_NUMERIC=C printf "%.2f" $time_coef_var)
    local time_ic_fmt=$(LC_NUMERIC=C printf "%.3f" $time_ic)
    local time_min_fmt=$(LC_NUMERIC=C printf "%.3f" $time_min)
    local time_max_fmt=$(LC_NUMERIC=C printf "%.3f" $time_max)
    
    local size_media_fmt=$(format_size "$size_media")
    local size_desvio_fmt=$(format_size "$size_desvio")
    local size_coef_var_fmt=$(LC_NUMERIC=C printf "%.2f" $size_coef_var)
    local size_ic_fmt=$(format_size "$size_ic")
    local size_min_fmt=$(format_size "$size_min")
    local size_max_fmt=$(format_size "$size_max")
    
    local files_media_fmt=$(LC_NUMERIC=C printf "%.1f" $files_media)
    local files_desvio_fmt=$(LC_NUMERIC=C printf "%.2f" $files_desvio)
    local files_coef_var_fmt=$(LC_NUMERIC=C printf "%.2f" $files_coef_var)
    local files_ic_fmt=$(LC_NUMERIC=C printf "%.2f" $files_ic)
    
    local chunks_media_fmt=$(LC_NUMERIC=C printf "%.1f" $chunks_media)
    local chunks_desvio_fmt=$(LC_NUMERIC=C printf "%.2f" $chunks_desvio)
    local chunks_coef_var_fmt=$(LC_NUMERIC=C printf "%.2f" $chunks_coef_var)
    local chunks_ic_fmt=$(LC_NUMERIC=C printf "%.2f" $chunks_ic)
    
    # Armazenar para comparação (usar chave única com arquitetura + nome)
    local chave="${architecture}_${project_name}"
    
    projeto_build_time_media["$chave"]="$time_media"
    projeto_build_time_intervalo_confianca["$chave"]="$time_ic"
    projeto_build_time_coeficiente_variacao["$chave"]="$time_coef_var"
    projeto_build_time_desvio_padrao["$chave"]="$time_desvio"
    projeto_build_time_minimo["$chave"]="$time_min"
    projeto_build_time_maximo["$chave"]="$time_max"
    
    projeto_bundle_size_media["$chave"]="$size_media"
    projeto_bundle_size_intervalo_confianca["$chave"]="$size_ic"
    projeto_bundle_size_coeficiente_variacao["$chave"]="$size_coef_var"
    
    projeto_total_files_media["$chave"]="$files_media"
    projeto_total_files_intervalo_confianca["$chave"]="$files_ic"
    projeto_total_files_coeficiente_variacao["$chave"]="$files_coef_var"
    
    projeto_js_chunks_media["$chave"]="$chunks_media"
    projeto_js_chunks_intervalo_confianca["$chave"]="$chunks_ic"
    projeto_js_chunks_coeficiente_variacao["$chave"]="$chunks_coef_var"
    
    # Escrever no relatório
    write_to_file "## $architecture - $project_name"
    write_to_file ""
    write_to_file "**Medições válidas:** ${#build_times_limpos[@]} (outliers removidos: $outliers_time)"
    write_to_file ""
    write_to_file "### Build Time"
    write_to_file ""
    write_to_file "| Métrica | Média | Desvio Padrão | Coeficiente de Variação | Intervalo de Confiança ${NIVEL_CONFIANCA}% | Mínimo | Máximo |"
    write_to_file "|---------|-------|---------------|-------------------------|----------------------------|--------|--------|"
    write_to_file "| Build Time | ${time_media_fmt}s | ${time_desvio_fmt}s | ${time_coef_var_fmt}% | ±${time_ic_fmt}s | ${time_min_fmt}s | ${time_max_fmt}s |"
    write_to_file ""
    write_to_file "### Build Artifacts (métricas estáticas)"
    write_to_file ""
    write_to_file "- **Bundle Size:** ${size_media_fmt}"
    write_to_file "- **Total Files:** ${files_media_fmt}"
    write_to_file "- **JS Chunks:** ${chunks_media_fmt}"
    write_to_file ""
    write_to_file "**Interpretação:**"
    write_to_file "- Média com intervalo de confiança de ${NIVEL_CONFIANCA}%"
    write_to_file "- Coeficiente de Variação: menor é melhor, <10% = excelente, 10-20% = bom, >20% = alta variabilidade"
    write_to_file ""
    write_to_file "---"
    write_to_file ""
    
    echo -e "${VERDE}✓ Análise completa${SEM_COR}"
    echo -e "${CIANO}Resumo:${SEM_COR}"
    echo -e "  Build Time: ${time_media_fmt}s ± ${time_ic_fmt}s (CV: ${time_coef_var_fmt}%)"
    echo -e "  Bundle Size: ${size_media_fmt} ± ${size_ic_fmt} (CV: ${size_coef_var_fmt}%)"
    echo -e "  Total Files: ${files_media_fmt} ± ${files_ic_fmt} (CV: ${files_coef_var_fmt}%)"
    echo -e "  JS Chunks: ${chunks_media_fmt} ± ${chunks_ic_fmt} (CV: ${chunks_coef_var_fmt}%)\n"
}

# ============================================================================
# Geração de Relatório
# ============================================================================

generate_report_header() {
    write_to_file "# Relatório de Benchmark de Build"
    write_to_file "**Gerado em:** $(date '+%Y-%m-%d %H:%M:%S %Z')"
    write_to_file ""
    write_to_file "## Design Experimental (Metodologia Raj Jain)"
    write_to_file ""
    write_to_file "### Configuração Estatística"
    write_to_file "- **Execuções de aquecimento:** $EXECUCOES_AQUECIMENTO (excluídas da análise)"
    write_to_file "- **Execuções de medição:** $EXECUCOES_MEDICAO por projeto"
    write_to_file "- **Nível de confiança:** ${NIVEL_CONFIANCA}%"
    write_to_file "- **Delay entre execuções:** ${DELAY_ENTRE_EXECUCOES}s"
    write_to_file "- **Detecção de outliers:** Método da Amplitude Interquartil (1.5 × Amplitude Interquartil)"
    write_to_file ""
    write_to_file "### Ambiente do Sistema"
    write_to_file "- **Sistema Operacional:** $(get_os_info)"
    write_to_file "- **Kernel:** $(uname -r)"
    write_to_file "- **Arquitetura:** $(uname -m)"
    write_to_file "- **Processador:** $(get_cpu_info)"
    write_to_file "- **Núcleos do Processador:** $(get_cpu_cores)"
    write_to_file "- **Memória:** $(get_memory_info)"
    write_to_file "- **Node.js:** $(node --version)"
    write_to_file "- **npm:** $(npm --version)"
    write_to_file ""
    write_to_file "### Métricas Coletadas"
    write_to_file "- **Build Time:** Tempo total do processo de build (em segundos)"
    write_to_file "- **Bundle Size:** Tamanho total do diretório de saída (em KB/MB)"
    write_to_file "- **Total Files:** Quantidade total de arquivos gerados"
    write_to_file "- **JS Chunks:** Quantidade de arquivos JavaScript/MJS gerados"
    write_to_file ""
    write_to_file "### Análise Estatística"
    write_to_file "Para cada métrica, reportamos:"
    write_to_file "- **Média:** Valor médio"
    write_to_file "- **Desvio Padrão:** Medida de variabilidade"
    write_to_file "- **Coeficiente de Variação:** Desvio Padrão / Média × 100% (menor é melhor, <10% é excelente)"
    write_to_file "- **Intervalo de Confiança ${NIVEL_CONFIANCA}%:** Faixa onde a média verdadeira provavelmente está"
    write_to_file "- **Mínimo/Máximo:** Faixa observada"
    write_to_file "- **Outliers Removidos:** Usando método da Amplitude Interquartil"
    write_to_file ""
    write_to_file "---"
    write_to_file ""
}

compare_microfrontends() {
    local mf_type=$1  # shell-app, checkout-app, home-app, ui-utils
    
    write_to_file "## Comparação: $mf_type"
    write_to_file ""
    
    # Definir chaves únicas para cada arquitetura
    local mf_chave="mf-module-federation_${mf_type}"
    local spa_chave="mf-single-spa_${mf_type}"
    
    # Verificar se temos dados para ambas as arquiteturas
    if [ -z "${projeto_build_time_media[$mf_chave]}" ] || [ -z "${projeto_build_time_media[$spa_chave]}" ] || \
       [ "${projeto_build_time_media[$mf_chave]}" = "0" ] || [ "${projeto_build_time_media[$spa_chave]}" = "0" ]; then
        write_to_file "**Nota:** Dados insuficientes para comparação."
        write_to_file "- Module Federation: ${projeto_build_time_media[$mf_chave]:-N/A}"
        write_to_file "- Single-SPA: ${projeto_build_time_media[$spa_chave]:-N/A}"
        write_to_file ""
        write_to_file "---"
        write_to_file ""
        return
    fi
    
    # Build Time - Module Federation
    local mf_time_media="${projeto_build_time_media[$mf_chave]}"
    local mf_time_ic="${projeto_build_time_intervalo_confianca[$mf_chave]}"
    local mf_time_cv="${projeto_build_time_coeficiente_variacao[$mf_chave]}"
    local mf_time_desvio="${projeto_build_time_desvio_padrao[$mf_chave]}"
    local mf_time_min="${projeto_build_time_minimo[$mf_chave]}"
    local mf_time_max="${projeto_build_time_maximo[$mf_chave]}"
    
    # Build Time - Single-SPA
    local spa_time_media="${projeto_build_time_media[$spa_chave]}"
    local spa_time_ic="${projeto_build_time_intervalo_confianca[$spa_chave]}"
    local spa_time_cv="${projeto_build_time_coeficiente_variacao[$spa_chave]}"
    local spa_time_desvio="${projeto_build_time_desvio_padrao[$spa_chave]}"
    local spa_time_min="${projeto_build_time_minimo[$spa_chave]}"
    local spa_time_max="${projeto_build_time_maximo[$spa_chave]}"
    
    # Bundle Size
    local mf_size_media="${projeto_bundle_size_media[$mf_chave]}"
    local spa_size_media="${projeto_bundle_size_media[$spa_chave]}"
    
    # Total Files
    local mf_files_media="${projeto_total_files_media[$mf_chave]}"
    local spa_files_media="${projeto_total_files_media[$spa_chave]}"
    
    # JS Chunks
    local mf_chunks_media="${projeto_js_chunks_media[$mf_chave]}"
    local spa_chunks_media="${projeto_js_chunks_media[$spa_chave]}"
    
    # Debug: mostrar valores coletados
    echo -e "${AMARELO}[DEBUG] $mf_type - MF: $mf_time_media s, SPA: $spa_time_media s${SEM_COR}" >&2
    
    # Formatação Build Time
    local mf_time_fmt=$(LC_NUMERIC=C printf "%.3f" $mf_time_media)
    local mf_time_ic_fmt=$(LC_NUMERIC=C printf "%.3f" $mf_time_ic)
    local mf_time_cv_fmt=$(LC_NUMERIC=C printf "%.2f" $mf_time_cv)
    local mf_time_desvio_fmt=$(LC_NUMERIC=C printf "%.3f" $mf_time_desvio)
    local mf_time_min_fmt=$(LC_NUMERIC=C printf "%.3f" $mf_time_min)
    local mf_time_max_fmt=$(LC_NUMERIC=C printf "%.3f" $mf_time_max)
    
    local spa_time_fmt=$(LC_NUMERIC=C printf "%.3f" $spa_time_media)
    local spa_time_ic_fmt=$(LC_NUMERIC=C printf "%.3f" $spa_time_ic)
    local spa_time_cv_fmt=$(LC_NUMERIC=C printf "%.2f" $spa_time_cv)
    local spa_time_desvio_fmt=$(LC_NUMERIC=C printf "%.3f" $spa_time_desvio)
    local spa_time_min_fmt=$(LC_NUMERIC=C printf "%.3f" $spa_time_min)
    local spa_time_max_fmt=$(LC_NUMERIC=C printf "%.3f" $spa_time_max)
    
    # Formatação métricas estáticas
    local mf_size_fmt=$(format_size "$mf_size_media")
    local spa_size_fmt=$(format_size "$spa_size_media")
    
    local mf_files_fmt=$(LC_NUMERIC=C printf "%.0f" $mf_files_media)
    local spa_files_fmt=$(LC_NUMERIC=C printf "%.0f" $spa_files_media)
    
    local mf_chunks_fmt=$(LC_NUMERIC=C printf "%.0f" $mf_chunks_media)
    local spa_chunks_fmt=$(LC_NUMERIC=C printf "%.0f" $spa_chunks_media)
    
    # Tabela comparativa de Build Time (com ambas arquiteturas lado a lado)
    write_to_file "### Build Time (Tempo de Build)"
    write_to_file ""
    write_to_file "| Métrica | Module Federation | Single-SPA | Diferença |"
    write_to_file "|---------|-------------------|------------|-----------|"
    write_to_file "| **Média** | ${mf_time_fmt}s | ${spa_time_fmt}s | **$(calculate_difference "$mf_time_media" "$spa_time_media" "s")** |"
    write_to_file "| **Desvio Padrão** | ${mf_time_desvio_fmt}s | ${spa_time_desvio_fmt}s | $(calculate_difference "$mf_time_desvio" "$spa_time_desvio" "s") |"
    write_to_file "| **Coef. Variação** | ${mf_time_cv_fmt}% | ${spa_time_cv_fmt}% | $(calculate_difference "$mf_time_cv" "$spa_time_cv" "%") |"
    write_to_file "| **IC ${NIVEL_CONFIANCA}%** | ±${mf_time_ic_fmt}s | ±${spa_time_ic_fmt}s | $(calculate_difference "$mf_time_ic" "$spa_time_ic" "s") |"
    write_to_file "| **Mínimo** | ${mf_time_min_fmt}s | ${spa_time_min_fmt}s | $(calculate_difference "$mf_time_min" "$spa_time_min" "s") |"
    write_to_file "| **Máximo** | ${mf_time_max_fmt}s | ${spa_time_max_fmt}s | $(calculate_difference "$mf_time_max" "$spa_time_max" "s") |"
    write_to_file ""
    
    # Informações de Build Artifacts (métricas estáticas)
    write_to_file "### Build Artifacts (Métricas Estáticas)"
    write_to_file ""
    write_to_file "| Métrica | Module Federation | Single-SPA | Diferença |"
    write_to_file "|---------|-------------------|------------|-----------|"
    write_to_file "| **Bundle Size** | ${mf_size_fmt} | ${spa_size_fmt} | **$(calculate_difference "$mf_size_media" "$spa_size_media" "size")** |"
    write_to_file "| **Total Files** | ${mf_files_fmt} | ${spa_files_fmt} | $(calculate_difference "$mf_files_media" "$spa_files_media" "files") |"
    write_to_file "| **JS Chunks** | ${mf_chunks_fmt} | ${spa_chunks_fmt} | $(calculate_difference "$mf_chunks_media" "$spa_chunks_media" "chunks") |"
    write_to_file ""
    
    # Análise de significância para Build Time
    local time_diff=$(echo "$mf_time_media - $spa_time_media" | bc -l)
    local time_diff_abs=$(echo "scale=6; sqrt($time_diff * $time_diff)" | bc -l)
    local time_diff_fmt=$(LC_NUMERIC=C printf "%.3f" $time_diff_abs)
    local time_soma_ic=$(echo "$mf_time_ic + $spa_time_ic" | bc -l)
    
    local time_vencedor=""
    local time_significancia=""
    local time_interpretacao=""
    
    if (( $(echo "$time_diff_abs > $time_soma_ic" | bc -l) )); then
        time_significancia="✅ **Estatisticamente significativo**"
        if (( $(echo "$time_diff < 0" | bc -l) )); then
            time_vencedor="**Module Federation**"
            local diff_percent=$(echo "scale=2; ($time_diff_abs / $spa_time_media) * 100" | bc -l)
            time_interpretacao="**Vencedor: Module Federation** (${time_diff_fmt}s mais rápido - ${diff_percent}% de melhoria)"
        else
            time_vencedor="**Single-SPA**"
            local diff_percent=$(echo "scale=2; ($time_diff_abs / $mf_time_media) * 100" | bc -l)
            time_interpretacao="**Vencedor: Single-SPA** (${time_diff_fmt}s mais rápido - ${diff_percent}% de melhoria)"
        fi
    else
        time_significancia="⚠️ **Não estatisticamente significativo**"
        time_vencedor="**Empate**"
        time_interpretacao="Sem vencedor claro (intervalos de confiança se sobrepõem)"
    fi
    
    write_to_file "### Análise Estatística"
    write_to_file ""
    write_to_file "**Diferença na Média:** ${time_diff_fmt}s"
    write_to_file ""
    write_to_file "$time_significancia"
    write_to_file ""
    write_to_file "$time_interpretacao"
    write_to_file ""
    
    # Significância prática
    local time_pratico=""
    if (( $(echo "$time_diff_abs < 1.0" | bc -l) )); then
        time_pratico="ℹ️ **Impacto Prático:** Diferença menor que 1 segundo (impacto limitado no desenvolvimento)"
        write_to_file "$time_pratico"
        write_to_file ""
    fi
    
    # Análise de consistência
    local time_mais_consistente=""
    if (( $(echo "$mf_time_cv < $spa_time_cv" | bc -l) )); then
        time_mais_consistente="**Module Federation** (CV: ${mf_time_cv_fmt}% vs ${spa_time_cv_fmt}%)"
    else
        time_mais_consistente="**Single-SPA** (CV: ${spa_time_cv_fmt}% vs ${mf_time_cv_fmt}%)"
    fi
    write_to_file "**Mais Consistente:** $time_mais_consistente"
    write_to_file ""
    
    # Qualidade dos dados
    write_to_file "**Qualidade dos Dados:**"
    if (( $(echo "$mf_time_cv < 10 && $spa_time_cv < 10" | bc -l) )); then
        write_to_file "- ✅ Excelente consistência em ambas arquiteturas (CV < 10%)"
    elif (( $(echo "$mf_time_cv < 20 && $spa_time_cv < 20" | bc -l) )); then
        write_to_file "- ✅ Boa consistência em ambas arquiteturas (CV < 20%)"
    else
        write_to_file "- ⚠️ Alta variabilidade detectada (CV > 20%) - considere re-testar"
    fi
    write_to_file ""
    
    # Recomendação para este microfrontend
    write_to_file "### Recomendação para $mf_type"
    write_to_file ""
    
    if [ "$time_vencedor" = "**Empate**" ]; then
        write_to_file "- 🟰 **Performance equivalente:** Ambas as arquiteturas apresentam performance de build similar"
        write_to_file "- 📊 **Decisão baseada em outros critérios:** Tamanho do bundle, experiência do desenvolvedor, requisitos da aplicação"
    else
        write_to_file "- 🏆 **Performance superior:** $time_vencedor apresenta melhor performance de build"
        if [ -n "$time_pratico" ]; then
            write_to_file "- ⚖️ **Consideração prática:** $time_pratico"
        fi
    fi
    write_to_file ""
    write_to_file "---"
    write_to_file ""
}

generate_summary() {
    write_to_file "## Análise Comparativa Detalhada"
    write_to_file ""
    write_to_file "Esta seção compara diretamente cada microfrontend entre as duas arquiteturas."
    write_to_file ""
    write_to_file "---"
    write_to_file ""
    
    # Comparar cada tipo de microfrontend
    compare_microfrontends "shell-app"
    compare_microfrontends "checkout-app"
    compare_microfrontends "home-app"
    compare_microfrontends "ui-utils"
    
    # Sumário geral
    write_to_file "## Sumário Geral"
    write_to_file ""
    write_to_file "### Guia de Interpretação"
    write_to_file ""
    write_to_file "- **Significância Estatística:** Resultados marcados com ✓ indicam diferenças que provavelmente não são devidas ao acaso"
    write_to_file "- **Significância Prática:** Mesmo se estatisticamente significativo, pequenas diferenças podem não impactar o desenvolvimento"
    write_to_file "- **Consistência:** Coeficiente de Variação (CV) menor indica performance mais previsível e estável"
    write_to_file "  - CV <10% = consistência excelente"
    write_to_file "  - CV 10-20% = boa consistência"
    write_to_file "  - CV >20% = alta variabilidade (considere re-testar)"
    write_to_file "- **Intervalos de Confiança:** Intervalos que não se sobrepõem = forte evidência de diferença real"
    write_to_file ""
    write_to_file "### Limitações / Ameaças à Validade"
    write_to_file ""
    write_to_file "- Testes conduzidos em ambiente local controlado"
    write_to_file "- Tarefas em segundo plano do sistema, throttling de CPU e cache de I/O podem influenciar os resultados"
    write_to_file "- Tamanho de amostra (n=${EXECUCOES_MEDICAO} por projeto) fornece poder estatístico indicativo"
    write_to_file "- Limpeza de cache entre execuções simula builds 'cold' consistentemente"
    write_to_file "- Variações no tamanho do bundle são naturalmente baixas (arquivos estáticos)"
    write_to_file ""
    write_to_file "---"
    write_to_file ""
    write_to_file "**Metodologia:** Esta análise segue princípios de *The Art of Computer Systems Performance Analysis* de Raj Jain."
    write_to_file "Medidas estatísticas incluem: média (tendência central), desvio padrão (dispersão), coeficiente de variação (variabilidade normalizada),"
    write_to_file "intervalos de confiança (confiança estatística) e detecção de outliers (método da Amplitude Interquartil)."
    write_to_file ""
}

# ============================================================================
# Execução Principal
# ============================================================================

main() {
    echo -e "${AZUL}================================================================${SEM_COR}"
    echo -e "${AZUL}  Benchmark de Performance de Build${SEM_COR}"
    echo -e "${AZUL}  Baseado na Metodologia Estatística de Raj Jain${SEM_COR}"
    echo -e "${AZUL}================================================================${SEM_COR}\n"
    
    # Verificar dependências
    if ! command -v node &> /dev/null; then
        log_error "Node.js não está instalado"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        log_error "npm não está instalado"
        exit 1
    fi
    
    if ! command -v bc &> /dev/null; then
        log_error "bc não está instalado (necessário para cálculos estatísticos)"
        exit 1
    fi
    
    # Criar diretório de saída
    mkdir -p "$DIRETORIO_RESULTADOS"
    
    # Inicializar relatório
    > "$ARQUIVO_RESULTADO"
    generate_report_header
    
    echo -e "${AZUL}Iniciando sequência de benchmark...${SEM_COR}\n"
    
    # Executar benchmark para todos os projetos
    for projeto in "${PROJETOS[@]}"; do
        if [ -d "$projeto" ]; then
            benchmark_project "$projeto"
        else
            log_warning "Projeto não encontrado: $projeto"
        fi
    done
    
    # Gerar análise comparativa
    echo -e "\n${CIANO}Gerando análise comparativa detalhada...${SEM_COR}"
    generate_summary
    
    # Adicionar rodapé
    write_to_file ""
    write_to_file "---"
    write_to_file ""
    write_to_file "*Relatório gerado por clean-build-benchmark.sh em $(date '+%Y-%m-%d %H:%M:%S')*"
    
    # Resumo final
    echo -e "\n${AZUL}================================================================${SEM_COR}"
    echo -e "${AZUL}  Benchmark Completo!${SEM_COR}"
    echo -e "${AZUL}================================================================${SEM_COR}\n"
    echo -e "${VERDE}Resultados salvos em:${SEM_COR}"
    echo -e "  📊 Relatório: ${CIANO}$ARQUIVO_RESULTADO${SEM_COR}\n"
    
    echo -e "${AMARELO}Próximos passos:${SEM_COR}"
    echo -e "  1. Revisar o relatório para significância estatística"
    echo -e "  2. Verificar Coeficiente de Variação para consistência de performance"
    echo -e "  3. Analisar diferenças entre arquiteturas para cada microfrontend"
    echo -e "  4. Re-executar se alta variabilidade detectada (CV >20%)\n"
}

main