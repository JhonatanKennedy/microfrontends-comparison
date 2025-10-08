#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

RUNS=5

REPORTS_DIR="reports/build"

mkdir -p "$REPORTS_DIR"

RESULTS_FILE="${REPORTS_DIR}/benchmark_results_$(date +%Y%m%d_%H%M%S).txt"

print_both() {
    local text="$1"
    local color="${2:-$NC}"
    echo -e "${color}${text}${NC}"
    echo "$text" >> "$RESULTS_FILE"
}

> "$RESULTS_FILE"

print_both "====================================="
print_both "  MICROFRONTENDS BENCHMARK"
print_both "====================================="
print_both ""

show_system_info() {
    print_both "=== SYSTEM INFORMATION ===" "$BLUE"
    print_both "Date: $(date)"
    print_both "Node.js: $(node --version)"
    print_both "npm: $(npm --version)"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_both "CPU: $(cat /proc/cpuinfo | grep "model name" | head -1 | cut -d: -f2 | xargs)"
        print_both "RAM: $(free -h | grep Mem | awk '{print $2}')"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_both "CPU: $(sysctl -n machdep.cpu.brand_string)"
        print_both "RAM: $(sysctl -n hw.memsize | awk '{print $0/1024/1024/1024 " GB"}')"
    fi
    
    print_both ""
}

clean_cache() {
    local project_path=$1
    echo -e "${YELLOW}Cleaning cache and dist in $project_path${NC}" >&2
    
    cd "$project_path"
    
    [ -d "dist" ] && rm -rf dist
    [ -d "node_modules/.cache" ] && rm -rf node_modules/.cache
    [ -d ".rsbuild" ] && rm -rf .rsbuild
    [ -d ".rspack" ] && rm -rf .rspack  
    [ -d ".webpack" ] && rm -rf .webpack
    [ -d "node_modules/.vite" ] && rm -rf node_modules/.vite
    
    npm cache clean --force > /dev/null 2>&1 || true
    
    if [ -d "dist" ]; then
        echo -e "${RED}ERROR: Could not remove dist! Trying with sudo...${NC}" >&2
        sudo rm -rf dist || true
    fi
    
    if [ -f "rsbuild.config.ts" ]; then
        cp rsbuild.config.ts rsbuild.config.ts.bak
        
        if ! grep -q "buildCache: false" rsbuild.config.ts; then
            echo -e "${YELLOW}Adding buildCache: false to config${NC}" >&2
        fi
    fi
    
    cd - > /dev/null
    
    sleep 1
}

restore_config() {
    local project_path=$1
    cd "$project_path"
    
    if [ -f "rsbuild.config.ts.bak" ]; then
        mv rsbuild.config.ts.bak rsbuild.config.ts
    fi
    
    cd - > /dev/null
}

