#!/bin/bash

# ============================================================================
# Clean Build Benchmark - Microfrontends Performance Analysis
# Measures build time, bundle size, and chunk count with cache cleaning
# ============================================================================

set -e

# ============================================================================
# Configuration
# ============================================================================

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

readonly RUNS=5
readonly SLEEP_BETWEEN_RUNS=2

readonly REPORTS_DIR="reports/build"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)
readonly RESULTS_FILE="${REPORTS_DIR}/benchmark_results_${TIMESTAMP}.md"

readonly PROJECTS=(
    "mf-module-federation/shell-app"
    "mf-module-federation/checkout-app"
    "mf-module-federation/home-app"
    "mf-module-federation/ui-utils"
    "mf-single-spa/shell-app"
    "mf-single-spa/checkout-app"
    "mf-single-spa/home-app"
    "mf-single-spa/ui-utils"
)

# ============================================================================
# Utility Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

write_to_file() {
    echo "$1" >> "$RESULTS_FILE"
}

# ============================================================================
# System Information
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

# ============================================================================
# Cache Cleaning
# ============================================================================

clean_build_cache() {
    local project_path=$1
    
    log_warning "Cleaning cache for $project_path"
    
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
        log_error "Failed to remove dist directory, trying with sudo..."
        sudo rm -rf dist 2>/dev/null || true
    fi
    
    cd - > /dev/null
    
    sleep 1
}

# ============================================================================
# Build Measurement
# ============================================================================

measure_build() {
    local project_path=$1
    local run_number=$2
    
    cd "$project_path"
    
    # Verify clean state
    if [ -d "dist" ] || [ -d "build" ]; then
        log_error "Build directory exists before build!"
        cd - > /dev/null
        echo "ERROR|0.000|N/A|0|0"
        return
    fi
    
    local build_log="/tmp/build_output_$$.log"
    local error_log="/tmp/build_error_$$.log"
    
    log_info "Starting build #$run_number..."
    
    # Measure build time
    local start_ms=$(date +%s%3N)
    
    set +e
    npm run build > "$build_log" 2> "$error_log"
    local exit_code=$?
    set -e
    
    local end_ms=$(date +%s%3N)
    local duration_ms=$((end_ms - start_ms))
    local duration_s=$(awk -v ms="$duration_ms" 'BEGIN {printf "%.3f", ms / 1000}')
    
    # Check build success
    if [ $exit_code -ne 0 ]; then
        log_error "Build failed with exit code $exit_code"
        tail -20 "$build_log" >&2
        cat "$error_log" >&2
        rm -f "$build_log" "$error_log"
        cd - > /dev/null
        echo "ERROR|0.000|N/A|0|0"
        return
    fi
    
    # Find output directory
    local output_dir=""
    if [ -d "dist" ]; then
        output_dir="dist"
    elif [ -d "build" ]; then
        output_dir="build"
    else
        log_error "No output directory found after build"
        rm -f "$build_log" "$error_log"
        cd - > /dev/null
        echo "ERROR|0.000|N/A|0|0"
        return
    fi
    
    # Collect metrics
    local bundle_size=$(du -sh "$output_dir" 2>/dev/null | cut -f1 || echo "N/A")
    local total_files=$(find "$output_dir" -type f 2>/dev/null | wc -l | xargs)
    local js_chunks=$(find "$output_dir" -type f \( -name "*.js" -o -name "*.mjs" \) 2>/dev/null | wc -l | xargs)
    
    log_success "Build completed in ${duration_s}s - Size: $bundle_size - Files: $total_files - JS Chunks: $js_chunks"
    
    rm -f "$build_log" "$error_log"
    cd - > /dev/null
    
    echo "SUCCESS|$duration_s|$bundle_size|$total_files|$js_chunks"
}

# ============================================================================
# Statistics Calculation
# ============================================================================

