# Relatório de Benchmark de Performance com Lighthouse
**Gerado em:** 2025-11-21 11:29:51 -03

## Design Experimental (Metodologia Raj Jain)

### Configuração Estatística
- **Execuções de aquecimento:** 3 (excluídas da análise)
- **Execuções de medição:** 30 por aplicação
- **Nível de confiança:** 95%
- **Delay entre execuções:** 5s
- **Detecção de outliers:** Método da Amplitude Interquartil (1.5 × Amplitude Interquartil)

### Ambiente do Sistema
- **Sistema Operacional:** Linux 6.12.48-1-MANJARO
- **Arquitetura:** x86_64
- **Node.js:** v24.8.0
- **Lighthouse:** 12.8.2
- **Docker:** Docker version 28.4.0, build d8eb465
- **Memória Disponível:** 30Gi 
- **Processador:** AMD Ryzen 7 7700X 8-Core Processor
- **Núcleos do Processador:** 16

### Métricas Coletadas
- **First Contentful Paint (Tempo da Primeira Renderização de Conteúdo):** Tempo até a primeira renderização de conteúdo
- **Largest Contentful Paint (Tempo da Maior Renderização de Conteúdo):** Tempo até a maior renderização de conteúdo
- **Performance Score (Pontuação de Performance):** Pontuação geral do Lighthouse (0-100)

### Análise Estatística
Para cada métrica, reportamos:
- **Média:** Valor médio
- **Desvio Padrão:** Medida de variabilidade
- **Coeficiente de Variação:** Desvio Padrão / Média × 100% (menor é melhor, menos de 10% é excelente)
- **Intervalo de Confiança 95%:** Faixa onde a média verdadeira provavelmente está
- **Mínimo/Máximo:** Faixa observada
- **Outliers Removidos:** Usando método da Amplitude Interquartil

---

## Rsbuild Module Federation

**Medições válidas:** 30 (0 outliers removidos)

### Estatísticas Resumidas

| Métrica | Média | Desvio Padrão | Coeficiente de Variação (%) | Intervalo de Confiança 95% | Mínimo | Máximo |
|--------|------|-------------|--------|-----------|-----|-----|
| **First Contentful Paint (segundos)** | 0.072 | 0.007 | 9.89 | ±0.003 | 0.061 | 0.085 |
| **Largest Contentful Paint (segundos)** | 0.094 | 0.005 | 5.44 | ±0.002 | 0.088 | 0.103 |
| **Performance Score** | 100.0 | 0.00 | 0.00 | ±0.00 | 100.0 | 100.0 |

**Interpretação:**
- Valores médios com intervalos de confiança de 95%
- Coeficiente de Variação: menor é melhor, menos de 10% = excelente, 10-20% = bom, maior que 20% = alta variabilidade
- Valores menores de First Contentful Paint e Largest Contentful Paint e pontuações maiores de Performance são melhores

---

## Single SPA

**Medições válidas:** 30 (0 outliers removidos)

### Estatísticas Resumidas

| Métrica | Média | Desvio Padrão | Coeficiente de Variação (%) | Intervalo de Confiança 95% | Mínimo | Máximo |
|--------|------|-------------|--------|-----------|-----|-----|
| **First Contentful Paint (segundos)** | 2.761 | 0.646 | 23.39 | ±0.241 | 2.126 | 3.939 |
| **Largest Contentful Paint (segundos)** | 2.787 | 0.645 | 23.14 | ±0.241 | 2.029 | 3.977 |
| **Performance Score** | 90.7 | 6.58 | 7.24 | ±2.46 | 78.0 | 98.0 |

**Interpretação:**
- Valores médios com intervalos de confiança de 95%
- Coeficiente de Variação: menor é melhor, menos de 10% = excelente, 10-20% = bom, maior que 20% = alta variabilidade
- Valores menores de First Contentful Paint e Largest Contentful Paint e pontuações maiores de Performance são melhores

---

## Análise Comparativa

### First Contentful Paint (Tempo da Primeira Renderização de Conteúdo)

| Aplicação | Média | Intervalo de Confiança 95% | Coeficiente de Variação |
|-------------|------|--------|-----|
| Rsbuild Module Federation | 0.072s | ±0.003s | 9.89% |
| Single SPA | 2.761s | ±0.241s | 23.39% |

**Diferença:** 2.689s  
**✓ Estatisticamente significativo** **Vencedor: Rsbuild Module Federation** (2.689s mais rápido)  


**Mais consistente:** Rsbuild Module Federation (Coeficiente de Variação: 9.89% versus 23.39%)

---

### Largest Contentful Paint (Tempo da Maior Renderização de Conteúdo)

| Aplicação | Média | Intervalo de Confiança 95% | Coeficiente de Variação |
|-------------|------|--------|-----|
| Rsbuild Module Federation | 0.094s | ±0.002s | 5.44% |
| Single SPA | 2.787s | ±0.241s | 23.14% |

**Diferença:** 2.694s  
**✓ Estatisticamente significativo** **Vencedor: Rsbuild Module Federation** (2.694s mais rápido)  


**Mais consistente:** Rsbuild Module Federation (Coeficiente de Variação: 5.44% versus 23.14%)

---

### Performance Score (Pontuação de Performance)

| Aplicação | Média | Intervalo de Confiança 95% | Coeficiente de Variação |
|-------------|------|--------|-----|
| Rsbuild Module Federation | 100.0 | ±0.00 | 0.00% |
| Single SPA | 90.7 | ±2.46 | 7.24% |

**Diferença:** 9.3 pontos  
**✓ Estatisticamente significativo** **Vencedor: Rsbuild Module Federation** (+9.3 pontos)

**Mais consistente:** Rsbuild Module Federation (Coeficiente de Variação: 0.00% versus 7.24%)

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

