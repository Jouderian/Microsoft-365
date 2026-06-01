---
description: Checklist de tarefas para otimização de performance do listarCaixasPostais.ps1
---

# Tasks: Otimização de Performance — listarCaixasPostais.ps1

## Planejamento

- `[x]` Criar `spec.md` com identificação dos gargalos e critérios de aceitação
- `[x]` Criar `plan.md` com a estratégia técnica e impacto estimado
- `[x]` Registrar melhorias futuras no `.agents/todo.md` (paralelismo e consolidação de chamadas Graph)

## Implementação

- `[ ]` Buscar todas as assinaturas do tenant com `Get-MgSubscribedSku` criando a tabela `$skuMap`
- `[ ]` Consolidar o carregamento do Graph em uma única chamada `Get-MgUser -All` com propriedades e expansão de `manager`
- `[ ]` Popular os dicionários `$detalheCredenciais`, `$licencasPorUPN` e `$gerentePorUPN` a partir da pré-carga única
- `[ ]` Substituir `Get-EXOMailbox -PropertySets All` por `-Properties $camposCaixa`
- `[ ]` Adicionar `ForwardingAddress` e `DeliverToMailboxAndForward` em `$camposCaixa`
- `[ ]` Substituir `$buffer = @()` por `[System.Collections.Generic.List[string]]::new()`
- `[ ]` Substituir `$buffer += $infoCaixa` por `$buffer.Add($infoCaixa)` e re-inicializar como `List[string]` no flush (500 itens)
- `[ ]` Remover `Get-MgUserLicenseDetail` e `Get-MgUserManager` do loop interno
- `[ ]` Adaptar lógica de licenças no loop para ler de `$licencasPorUPN` e traduzir com `$skuMap` e `ObterDescricaoLicenca`
- `[ ]` Adaptar lógica de gerentes no loop para ler de `$gerentePorUPN`
- `[ ]` Remover o uso de `-PropertySets All` nas chamadas a `Get-EXOMailboxStatistics` (caixas principais e arquivadas)
- `[ ]` Atualizar cabeçalho do script (versão 25, data atualizada 31/05/26 ou 01/06/26)

## Verificação

- `[ ]` Executar o script e medir tempo de execução total
- `[ ]` Verificar que o CSV gerado tem exatamente as mesmas 28 colunas originais
- `[ ]` Confirmar que licenças aparecem com as descrições corretas no CSV
- `[ ]` Confirmar que gerentes são preenchidos corretamente (e vazios onde não há gerente)
- `[ ]` Confirmar que caixas com arquivamento ativo têm tamanho de arquivamento preenchido

