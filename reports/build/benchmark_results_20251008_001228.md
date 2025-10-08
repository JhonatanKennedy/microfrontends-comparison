# Microfrontends Benchmark Report

## System Information

- Sistema: Linux 6.12.48-1-MANJARO
- Node.js: v24.8.0
- npm: 11.6.0
- CPU: AMD Ryzen 7 7700X 8-Core Processor
- RAM: 30Gi
- Runs per project: 5

---

## Module Federation


### Module Federation - shell-app

| Run | Time | Bundle Size | Files | JS Chunks |
|-----|------|-------------|-------|-----------|
| 1 | 0.398s | 432K | 13 | 5 |
| 2 | 0.409s | 432K | 13 | 5 |
| 3 | 0.406s | 432K | 13 | 5 |
| 4 | 0.409s | 432K | 13 | 5 |
| 5 | 0.410s | 432K | 13 | 5 |

**Results:**

- **Average time:** 0.406s ± 0.004s (CV: 1.0%)
- **Bundle size:** 432K
- **Total files:** 13
- **JS chunks:** 5

### Module Federation - checkout-app

| Run | Time | Bundle Size | Files | JS Chunks |
|-----|------|-------------|-------|-----------|
| 1 | 0.416s | 544K | 18 | 7 |
| 2 | 0.412s | 544K | 18 | 7 |
| 3 | 0.414s | 544K | 18 | 7 |
| 4 | 0.413s | 544K | 18 | 7 |
| 5 | 0.424s | 544K | 18 | 7 |

**Results:**

- **Average time:** 0.416s ± 0.004s (CV: 1.0%)
- **Bundle size:** 544K
- **Total files:** 18
- **JS chunks:** 7

### Module Federation - home-app

| Run | Time | Bundle Size | Files | JS Chunks |
|-----|------|-------------|-------|-----------|
| 1 | 0.418s | 544K | 18 | 7 |
| 2 | 0.416s | 544K | 18 | 7 |
| 3 | 0.413s | 544K | 18 | 7 |
| 4 | 0.422s | 544K | 18 | 7 |
| 5 | 0.414s | 544K | 18 | 7 |

**Results:**

- **Average time:** 0.417s ± 0.003s (CV: 0.7%)
- **Bundle size:** 544K
- **Total files:** 18
- **JS chunks:** 7

### Module Federation - ui-utils

| Run | Time | Bundle Size | Files | JS Chunks |
|-----|------|-------------|-------|-----------|
| 1 | 0.402s | 344K | 15 | 7 |
| 2 | 0.401s | 344K | 15 | 7 |
| 3 | 0.409s | 344K | 15 | 7 |
| 4 | 0.409s | 344K | 15 | 7 |
| 5 | 0.406s | 344K | 15 | 7 |

**Results:**

- **Average time:** 0.405s ± 0.003s (CV: 0.7%)
- **Bundle size:** 344K
- **Total files:** 15
- **JS chunks:** 7

### Summary

| Metric | Value |
|--------|-------|
| **Total average build time** | 1.644s |
| **Applications tested** | 4 |


---

## Single-SPA


### Single-SPA - shell-app

| Run | Time | Bundle Size | Files | JS Chunks |
|-----|------|-------------|-------|-----------|
| 1 | 1.297s | 64K | 4 | 1 |
| 2 | 1.314s | 64K | 4 | 1 |
| 3 | 1.311s | 64K | 4 | 1 |
| 4 | 1.302s | 64K | 4 | 1 |
| 5 | 1.323s | 64K | 4 | 1 |

**Results:**

- **Average time:** 1.309s ± 0.009s (CV: 0.7%)
- **Bundle size:** 64K
- **Total files:** 4
- **JS chunks:** 1

### Single-SPA - checkout-app

| Run | Time | Bundle Size | Files | JS Chunks |
|-----|------|-------------|-------|-----------|
| 1 | 1.636s | 108K | 9 | 1 |
| 2 | 1.669s | 108K | 9 | 1 |
| 3 | 1.714s | 108K | 9 | 1 |
| 4 | 1.621s | 108K | 9 | 1 |
| 5 | 1.629s | 108K | 9 | 1 |

**Results:**

- **Average time:** 1.654s ± 0.034s (CV: 2.1%)
- **Bundle size:** 108K
- **Total files:** 9
- **JS chunks:** 1

### Single-SPA - home-app

| Run | Time | Bundle Size | Files | JS Chunks |
|-----|------|-------------|-------|-----------|
| 1 | 1.649s | 136K | 9 | 1 |
| 2 | 1.643s | 136K | 9 | 1 |
| 3 | 1.657s | 136K | 9 | 1 |
| 4 | 1.667s | 136K | 9 | 1 |
| 5 | 1.656s | 136K | 9 | 1 |

**Results:**

- **Average time:** 1.654s ± 0.008s (CV: 0.5%)
- **Bundle size:** 136K
- **Total files:** 9
- **JS chunks:** 1

### Single-SPA - ui-utils

| Run | Time | Bundle Size | Files | JS Chunks |
|-----|------|-------------|-------|-----------|
| 1 | 1.874s | 1,5M | 19 | 1 |
| 2 | 1.902s | 1,5M | 19 | 1 |
| 3 | 1.887s | 1,5M | 19 | 1 |
| 4 | 1.899s | 1,5M | 19 | 1 |
| 5 | 1.900s | 1,5M | 19 | 1 |

**Results:**

- **Average time:** 1.892s ± 0.011s (CV: 0.6%)
- **Bundle size:** 1,5M
- **Total files:** 19
- **JS chunks:** 1

### Summary

| Metric | Value |
|--------|-------|
| **Total average build time** | 6.509s |
| **Applications tested** | 4 |


---

## Final Comparison

| Architecture | Total Time |
|--------------|------------|
| **Module Federation** | 1.644s
| **Single-SPA** | 6.509s

### Analysis

- **Absolute difference:** 4.865s
- **Percentage difference:** 74.74%

---

*Report generated on qua 08 out 2025 00:15:14 -03*

📊 Results saved to: `reports/build/benchmark_results_20251008_001228.md`
