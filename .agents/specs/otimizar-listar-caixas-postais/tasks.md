---
description: Checklist de tarefas para otimização de performance do listarCaixasPostais.ps1
---

# Tasks: Otimização de Performance — listarCaixasPostais.ps1

## Planejamento

- `[x]` Criar `spec.md` com identificação dos gargalos e critérios de aceitação
- `[x]` Criar `plan.md` com a estratégia técnica e impacto estimado
- `[x]` Registrar melhorias futuras no `.agents/todo.md` (paralelismo e consolidação de chamadas Graph)

## Implementação

- `[x]` Substituir `Get-EXOMailbox -PropertySets All` por `-Properties $camposCaixa`
- `[x]` Adicionar `ForwardingAddress` em `$camposCaixa` (necessário para coluna Encaminhada)
- `[x]` Substituir `$buffer = @()` por `[System.Collections.Generic.List[string]]::new()`
- `[x]` Substituir `$buffer += $infoCaixa` por `$buffer.Add($infoCaixa)`
- `[x]` Re-inicializar `$buffer` como `List[string]` no flush a cada 500 itens
- `[x]` Pré-carga 1: `Get-MgUser -All -Property $camposDetalhesCaixa` → `$detalheCredenciais`
- `[x]` Pré-carga 2: `Get-MgSubscribedSku -All` → `$skuPorId` (SkuId → SkuPartNumber)
- `[x]` Pré-carga 3: `Get-MgUser -All -Property 'userPrincipalName','assignedLicenses'` → `$licencasPorUPN`
- `[x]` Pré-carga 4: `Get-MgUser -All -ExpandProperty 'manager'` → `$gerentePorUPN`
- `[x]` Remover `Get-MgUserLicenseDetail` do loop
- `[x]` Remover `Get-MgUserManager` do loop
- `[x]` Remover `-PropertySets All` do `Get-EXOMailboxStatistics` (caixa principal e arquivamento)
- `[x]` Adaptar lógica de licenças para usar `$skuPorId[$licenca.SkuId]` → `ObterDescricaoLicenca`
- `[x]` Atualizar cabeçalho do script (versão 25, data 25/05/26)

## Verificação

- `[x]` Executar o script e medir tempo de execução total
- `[x]` Verificar que o CSV gerado tem as mesmas 28 colunas
- `[x]` Confirmar que licenças aparecem com as descrições corretas
- `[x]` Confirmar que gerentes são preenchidos corretamente (vazios onde não há gerente)
- `[x]` Confirmar que caixas com arquivamento ativo têm tamanho de arquivamento preenchido
