---
description: Especificação para unificação dos scripts de limpeza de cache de Teams e Outlook.
---

# Especificação: Unificação de Scripts de Limpeza de Cache (Teams e Outlook)

## Contexto
Atualmente, existem dois scripts que realizam tarefas de limpeza de cache de forma sobreposta:
1. `limparCacheTeams.ps1`: Limpa apenas o cache do Microsoft Teams (clássico e novo).
2. `limpaCacheTeamsOutlook.ps1`: Limpa o cache do Teams (clássico/novo) e do Outlook (clássico/novo) de forma mais robusta e estruturada.

Para simplificar o repositório, evitar código duplicado e melhorar a manutenção a longo prazo, decidimos unificar as rotinas em um único script mais flexível e parametrizável.

## Objetivos
- Unificar o comportamento de limpeza em um único arquivo.
- Renomear o script principal para seguir a padronização do repositório (verbos no infinitivo): `limparCacheTeamsOutlook.ps1`.
- Excluir o script legado e redundante `limparCacheTeams.ps1`.
- Excluir o arquivo com o nome antigo `limpaCacheTeamsOutlook.ps1`.

## Requisitos de Negócio e Funcionais
- **Parametrização**: O script deve suportar `-somenteTeams` e `-somenteOutlook` de forma independente. Se nenhum parâmetro for fornecido, ambos os caches deverão ser limpos por padrão.
- **Fechamento de Processos Inteligente**: O script deve apenas encerrar os processos vinculados ao aplicativo selecionado. Por exemplo, rodar `-somenteTeams` não pode derrubar o Outlook do usuário.
- **Tratamento de Exceções**: Manter funções robustas de tratamento (`Remove-PathSafe` e `Stop-ProcessSafe`) para evitar interrupções caso o usuário não tenha permissão ou se o arquivo estiver bloqueado.
- **Estrutura de Logs**: Preservar e garantir o uso da função `Write-Log`.

## Critérios de Aceitação
- [ ] Executar o script sem parâmetros deve limpar ambos os caches e reabrir ambos os aplicativos.
- [ ] Executar com `-somenteTeams` deve parar os processos do Teams, limpar apenas os caminhos de cache do Teams, e reabrir apenas o Teams. O Outlook não deve ser afetado.
- [ ] Executar com `-somenteOutlook` deve parar os processos do Outlook, limpar apenas os caminhos de cache do Outlook, e reabrir apenas o Outlook. O Teams não deve ser afetado.
- [ ] Não devem haver erros fatais de permissão que interrompam o fluxo.
- [x] O arquivo `limparCacheTeams.ps1` legado deve ser apagado fisicamente.
- [x] O arquivo `limpaCacheTeamsOutlook.ps1` antigo deve ser apagado fisicamente.
