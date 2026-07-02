---
description: Backlog persistente do projeto — tarefas pendentes e ideias de melhoria
---

# Backlog (Pendente)

## Melhorias Futuras — listarCaixasPostais.ps1

- **[MELHORIA]** Substituir `Add-Content` + buffer de 500 linhas por `System.IO.StreamWriter` na gravação do CSV. O StreamWriter mantém o arquivo aberto durante todo o loop, elimina a alocação periódica de `List[string]` e reduz chamadas ao sistema de arquivos de N/500 para uma única abertura. Compatível com PS5.
  - _Origem: implementation_plan.md — decisão adiada em 02/07/26 (menor impacto relativo; aguarda validação das otimizações da v27)_

- **[MELHORIA]** Avaliar paralelismo com `ForEach-Object -Parallel` (PowerShell 7+) para a etapa de `Get-EXOMailboxStatistics`, que permanece sendo chamada individualmente por caixa (~3.000+ chamadas). Esta é a maior oportunidade de ganho de performance restante. Requer PS7+ e análise de limites de throttling do Exchange Online.
  - _Origem: implementation_plan.md — decisão adiada em 02/07/26 (restrição de compatibilidade PS5)_
