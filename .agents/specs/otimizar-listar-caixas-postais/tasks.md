---
description: Checklist de tarefas para otimização de performance do listarCaixasPostais.ps1
---

# Tasks: Otimização de Performance — listarCaixasPostais.ps1

## Planejamento

- `[x]` Criar `spec.md` com identificação dos gargalos e critérios de aceitação
- `[x]` Criar `plan.md` com a estratégia técnica e impacto estimado
- `[x]` Registrar melhorias futuras no `.agents/todo.md` (paralelismo e consolidação de chamadas Graph)

## Implementação

- `[x]` Buscar todas as assinaturas do tenant com `Get-MgSubscribedSku` criando a tabela `$skuMap`
- `[x]` Consolidar o carregamento do Graph em uma única chamada `Get-MgUser -All` com propriedades e expansão de `manager`
- `[x]` Popular os dicionários `$detalheCredenciais`, `$licencasPorUPN` e `$gerentePorUPN` a partir da pré-carga única
- `[x]` Substituir `Get-EXOMailbox -PropertySets All` por `-Properties $camposCaixa`
- `[x]` Adicionar `ForwardingAddress` e `DeliverToMailboxAndForward` em `$camposCaixa`
- `[x]` Substituir `$buffer = @()` por `[System.Collections.Generic.List[string]]::new()`
- `[x]` Substituir `$buffer += $infoCaixa` por `$buffer.Add($infoCaixa)` e re-inicializar como `List[string]` no flush (500 itens)
- `[x]` Remover `Get-MgUserLicenseDetail` e `Get-MgUserManager` do loop interno
- `[x]` Adaptar lógica de licenças no loop para ler de `$licencasPorUPN` e traduzir com `$skuMap` e `ObterDescricaoLicenca`
- `[x]` Adaptar lógica de gerentes no loop para ler de `$gerentePorUPN`
- `[x]` Remover o uso de `-PropertySets All` nas chamadas a `Get-EXOMailboxStatistics` (caixas principais e arquivadas)
- `[x]` Atualizar cabeçalho do script (versão 25, data atualizada 31/05/26 ou 01/06/26)

## Verificação

- `[x]` Executar o script e medir tempo de execução total
- `[x]` Verificar que o CSV gerado tem exatamente as mesmas 28 colunas originais
- `[x]` Confirmar que licenças aparecem com as descrições corretas no CSV
- `[x]` Confirmar que gerentes são preenchidos corretamente (e vazios onde não há gerente)
- `[x]` Confirmar que caixas com arquivamento ativo têm tamanho de arquivamento preenchido