measure_build() {
    local project_name=$1
    local project_path=$2
    local run_number=$3
    
    echo -e "${GREEN}Running build $run_number/$RUNS of $project_name${NC}" >&2
    
    cd "$project_path"
    
    BUILD_OUTPUT_FILE="/tmp/build_output_${project_name// /_}_$$.log"
    BUILD_ERROR_FILE="/tmp/build_error_${project_name// /_}_$$.log"
    
    if [ -d "dist" ]; then
        echo -e "${RED}CRITICAL ERROR: dist/ still exists before build!${NC}" >&2
        ls -la dist/ >&2
        cd - > /dev/null
        echo "0.000|N/A|0|0"
        return
    fi
    
    echo -e "${BLUE}Starting build at $(date +%H:%M:%S.%3N)${NC}" >&2
    
    START_TIME=$(date +%s%3N)
    
    set +e
    npm run build > "$BUILD_OUTPUT_FILE" 2> "$BUILD_ERROR_FILE"
    BUILD_EXIT_CODE=$?
    set -e
    
    END_TIME=$(date +%s%3N)
    
    echo -e "${BLUE}Finishing build at $(date +%H:%M:%S.%3N)${NC}" >&2
    
    BUILD_TIME_MS=$((END_TIME - START_TIME))
    BUILD_TIME=$(awk -v ms="$BUILD_TIME_MS" 'BEGIN {printf "%.3f", ms / 1000}')
    
    if [ $BUILD_EXIT_CODE -ne 0 ]; then
        echo -e "${RED}Build ERROR! Exit code: $BUILD_EXIT_CODE${NC}" >&2
        echo -e "${RED}=== OUTPUT ===${NC}" >&2
        tail -30 "$BUILD_OUTPUT_FILE" >&2
        echo -e "${RED}=== ERRORS ===${NC}" >&2
        cat "$BUILD_ERROR_FILE" >&2
        BUILD_TIME="0.000"
    elif [ ! -d "dist" ]; then
        echo -e "${RED}ERROR: Build completed but dist/ was not created!${NC}" >&2
        echo -e "${YELLOW}=== BUILD OUTPUT ===${NC}" >&2
        cat "$BUILD_OUTPUT_FILE" >&2
        BUILD_TIME="0.000"
    else
        echo -e "${GREEN}Build completed successfully!${NC}" >&2
    fi
    
    echo -e "${BLUE}=== Last build lines ===${NC}" >&2
    tail -5 "$BUILD_OUTPUT_FILE" >&2
    
    if [ -d "dist" ]; then
        BUNDLE_SIZE=$(du -sh dist 2>/dev/null | cut -f1)
        FILE_COUNT=$(find dist -type f 2>/dev/null | wc -l | xargs)
        CHUNK_COUNT=$(find dist -type f -name "*.js" 2>/dev/null | wc -l | xargs)
        
        echo -e "${BLUE}Dist created: $BUNDLE_SIZE with $FILE_COUNT files${NC}" >&2
    else
        BUNDLE_SIZE="N/A"
        FILE_COUNT="0"
        CHUNK_COUNT="0"
    fi
    
    rm -f "$BUILD_OUTPUT_FILE" "$BUILD_ERROR_FILE"
    
    cd - > /dev/null
    
    echo "$BUILD_TIME|$BUNDLE_SIZE|$FILE_COUNT|$CHUNK_COUNT"
}

