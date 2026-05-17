---
description: Checklist de tarefas atômicas para refatoração e evolução do script validaGPOs.ps1
---

# Checklist de Tarefas — Evolução do `validaGPOs.ps1`

Este documento define as tarefas atômicas e verificáveis para a implementação das melhorias propostas para o script [`validaGPOs.ps1`](/activeDirectory/validaGPOs.ps1).

---

## 📋 Fase 1 — Preparação e Cabeçalhos
- [x] Atualizar o Comment-Based Help no topo do script definindo o autor original como Felipe Aquino e data de criação 05/04/26.
- [x] Mapear o parâmetro de entrada `[string]$logPath` de forma opcional com o fallback padrão `validaGPOs_execution.log` na mesma pasta do script.

## 📋 Fase 2 — Limpeza e Interface (RSoP)
- [x] Remover do bloco `param(...)` os parâmetros `$UseRsop`, `$ComputersCsv`, `$RsopUsersPerOu`, `$RsopTimeoutSec`, `$PingTimeoutMs`, `$PortTimeoutMs`, `$WinrmTimeoutSec`, `$WmiTimeoutSec`.
- [x] Excluir a criação da pasta `$rsopOutFolder` e a variável `$UseRSOP`.
- [x] Remover a verificação condicional de RSoP ativo/desabilitado no console de log.

## 📋 Fase 3 — Helpers Autônomos Locais
- [x] Remover as funções antigas `Write-Info`, `Write-OK`, `Write-Warn`, `Write-Bad`, `Write-Dim` e `Require-Module`.
- [x] Implementar a função local `Grava-LogLocal` utilizando o escopo de script local `$script:logExecutionPath` em vez da variável `$global:logExecutionPath` para gravação síncrona de logs.
- [x] Implementar a função local `Verifica-ModuloLocal` com fluxo inteligente e interativo para instalar dependências.
- [x] Atualizar as chamadas de importação de módulos iniciais para usar `Verifica-ModuloLocal`.

## 📋 Fase 4 — Renomeação para camelCase e Otimização do AD
- [x] Renomear sistematicamente todas as ocorrências de variáveis PascalCase para camelCase no script.
- [x] Otimizar a chamada inicial do `Get-ADUser` carregando apenas a propriedade `Enabled`.
- [x] Implementar a lógica de carregamento sob demanda (*lazy loading*) de amostras de usuários no loop principal se o parâmetro `$includeUsersSample` estiver ativo.

## 📋 Fase 5 — Tratamento de Erros e Consolidação do HTML
- [x] Envolver toda a rotina de execução em um bloco `try-catch` global de forma a garantir logs persistentes e robustos em caso de erros fatais do domínio.
- [x] Testar a integridade do HTML gerado garantindo que exiba corretamente todas as informações do domínio, contagem de usuários e status de links.

## 📋 Fase 6 — Documentação e Atualização do Wiki
- [x] Enriquecer o arquivo de documentação complementar [`validaGPOs.md`](/docs/activeDirectory/validaGPOs.md) preenchendo todos os placeholders, dependências de módulos RSAT e descrição detalhada do funcionamento.
- [x] Atualizar o backlog em [todo.md](/.agents/todo.md) movendo/removendo pendências correspondentes ao controle de logs concluído.
