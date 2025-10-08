# Lighthouse Benchmark Microfrontends - 2025-10-08 00:00:40

## Configuration
- Number of runs per URL: 5
- System: Linux 6.12.48-1-MANJARO
- Node: v24.8.0
- Lighthouse: 12.8.2

**Metrics collected:**
- FCP (First Contentful Paint)
- LCP (Largest Contentful Paint)
- Performance Score

**Statistics:**
- Mean, Standard Deviation, Min, Max

---

## Rsbuild (Module Federation)

**URL:** `http://localhost:9000`

| Metric | Mean | Standard Deviation | Min | Max |
|--------|------|-------------------|-----|-----|
| **FCP** | 2.417s | .001s | 2.416s | 2.419s |
| **LCP** | 5.882s | .002s | 5.880s | 5.883s |
| **Performance Score** | 75.0 | 0 | - | - |

### Individual values (FCP / LCP in seconds)
- Run 1: FCP 2.416s / LCP 5.881s / Score 75
- Run 2: FCP 2.417s / LCP 5.883s / Score 75
- Run 3: FCP 2.416s / LCP 5.880s / Score 75
- Run 4: FCP 2.416s / LCP 5.880s / Score 75
- Run 5: FCP 2.419s / LCP 5.886s / Score 75

---

## Single-SPA

**URL:** `http://localhost:9000`

| Metric | Mean | Standard Deviation | Min | Max |
|--------|------|-------------------|-----|-----|
| **FCP** | 2.995s | .146s | 2.828s | 2.824s |
| **LCP** | 5.165s | .264s | 5.208s | 4.864s |
| **Performance Score** | 71.8 | 1.720465 | - | - |

### Individual values (FCP / LCP in seconds)
- Run 1: FCP 2.828s / LCP 4.864s / Score 73
- Run 2: FCP 2.824s / LCP 4.854s / Score 74
- Run 3: FCP 3.136s / LCP 5.444s / Score 71
- Run 4: FCP 3.019s / LCP 5.208s / Score 72
- Run 5: FCP 3.166s / LCP 5.454s / Score 69

---

