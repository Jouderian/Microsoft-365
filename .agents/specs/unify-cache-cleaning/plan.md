---
description: Plano técnico de implementação para a unificação dos scripts de limpeza de cache de Teams e Outlook.
---

# Plano de Implementação: Unificação de Scripts de Limpeza de Cache

Este plano detalha as alterações de código necessárias para consolidar as rotinas de limpeza de cache do Microsoft Teams e Microsoft Outlook, em conformidade com a [Especificação](/.agents/specs/unify-cache-cleaning/spec.md).

## Decisões Técnicas e Arquitetura

### 1. Assinatura do Script e Parâmetros
Para atender ao requisito de flexibilidade (conforme `spec.md § Requisitos de Negócio e Funcionais`), adicionaremos um bloco `param()` no topo do script:
```powershell
param(
  [switch]$SomenteTeams,
  [switch]$SomenteOutlook
)
```
Por padrão, se o usuário não passar nenhum parâmetro, ambos os aplicativos serão limpos. Avaliaremos isso no fluxo principal com a seguinte lógica de controle:
```powershell
$limparTeams = $true
$limparOutlook = $true

if ($SomenteTeams -or $SomenteOutlook){
  $limparTeams = $SomenteTeams
  $limparOutlook = $SomenteOutlook
}
```

### 2. Cabeçalho Padronizado
O script `limparCacheTeamsOutlook.ps1` utilizará o bloco rigoroso de comentário `<# .SYNOPSIS ... #>` conforme exigido pelas diretrizes (`code-standards.md`), detalhando a compatibilidade com o Teams clássico, novo Teams e ambas as versões de Outlook.

### 3. Divisão de Processos e Fluxos de Limpeza
Para implementar a "Parada de Processos Inteligente" (conforme `spec.md § Requisitos de Negócio e Funcionais`):
- O array de processos a serem fechados será filtrado condicionalmente:
  - Processos do Teams: `"ms-teams"`, `"MSTeams"`, `"teams"`
  - Processos do Outlook: `"olk"`, `"HxOutlook"`, `"HxTsr"`, `"HxMail"`, `"outlook"`
- As rotinas de limpeza (`Clear-Teams*` e `Clear-OutlookCache`) e as rotinas de reinicialização (`Start-TeamsSafe`, `Start-OutlookSafe`) serão executadas condicionalmente baseado nas variáveis `$limparTeams` e `$limparOutlook`.

### 4. Remoção de Código Duplicado e Obsoleto
- Exclusão do arquivo legado `limparCacheTeams.ps1`.
- Exclusão do arquivo `limpaCacheTeamsOutlook.ps1` com nome desalinhado dos padrões de nomenclatura ( `camelCase` com verbos no infinitivo).

## Estrutura do Novo Arquivo

O novo script unificado `limparCacheTeamsOutlook.ps1` conterá:
1. Cabeçalho `.SYNOPSIS`
2. Bloco `param()`
3. Definição de funções utilitárias (`Write-Log`, `Stop-ProcessSafe`, `Remove-PathSafe`)
4. Definição de funções de limpeza do Teams (`Clear-TeamsClassicRoamingCache`, `Clear-TeamsLocalElectronCache`, `Clear-TeamsNewMsixCache`)
5. Definição de funções de limpeza do Outlook (`Clear-OutlookCache`)
6. Definição de funções de inicialização (`Start-TeamsSafe`, `Start-OutlookSafe`)
7. Fluxo principal estruturado e condicionado por `$limparTeams` e `$limparOutlook`.

Para o checklist de implementação e etapas de execução, consulte [Tasks](/.agents/specs/unify-cache-cleaning/tasks.md).
