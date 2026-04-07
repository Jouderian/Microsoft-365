# listarCaixasPostaisNOVO.ps1

> **Sinopse**: Inventário de mailboxes (alto desempenho) para Windows PowerShell 5.1
Usa Graph Reports (rápido) e cai para EXO statistics (lento) quando necessário.

## Descrição
- EXO (Get-EXOMailbox): tipo, encaminhamento, litígio, criação, status de arquivamento (REST V3).
- Graph Users (Get-MgUser): identidade (manager opcional), status da conta, sync AD, políticas de senha, licenças.
- Graph Reports (Get-MgReportMailboxUsageDetail): usado (GB), último uso, arquivamento (Sim/GB) — 1 CSV para todas as caixas.
-> Fallback automático para Get-EXOMailboxStatistics somente se Reports indisponível.

## Detalhes
- **Autor**: Desconhecido
- **Versão Atual**: N/A
- **Saída**: N/A

## Módulos / Dependências
- ExchangeOnlineManagement
- Microsoft.Graph
