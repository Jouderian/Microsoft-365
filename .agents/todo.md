---
description: Backlog persistente do projeto — tarefas pendentes e ideias de melhoria
---

# Backlog (Pendente)

## Melhorias Futuras — listarCaixasPostais.ps1

- **[MELHORIA]** Avaliar paralelismo com `ForEach-Object -Parallel` (PowerShell 7+) para a etapa de `Get-EXOMailboxStatistics`, que permanece sendo chamada individualmente por caixa (~4.000 chamadas). Esta é a maior oportunidade de ganho de performance restante após a otimização em batch. Requer PS7+ e análise de limites de throttling do Exchange Online.
  - _Origem: otimizar-listar-caixas-postais/plan.md — decisão adiada em 25/05/26_

- **[MELHORIA]** Avaliar a consolidação das pré-cargas do Graph (`detalheCredenciais`, `licencasPorUPN` e `gerentePorUPN`) em uma única chamada `Get-MgUser -All` com múltiplos `-Property` e `-ExpandProperty manager`, reduzindo de 3 chamadas paginadas para 1. Requer validação do limite de campos no `$select` da API Graph.
  - _Origem: otimizar-listar-caixas-postais/plan.md — decisão adiada em 25/05/26_