calculate_average() {
    local times=("$@")
    
    echo -e "${YELLOW}DEBUG: Calculating average from: ${times[*]}${NC}" >&2
    
    # Use awk for all calculations to avoid locale issues
    local avg=$(awk -v times="${times[*]}" '
    BEGIN {
        sum = 0
        count = 0
        split(times, arr, " ")
        
        for (i in arr) {
            val = arr[i]
            # Clean leading zeros and convert .xxx to 0.xxx
            gsub(/^0+/, "", val)
            if (val ~ /^\./) val = "0" val
            
            if (val ~ /^[0-9]*\.?[0-9]+$/ && val > 0) {
                sum += val
                count++
                printf "DEBUG: Added %s to sum. Current sum: %.3f, count: %d\n", val, sum, count > "/dev/stderr"
            }
        }
        
        if (count > 0) {
            avg = sum / count
            printf "DEBUG: Final average: %.3f (sum=%.3f, count=%d)\n", avg, sum, count > "/dev/stderr"
            printf "%.3f", avg
        } else {
            print "DEBUG: No valid times to average!" > "/dev/stderr"
            print "0.000"
        }
    }')
    
    echo -e "${GREEN}$avg${NC}" >&2
    echo "$avg"
}

calculate_stddev() {
    local avg=$1
    shift
    local times=("$@")
    
    local stddev=$(awk -v avg="$avg" -v times="${times[*]}" '
    BEGIN {
        sum_sq_diff = 0
        count = 0
        split(times, arr, " ")
        
        for (i in arr) {
            val = arr[i]
            # Clean leading zeros and convert .xxx to 0.xxx
            gsub(/^0+/, "", val)
            if (val ~ /^\./) val = "0" val
            
            if (val ~ /^[0-9]*\.?[0-9]+$/ && val > 0) {
                diff = val - avg
                sum_sq_diff += diff * diff
                count++
            }
        }
        
        if (count > 0) {
            stddev = sqrt(sum_sq_diff / count)
            printf "%.3f", stddev
        } else {
            print "0.000"
        }
    }')
    
    echo "$stddev"
}

benchmark_project() {
    local project_name=$1
    local project_path=$2
    
    print_both "" 
    print_both "================================" "$BLUE"
    print_both "  TESTING: $project_name" "$BLUE"
    print_both "================================" "$BLUE"
    print_both ""
    
    if [ ! -d "$project_path" ]; then
        print_both "ERROR: Project not found at $project_path" "$RED"
        echo "0"
        return
    fi
    
    if [ ! -d "$project_path/node_modules" ]; then
        echo -e "${YELLOW}Installing dependencies at $project_path...${NC}" >&2
        cd "$project_path"
        npm install > /dev/null 2>&1
        cd - > /dev/null
    fi
    
    if ! grep -q '"build"' "$project_path/package.json"; then
        print_both "ERROR: 'build' script not found in package.json" "$RED"
        echo "0"
        return
    fi
    
    local times=()
    local sizes=()
    local files=()
    local chunks=()
    
    for i in $(seq 1 $RUNS); do
        clean_cache "$project_path"
        
        result=$(measure_build "$project_name" "$project_path" "$i")
        
        IFS='|' read -r time size file_count chunk_count <<< "$result"
        
        times+=("$time")
        sizes+=("$size")
        files+=("$file_count")
        chunks+=("$chunk_count")
        
        print_both "  Run $i: ${time}s | ${size} | ${file_count} files | ${chunk_count} JS chunks"
        
        restore_config "$project_path"
        
        sleep 2
    done
    
    print_both ""
    print_both "AVERAGE RESULTS:" "$GREEN"
    
    avg_time=$(calculate_average "${times[@]}")
    stddev_time=$(calculate_stddev "$avg_time" "${times[@]}")
    
    # Calculate coefficient of variation (CV) as percentage
    cv=$(awk -v stddev="$stddev_time" -v avg="$avg_time" 'BEGIN {
        if (avg > 0) printf "%.1f", (stddev/avg)*100
        else print "0.0"
    }')
    
    print_both "  Average time: ${avg_time}s ± ${stddev_time}s (CV: ${cv}%)"
    print_both "  Bundle size: ${sizes[0]}"
    print_both "  Total files: ${files[0]}"
    print_both "  JS chunks: ${chunks[0]}"
    
    # Return ONLY the average, nothing else
    echo "$avg_time" | tr -cd '0-9.'
}

benchmark_architecture() {
    local arch_name=$1
    local base_path=$2
    shift 2
    local apps=("$@")
    
    print_both ""
    print_both "########################################" "$BLUE"
    print_both "  ARCHITECTURE: $arch_name" "$BLUE"
    print_both "########################################" "$BLUE"
    print_both ""
    
    local -a averages=()
    local app_count=0
    
    for app in "${apps[@]}"; do
        local app_path="$base_path/$app"
        if [ -d "$app_path" ]; then
            echo -e "${YELLOW}DEBUG: Starting benchmark for $app${NC}" >&2
            
            # Capture ONLY stdout from benchmark_project
            app_avg_time=$(benchmark_project "$arch_name - $app" "$app_path" 2>&1 | tail -1)
            
            echo -e "${YELLOW}DEBUG: Raw output from benchmark_project: '$app_avg_time'${NC}" >&2
            
            # Clean the value
            app_avg_clean=$(echo "$app_avg_time" | tr -cd '0-9.')
            
            echo -e "${YELLOW}DEBUG: Cleaned average from $app: '$app_avg_clean'${NC}" >&2
            
            if [[ "$app_avg_clean" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                is_positive=$(awk -v t="$app_avg_clean" 'BEGIN {print (t > 0) ? 1 : 0}')
                
                if [ "$is_positive" -eq 1 ]; then
                    averages+=("$app_avg_clean")
                    app_count=$((app_count + 1))
                    echo -e "${YELLOW}DEBUG: Stored average $app_avg_clean for $app${NC}" >&2
                else
                    print_both "WARNING: Invalid time for $app: $app_avg_clean (not positive)" "$YELLOW"
                fi
            else
                print_both "WARNING: Invalid time format for $app: $app_avg_clean" "$YELLOW"
            fi
        else
            print_both "WARNING: $app not found at $app_path" "$YELLOW"
        fi
    done
    
    local total_time="0.000"
    if [ ${#averages[@]} -gt 0 ]; then
        echo -e "${YELLOW}DEBUG: Summing averages: ${averages[*]}${NC}" >&2
        total_time=$(awk -v avgs="${averages[*]}" '
        BEGIN {
            sum = 0
            split(avgs, arr, " ")
            for (i in arr) {
                sum += arr[i]
            }
            printf "%.3f", sum
        }')
        echo -e "${YELLOW}DEBUG: Total sum of averages: $total_time${NC}" >&2
    fi
    
    if [ $app_count -gt 0 ]; then
        print_both ""
        print_both ">>> TOTAL $arch_name <<<" "$GREEN"
        print_both "  Total average build time: ${total_time}s"
        print_both "  Applications: $app_count"
        print_both ""
    fi
    
    echo "$total_time"
}

main() {
    show_system_info
    
    print_both "Number of runs per project: $RUNS" "$YELLOW"
    print_both ""
    
    APPS=("shell-app" "checkout-app" "home-app" "ui-utils")
    
    MF_BASE="./mf-module-federation"
    SPA_BASE="./mf-single-spa"
    
    print_both "=====================================" "$YELLOW"
    print_both "  STARTING: MODULE FEDERATION" "$YELLOW"
    print_both "=====================================" "$YELLOW"
    mf_time=$(benchmark_architecture "Module Federation" "$MF_BASE" "${APPS[@]}")
    
    print_both "=====================================" "$YELLOW"
    print_both "  STARTING: SINGLE-SPA" "$YELLOW"
    print_both "=====================================" "$YELLOW"
    spa_time=$(benchmark_architecture "Single-SPA" "$SPA_BASE" "${APPS[@]}")
    
    print_both ""
    print_both "=====================================" "$BLUE"
    print_both "  FINAL OVERALL COMPARISON" "$BLUE"
    print_both "=====================================" "$BLUE"
    print_both ""
    
    mf_clean=$(echo "$mf_time" | sed 's/\x1b\[[0-9;]*m//g' | tr -cd '0-9.' | grep -oE '^[0-9]+\.?[0-9]*' || echo "0")
    spa_clean=$(echo "$spa_time" | sed 's/\x1b\[[0-9;]*m//g' | tr -cd '0-9.' | grep -oE '^[0-9]+\.?[0-9]*' || echo "0")
    
    if [[ ! "$mf_clean" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        mf_clean="0"
    fi
    
    if [[ ! "$spa_clean" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        spa_clean="0"
    fi
    
    mf_positive=$(awk -v t="$mf_clean" 'BEGIN {print (t > 0) ? 1 : 0}')
    spa_positive=$(awk -v t="$spa_clean" 'BEGIN {print (t > 0) ? 1 : 0}')
    
    if [ "$mf_positive" -eq 1 ] && [ "$spa_positive" -eq 1 ]; then
        diff=$(awk -v m="$mf_clean" -v s="$spa_clean" 'BEGIN {printf "%.2f", ((m - s) / s) * 100}')
        abs_diff=$(awk -v m="$mf_clean" -v s="$spa_clean" 'BEGIN {printf "%.3f", m - s}')
        
        print_both "Module Federation (sum of averages): ${mf_clean}s"
        print_both "Single-SPA (sum of averages): ${spa_clean}s"
        print_both "Absolute difference: ${abs_diff}s"
        print_both ""
        
        mf_slower=$(awk -v m="$mf_clean" -v s="$spa_clean" 'BEGIN {print (m > s) ? 1 : 0}')
        
        if [ "$mf_slower" -eq 1 ]; then
            print_both "Module Federation is ${diff#-}% slower" "$YELLOW"
        else
            print_both "Module Federation is ${diff#-}% faster" "$GREEN"
        fi
    else
        print_both "ERROR: Could not calculate comparison (MF=$mf_clean, SPA=$spa_clean)" "$RED"
    fi
    
    print_both ""
    print_both "=====================================" "$GREEN"
    print_both "Results saved to: $RESULTS_FILE" "$GREEN"
    print_both "=====================================" "$GREEN"
}

if ! command -v bc &> /dev/null; then
    echo -e "${RED}ERROR: 'bc' is not installed. Install with: sudo apt install bc${NC}"
    exit 1
fi

if ! command -v awk &> /dev/null; then
    echo -e "${RED}ERROR: 'awk' is not installed.${NC}"
    exit 1
fi

main