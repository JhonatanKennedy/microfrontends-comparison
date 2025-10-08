# Lighthouse Benchmark Microfrontends - 2025-10-07 22:44:03

## Configuração
- Número de execuções por URL: 5
- Sistema: Linux 6.12.48-1-MANJARO
- Node: v24.8.0
- Lighthouse: 12.8.2

**Métricas coletadas:**
- FCP (First Contentful Paint)
- LCP (Largest Contentful Paint)
- Performance Score

**Estatísticas:**
- Média, Desvio Padrão, Min, Max

---

## Rsbuild (Module Federation)

**URL:** `http://localhost:9000`

| Métrica | Média | Desvio Padrão | Min | Max |
|---------|-------|---------------|-----|-----|
| **FCP** | 2.417s | 0s | 2.417s | 2.418s |
| **LCP** | 5.882s | .001s | 5.880s | 5.882s |
| **Performance Score** | 75.0 | 0 | - | - |

### Valores individuais (FCP / LCP em segundos)
- Run 1: FCP 2.417s / LCP 5.883s / Score 75
- Run 2: FCP 2.418s / LCP 5.884s / Score 75
- Run 3: FCP 2.416s / LCP 5.880s / Score 75
- Run 4: FCP 2.416s / LCP 5.880s / Score 75
- Run 5: FCP 2.417s / LCP 5.882s / Score 75

---

## Single-SPA

**URL:** `http://localhost:9000`

| Métrica | Média | Desvio Padrão | Min | Max |
|---------|-------|---------------|-----|-----|
| **FCP** | 3.199s | .308s | 3.775s | 3.237s |
| **LCP** | 5.388s | .368s | 5.263s | 5.581s |
| **Performance Score** | 68.2 | 3.310589 | - | - |

### Valores individuais (FCP / LCP em segundos)
- Run 1: FCP 3.775s / LCP 6.005s / Score 63
- Run 2: FCP 3.237s / LCP 5.581s / Score 66
- Run 3: FCP 3.028s / LCP 5.115s / Score 69
- Run 4: FCP 2.894s / LCP 4.975s / Score 72
- Run 5: FCP 3.061s / LCP 5.263s / Score 71

---

