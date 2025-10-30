# Relatório de Benchmark de Performance com Lighthouse
**Gerado em:** 2025-11-02 09:36:29 -03

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