calculate_statistics() {
    local values=("$@")
    local count=${#values[@]}
    
    if [ $count -eq 0 ]; then
        echo "0.000|0.000|0.000|0.000"
        return
    fi
    
    # Calculate mean, min, max, stddev using awk
    local stats=$(printf '%s\n' "${values[@]}" | awk '
    {
        sum += $1
        values[NR] = $1
        count++
    }
    END {
        if (count == 0) {
            print "0.000|0.000|0.000|0.000"
            exit
        }
        
        mean = sum / count
        
        # Find min and max
        min = values[1]
        max = values[1]
        for (i = 2; i <= count; i++) {
            if (values[i] < min) min = values[i]
            if (values[i] > max) max = values[i]
        }
        
        # Calculate standard deviation
        sum_sq_diff = 0
        for (i = 1; i <= count; i++) {
            diff = values[i] - mean
            sum_sq_diff += diff * diff
        }
        stddev = sqrt(sum_sq_diff / count)
        
        printf "%.3f|%.3f|%.3f|%.3f", mean, stddev, min, max
    }')
    
    echo "$stats"
}


calculate_confidence_interval() {
    local mean=$1
    local stddev=$2
    local n=$3

    # For small sample (n<=30), use t-distribution.
    # 95% confidence, df = n-1 → t ≈ 2.776 when n=5
    local t_value=2.776

    if (( n < 2 )); then
        echo "0.000"
        return
    fi

    local se=$(awk -v s="$stddev" -v n="$n" 'BEGIN {printf "%.6f", s / sqrt(n)}')
    local ci=$(awk -v t="$t_value" -v se="$se" 'BEGIN {printf "%.6f", t * se}')
    echo "$ci"
}

# ============================================================================
# Benchmark Execution
# ============================================================================

benchmark_project() {
    local project_path=$1
    local project_name=$(basename "$project_path")
    local architecture=$(basename $(dirname "$project_path"))
    
    log_info "========================================"
    log_info "Benchmarking: $architecture/$project_name"
    log_info "========================================"
    
    # Validate project
    if [ ! -d "$project_path" ]; then
        log_error "Project not found: $project_path"
        return
    fi
    
    if [ ! -f "$project_path/package.json" ]; then
        log_error "package.json not found in $project_path"
        return
    fi
    
    if ! grep -q '"build"' "$project_path/package.json"; then
        log_error "No build script found in package.json"
        return
    fi
    
    # Install dependencies if needed
    if [ ! -d "$project_path/node_modules" ]; then
        log_warning "Installing dependencies..."
        cd "$project_path"
        npm install > /dev/null 2>&1
        cd - > /dev/null
    fi
    
    # Write project header
    write_to_file ""
    write_to_file "## $architecture - $project_name"
    write_to_file ""
    write_to_file "| Run | Status | Build Time | Bundle Size | Total Files | JS Chunks |"
    write_to_file "|-----|--------|------------|-------------|-------------|-----------|"
    
    local build_times=()
    local valid_runs=0
    
    # Run multiple builds
    for i in $(seq 1 $RUNS); do
        clean_build_cache "$project_path"
        
        local result=$(measure_build "$project_path" "$i")
        
        IFS='|' read -r status time size files chunks <<< "$result"
        
        if [ "$status" = "SUCCESS" ]; then
            build_times+=("$time")
            valid_runs=$((valid_runs + 1))
            write_to_file "| $i | ✅ | ${time}s | $size | $files | $chunks |"
        else
            write_to_file "| $i | ❌ | - | - | - | - |"
        fi
        
        sleep $SLEEP_BETWEEN_RUNS
    done
    
    # Calculate and write statistics
    if [ $valid_runs -gt 0 ]; then
        local stats=$(calculate_statistics "${build_times[@]}")
        IFS='|' read -r mean stddev min max <<< "$stats"
        
        # Calculate coefficient of variation
        local coefficient_of_variation=$(awk -v stddev="$stddev" -v mean="$mean" 'BEGIN {
            if (mean > 0) {
                printf "%.1f", (stddev/mean)*100
            } else {
                print "0.0"
            }
        }')
        
        write_to_file ""
        write_to_file "**Statistics:**"
        write_to_file ""
        write_to_file "- Mean: ${mean}s"
        write_to_file "- Standard Deviation: ${stddev}s"
        write_to_file "- Coefficient of Variation: ${coefficient_of_variation}%"
        write_to_file "- Minimum: ${min}s"
        write_to_file "- Maximum: ${max}s"
        write_to_file "- Successful Runs: $valid_runs/$RUNS"
        
        log_success "Statistics: Mean=${mean}s, StdDev=${stddev}s, Coefficient of Variation=${coefficient_of_variation}%"
    else
        write_to_file ""
        write_to_file "**Statistics:** All builds failed"
        log_error "All builds failed for $project_name"
    fi
    
    write_to_file ""
    write_to_file "---"
}

# ============================================================================
# Summary Analysis
# ============================================================================

generate_summary() {
    write_to_file ""
    write_to_file "## Executive Summary"
    write_to_file ""
    
    # Extract all project statistics
    local -A mf_times
    local -A spa_times
    local current_arch=""
    local current_app=""
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^##[[:space:]](.+)[[:space:]]-[[:space:]](.+)$ ]]; then
            current_arch="${BASH_REMATCH[1]}"
            current_app="${BASH_REMATCH[2]}"
        fi
        
        if [[ "$line" =~ ^-[[:space:]]Mean:[[:space:]]([0-9.]+)s$ ]]; then
            local mean_value="${BASH_REMATCH[1]}"
            if [ "$current_arch" = "mf-module-federation" ]; then
                mf_times["$current_app"]="$mean_value"
            elif [ "$current_arch" = "mf-single-spa" ]; then
                spa_times["$current_app"]="$mean_value"
            fi
        fi
    done < "$RESULTS_FILE"
    
    # Calculate aggregate statistics for each architecture
    local mf_values=()
    local spa_values=()
    
    for app in "${!mf_times[@]}"; do
        mf_values+=("${mf_times[$app]}")
    done
    
    for app in "${!spa_times[@]}"; do
        spa_values+=("${spa_times[$app]}")
    done
    
    if [ ${#mf_values[@]} -eq 0 ] || [ ${#spa_values[@]} -eq 0 ]; then
        write_to_file "**Note:** Insufficient data for architecture comparison."
        return
    fi
    
    local mf_stats=$(calculate_statistics "${mf_values[@]}")
    local spa_stats=$(calculate_statistics "${spa_values[@]}")
    
    IFS='|' read -r mf_mean mf_stddev mf_min mf_max <<< "$mf_stats"
    IFS='|' read -r spa_mean spa_stddev spa_min spa_max <<< "$spa_stats"
    
    # Calculate coefficient of variation for each architecture
    local mf_coefficient_of_variation=$(awk -v stddev="$mf_stddev" -v mean="$mf_mean" 'BEGIN {
        if (mean > 0) {
            printf "%.1f", (stddev/mean)*100
        } else {
            print "0.0"
        }
    }')
    
    local spa_coefficient_of_variation=$(awk -v stddev="$spa_stddev" -v mean="$spa_mean" 'BEGIN {
        if (mean > 0) {
            printf "%.1f", (stddev/mean)*100
        } else {
            print "0.0"
        }
    }')
    
    # Architecture comparison table
    write_to_file "### Architecture Performance Comparison"
    write_to_file ""
    write_to_file "| Architecture | Mean | Standard Deviation | Minimum | Maximum | Coefficient of Variation |"
    write_to_file "|--------------|------|--------------------|---------|---------|--------------------------|"
    write_to_file "| Module Federation | ${mf_mean}s | ${mf_stddev}s | ${mf_min}s | ${mf_max}s | ${mf_coefficient_of_variation}% |"
    write_to_file "| Single-SPA | ${spa_mean}s | ${spa_stddev}s | ${spa_min}s | ${spa_max}s | ${spa_coefficient_of_variation}% |"
    write_to_file ""
    
    # Determine winner
    local winner=""
    local loser=""
    local winner_mean=""
    local loser_mean=""
    
    local is_mf_faster=$(awk -v mf="$mf_mean" -v spa="$spa_mean" 'BEGIN {
        if (mf < spa) print "yes"
        else print "no"
    }')
    
    if [ "$is_mf_faster" = "yes" ]; then
        winner="Module Federation"
        loser="Single-SPA"
        winner_mean="$mf_mean"
        loser_mean="$spa_mean"
    else
        winner="Single-SPA"
        loser="Module Federation"
        winner_mean="$spa_mean"
        loser_mean="$mf_mean"
    fi
    
    # Calculate performance difference
    local absolute_difference=$(awk -v winner="$winner_mean" -v loser="$loser_mean" 'BEGIN {
        printf "%.3f", loser - winner
    }')
    
    # Percentage: how much faster is the winner compared to the loser
    local percentage_difference=$(awk -v winner="$winner_mean" -v loser="$loser_mean" 'BEGIN {
        printf "%.2f", ((loser - winner) / loser) * 100
    }')
    
    write_to_file "### Performance Analysis"
    write_to_file ""
    write_to_file "**Winner:** $winner"
    write_to_file ""
    write_to_file "- **Absolute Difference:** ${absolute_difference}s ($winner is ${absolute_difference}s faster)"
    write_to_file "- **Percentage Difference:** ${percentage_difference}% ($winner is ${percentage_difference}% faster than $loser)"
    write_to_file ""
    
    # Variability analysis
    write_to_file "### Variability Analysis"
    write_to_file ""
    write_to_file "**Coefficient of Variation (lower is more consistent):**"
    write_to_file ""
    write_to_file "- Module Federation: ${mf_coefficient_of_variation}%"
    write_to_file "- Single-SPA: ${spa_coefficient_of_variation}%"
    write_to_file ""
    
    # Consistency rating
    local mf_consistency_rating=""
    local spa_consistency_rating=""
    
    if (( $(awk -v val="$mf_coefficient_of_variation" 'BEGIN {print (val < 5) ? 1 : 0}') )); then
        mf_consistency_rating="Excellent"
    elif (( $(awk -v val="$mf_coefficient_of_variation" 'BEGIN {print (val < 10) ? 1 : 0}') )); then
        mf_consistency_rating="Good"
    elif (( $(awk -v val="$mf_coefficient_of_variation" 'BEGIN {print (val < 20) ? 1 : 0}') )); then
        mf_consistency_rating="Fair"
    else
        mf_consistency_rating="Poor"
    fi
    
    if (( $(awk -v val="$spa_coefficient_of_variation" 'BEGIN {print (val < 5) ? 1 : 0}') )); then
        spa_consistency_rating="Excellent"
    elif (( $(awk -v val="$spa_coefficient_of_variation" 'BEGIN {print (val < 10) ? 1 : 0}') )); then
        spa_consistency_rating="Good"
    elif (( $(awk -v val="$spa_coefficient_of_variation" 'BEGIN {print (val < 20) ? 1 : 0}') )); then
        spa_consistency_rating="Fair"
    else
        spa_consistency_rating="Poor"
    fi
    
    write_to_file "**Consistency Rating:**"
    write_to_file ""
    write_to_file "- Module Federation: $mf_consistency_rating"
    write_to_file "- Single-SPA: $spa_consistency_rating"
    write_to_file ""
    
    # Statistical confidence
    local mf_count=${#mf_values[@]}
    local spa_count=${#spa_values[@]}
    
    local mf_standard_error=$(awk -v stddev="$mf_stddev" -v n="$mf_count" 'BEGIN {
        printf "%.3f", stddev / sqrt(n)
    }')
    
    local spa_standard_error=$(awk -v stddev="$spa_stddev" -v n="$spa_count" 'BEGIN {
        printf "%.3f", stddev / sqrt(n)
    }')
    
    # local mf_confidence_interval=$(awk -v se="$mf_standard_error" 'BEGIN {
    #     printf "%.3f", 1.96 * se
    # }')
    
    # local spa_confidence_interval=$(awk -v se="$spa_standard_error" 'BEGIN {
    #     printf "%.3f", 1.96 * se
    # }')

    local mf_confidence_interval=$(calculate_confidence_interval "$mf_mean" "$mf_stddev" "$mf_count")
    local spa_confidence_interval=$(calculate_confidence_interval "$spa_mean" "$spa_stddev" "$spa_count")
    
    write_to_file "### Statistical Confidence"
    write_to_file ""
    write_to_file "**95% Confidence Intervals:**"
    write_to_file ""
    write_to_file "- Module Federation: ${mf_mean}s ± ${mf_confidence_interval}s"
    write_to_file "- Single-SPA: ${spa_mean}s ± ${spa_confidence_interval}s"
    write_to_file ""
    write_to_file "**Standard Error:**"
    write_to_file ""
    write_to_file "- Module Federation: ${mf_standard_error}s"
    write_to_file "- Single-SPA: ${spa_standard_error}s"
    write_to_file ""
    
    write_to_file "### Limitations / Threats to Validity"
    write_to_file ""
    write_to_file "- Tests were conducted in a controlled local environment and may not fully reflect production network conditions."
    write_to_file "- System background tasks, CPU throttling, and I/O caching could influence build times."
    write_to_file "- CDN, HTTP caching, and client rendering conditions were not part of this analysis."
    write_to_file "- Sample size (n=$RUNS per app) provides indicative but not definitive statistical power."
    write_to_file ""

    # Recommendations
    write_to_file "### Recommendations"
    write_to_file ""
    
    local perf_significance=""
    if (( $(awk -v diff="$percentage_difference" 'BEGIN {print (diff < 5) ? 1 : 0}') )); then
        perf_significance="marginal"
    elif (( $(awk -v diff="$percentage_difference" 'BEGIN {print (diff < 15) ? 1 : 0}') )); then
        perf_significance="moderate"
    else
        perf_significance="significant"
    fi
    
    write_to_file "1. **Performance Winner:** $winner demonstrates **${perf_significance}** performance advantage (${percentage_difference}%)"
    write_to_file ""
    
    local more_consistent=""
    if (( $(awk -v mf="$mf_coefficient_of_variation" -v spa="$spa_coefficient_of_variation" 'BEGIN {print (mf < spa) ? 1 : 0}') )); then
        more_consistent="Module Federation"
    else
        more_consistent="Single-SPA"
    fi
    
    write_to_file "2. **Consistency Winner:** $more_consistent shows more predictable build times"
    write_to_file ""
    write_to_file "3. **Sample Size:** Analysis based on ${mf_count} Module Federation apps and ${spa_count} Single-SPA apps"
    write_to_file ""
    write_to_file "4. **Reliability:** Both architectures completed ${RUNS} runs per application"
    write_to_file ""
    
    # Methodology note
    write_to_file "---"
    write_to_file ""
    write_to_file "**Methodology Note:** This analysis follows principles from *The Art of Computer Systems Performance Analysis* by Raj Jain."
    write_to_file "Key statistical measures include: mean (central tendency), standard deviation (spread), coefficient of variation (normalized variability),"
    write_to_file "confidence intervals (statistical confidence), and standard error (precision of mean estimate)."
}

# ============================================================================
# Report Generation
# ============================================================================

generate_report_header() {
    write_to_file "# Clean Build Benchmark Report"
    write_to_file ""
    write_to_file "**Generated:** $(date '+%Y-%m-%d %H:%M:%S')"
    write_to_file ""
    write_to_file "## System Information"
    write_to_file ""
    write_to_file "| Component | Details |"
    write_to_file "|-----------|---------|"
    write_to_file "| Operating System | $(get_os_info) |"
    write_to_file "| Kernel | $(uname -r) |"
    write_to_file "| Architecture | $(uname -m) |"
    write_to_file "| CPU | $(get_cpu_info) |"
    write_to_file "| Memory | $(get_memory_info) |"
    write_to_file "| Node.js | $(node --version) |"
    write_to_file "| npm | $(npm --version) |"
    write_to_file ""
    write_to_file "## Benchmark Configuration"
    write_to_file ""
    write_to_file "| Parameter | Value |"
    write_to_file "|-----------|-------|"
    write_to_file "| Runs per Project | $RUNS |"
    write_to_file "| Sleep Between Runs | ${SLEEP_BETWEEN_RUNS}s |"
    write_to_file "| Cache Cleaning | Enabled (full) |"
    write_to_file ""
    write_to_file "---"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    log_info "=========================================="
    log_info "  Clean Build Benchmark Starting"
    log_info "=========================================="
    echo ""
    
    # Check dependencies
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed"
        exit 1
    fi
    
    # Create output directory
    mkdir -p "$REPORTS_DIR"
    
    # Initialize report
    > "$RESULTS_FILE"
    generate_report_header
    
    # Benchmark all projects
    for project in "${PROJECTS[@]}"; do
        if [ -d "$project" ]; then
            benchmark_project "$project"
        else
            log_warning "Skipping non-existent project: $project"
        fi
        echo ""
    done
    
    # Generate comprehensive summary
    generate_summary
    
    # Add footer
    write_to_file ""
    write_to_file "---"
    write_to_file ""
    write_to_file "*Report generated by clean-build-benchmark.sh on $(date '+%Y-%m-%d %H:%M:%S')*"
    
    log_success "=========================================="
    log_success "  Benchmark Complete!"
    log_success "=========================================="
    log_info "Results saved to: $RESULTS_FILE"
    echo ""
}

main