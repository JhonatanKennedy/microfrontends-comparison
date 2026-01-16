# Microfrontends Comparison

Repositório desenvolvido como parte do Trabalho de Conclusão de Curso (TCC) sobre análise e comparação de diferentes abordagens de implementação de arquitetura de microfrontends.

## 📋 Sobre o Projeto

Este projeto apresenta uma análise comparativa entre duas das principais abordagens de implementação de microfrontends:

- **Module Federation** (Webpack 5)
- **Single-SPA**

O objetivo é avaliar e comparar métricas de performance, complexidade de implementação, bundle size e outras características relevantes para auxiliar na escolha da melhor abordagem para diferentes cenários de aplicação.

## 🏗️ Estrutura do Projeto

```
microfrontends-comparison/
├── mf-module-federation/     # Implementação usando Module Federation
├── mf-single-spa/            # Implementação usando Single-SPA
├── mf-tgc-types/             # Tipos compartilhados entre os projetos
├── server/                   # Servidor para servir as aplicações
├── reports/                  # Relatórios de métricas e análises
├── benchmark-build.sh        # Script para análise de build
└── benchmark-lighthouse.sh   # Script para análise com Lighthouse
```

## 🚀 Como Executar

### Pré-requisitos

- Node.js (versão especificada no arquivo `.nvmrc`)
- Docker e Docker Compose
- Sistema operacional Linux (para execução dos scripts de benchmark)

### Executando as Aplicações

Ambas as abordagens utilizam Docker containers para facilitar a execução local. Para iniciar qualquer uma das implementações:

```bash
# Entre no diretório da abordagem desejada
cd mf-module-federation
# ou
cd mf-single-spa

# Execute o Docker Compose
docker-compose up
```

## 📊 Análise de Métricas

Este projeto inclui dois scripts automatizados para capturar e analisar métricas de performance:

### 1. Benchmark de Build

Analisa métricas relacionadas ao processo de build, como tempo de compilação e tamanho dos bundles gerados.

```bash
# Dar permissão de execução (necessário apenas uma vez)
chmod +x benchmark-build.sh

# Executar o script
./benchmark-build.sh
```

### 2. Benchmark com Lighthouse

Utiliza o Google Lighthouse para avaliar métricas de performance, acessibilidade, SEO e melhores práticas.

```bash
# Dar permissão de execução (necessário apenas uma vez)
chmod +x benchmark-lighthouse.sh

# Executar o script
./benchmark-lighthouse.sh
```

> **⚠️ Importante**: Ambos os scripts foram desenvolvidos para serem executados em ambiente Linux.

## 🔍 Métricas Analisadas

As métricas coletadas incluem:

- **Performance**

  - First Contentful Paint (FCP)
  - Largest Contentful Paint (LCP)
  - Score

- **Build**

  - Tempo de build
  - Tamanho dos bundles
  - Número de chunks gerados

## 🛠️ Tecnologias Utilizadas

- **Frontend**: React
- **Module Federation**: Webpack 5
- **Single-SPA**: Framework de orquestração de microfrontends
- **Docker**: Containerização das aplicações
- **Node.js**: Ambiente de execução
- **Lighthouse**: Ferramenta de análise de performance

## 📈 Resultados

Os resultados detalhados das análises e comparações podem ser encontrados no diretório `reports/`, incluindo:

- Gráficos comparativos
- Tabelas de métricas
- Análises qualitativas
- Recomendações de uso

## 👥 Contribuindo

Este projeto foi desenvolvido como TCC acadêmico. Sugestões e melhorias são bem-vindas através de issues e pull requests.

## 📧 Contato

Para mais informações sobre o projeto ou questões relacionadas ao TCC, entre em contato através do GitHub.

---

**Desenvolvido como parte do Trabalho de Conclusão de Curso**
