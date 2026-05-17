---
description: Lista de tarefas atômicas para a implementação da unificação dos scripts de cache.
---

# Tasks: Unificação de Scripts de Cache

Esta lista rastreia a evolução das atividades de implementação e verificação da unificação de cache do Teams/Outlook.

- [x] **Fase 1: Preparação**
  - [x] Criar especificação técnica e plano SDD (Concluído)
  - [x] Validar estrutura nominal e regras de nomenclatura (Concluído)

- [x] **Fase 2: Implementação de `limparCacheTeamsOutlook.ps1`**
  - [x] Criar o arquivo `limparCacheTeamsOutlook.ps1` na pasta raiz de scripts.
  - [x] Inserir o cabeçalho padronizado `<# .SYNOPSIS ... #>` detalhado.
  - [x] Implementar os parâmetros `[switch]$somenteTeams` e `[switch]$somenteOutlook`.
  - [x] Declarar as funções básicas de utilidade (`Write-Log`, `Stop-ProcessSafe`, `Remove-PathSafe`).
  - [x] Importar as funções de limpeza do Teams:
    - [x] `Clear-TeamsClassicRoamingCache`
    - [x] `Clear-TeamsLocalElectronCache`
    - [x] `Clear-TeamsNewMsixCache`
  - [x] Importar e adaptar a função de limpeza de cache do Outlook (`Clear-OutlookCache`).
  - [x] Implementar reabertura condicionada (`Start-TeamsSafe`, `Start-OutlookSafe`).
  - [x] Consolidar o fluxo principal condicionando as etapas a `$limparTeams` e `$limparOutlook`.

- [x] **Fase 3: Faxina do Repositório**
  - [x] Remover permanentemente o arquivo legado [limparCacheTeams.ps1](/limparCacheTeams.ps1).
  - [x] Remover permanentemente o arquivo com nome antigo [limpaCacheTeamsOutlook.ps1](/limpaCacheTeamsOutlook.ps1).

- [ ] **Fase 4: Validação Funcional (Critérios de Aceitação)**
  - [ ] Testar limpeza completa (sem parâmetros).
  - [ ] Testar limpeza restrita ao Teams (`-somenteTeams`).
  - [ ] Testar limpeza restrita ao Outlook (`-somenteOutlook`).
