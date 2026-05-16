---
description: Workflow e procedimento para registrar Arquitetural Decision Records (ADRs)
---

# Registro de Decisões Arquiteturais (ADRs)

Todo evento que causar uma mudança estrutural na forma como os scripts operam (ex: Adição de ClientSecret invés de Certificado, mudança de nome grande de arquivo, troca de API de Auth do RM) deve gerar uma ADR no repositório.

Crie os arquivos numéricos sequenciais em `.agents/wiki/decisions/<numero>-<nome>.md`.

## Molde de ADR
- Yaml Frontmatter (com campo `description`)
- Resumo
- Data e Status
- Contexto e Problema
- Decisão Técnica (Opções avaliadas)
- Consequências (Impacto em Scripts legados)
