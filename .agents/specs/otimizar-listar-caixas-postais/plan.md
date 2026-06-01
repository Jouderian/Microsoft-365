---
description: Plano técnico de otimização do script listarCaixasPostais.ps1 — pré-carga em batch de dados para eliminar chamadas de API por item dentro do loop
---

# Plan: Otimização de Performance — listarCaixasPostais.ps1

> Referência: `spec.md § Gargalos Identificados` e `spec.md § Critérios de Aceitação`

## Estratégia Central

Substituir **todas as chamadas de API individuais dentro do loop** por **pré-cargas em batch antes do loop**, usando dicionários (hashtables) indexados por UPN/GUID para acesso O(1) durante a iteração.

---

## Mudanças Técnicas por Gargalo

### Gargalo 1 — Licenças (Get-MgUserLicenseDetail por caixa)

**Problema:** 1 chamada Graph por caixa = ~4.000 chamadas.

**Solução:** Pré-carregar todas as assinaturas do tenant com `Get-MgSubscribedSku` criando um mapeamento `$skuMap` (SkuId -> SkuPartNumber). Consolidar a listagem do Graph em uma única chamada principal de usuários contendo a propriedade `assignedLicenses`, guardando em um dicionário `$licencasPorUPN` indexado por UPN para acesso O(1) no loop.

```powershell
# PRÉ-LOOP (Busca de SKUs)
$skuMap = @{}
Get-MgSubscribedSku -All | ForEach-Object {
  $skuMap[$_.SkuId.ToString()] = $_.SkuPartNumber
}

# DENTRO DO LOOP (acesso O(1) e tradução)
$licencas = $licencasPorUPN[$caixa.UserPrincipalName.ToLower()]
```

### Gargalo 2 — Estatísticas (Get-EXOMailboxStatistics por caixa)

**Problema:** 1 chamada Exchange por caixa = ~4.000 chamadas. Não existe endpoint batch para `Get-EXOMailboxStatistics`.

**Solução:** Não é possível eliminar 100% das chamadas individuais de estatísticas via Exchange REST. Mas podemos:

1. **Remover `-PropertySets All`** e solicitar apenas as propriedades necessárias (`TotalItemSize`, `LastInteractionTime`), reduzindo o payload de rede por chamada.
2. **Manter as chamadas**, pois não há alternativa batch nativa para este cmdlet.

```powershell
# ANTES (payload excessivo):
$detalheCaixa = Get-EXOMailboxStatistics -Identity $caixa.Guid -PropertySets All -Properties LastInteractionTime, TotalItemSize

# DEPOIS (payload mínimo):
$detalheCaixa = Get-EXOMailboxStatistics -Identity $caixa.Guid -Properties LastInteractionTime, TotalItemSize
```

### Gargalo 3 — Gerentes (Get-MgUserManager por caixa)

**Problema:** 1 chamada Graph por caixa = ~4.000 chamadas.

**Solução:** Consolidar a chamada principal do Graph expandindo a propriedade `manager` (`-ExpandProperty manager`) junto com os demais detalhes e licenças do usuário, montando o dicionário `$gerentePorUPN` indexado por UPN.

```powershell
# DENTRO DO LOOP (acesso O(1))
$gerente = $gerentePorUPN[$caixa.UserPrincipalName.ToLower()]
```

### Gargalo 4 — Get-EXOMailbox -PropertySets All

**Problema:** `-PropertySets All` busca dezenas de property sets desnecessários.

**Solução:** Substituir por `-Properties` listando apenas os campos utilizados.

```powershell
# ANTES:
$Caixas = Get-EXOMailbox -ResultSize Unlimited -PropertySets All | Select-Object $camposCaixa

# DEPOIS:
$Caixas = Get-EXOMailbox -ResultSize Unlimited -Properties $camposCaixa
```

### Gargalo 5 — Concatenação de Array ($buffer +=)

**Problema:** `$buffer += $infoCaixa` em PowerShell realoca todo o array a cada iteração. Para 4.000 itens, isso causa degradação progressiva.

**Solução:** Usar `[System.Collections.Generic.List[string]]` ou `[System.Text.StringBuilder]` que têm complexidade amortizada O(1) para adições.

```powershell
# ANTES:
$buffer = @()
$buffer += $infoCaixa

# DEPOIS:
$buffer = [System.Collections.Generic.List[string]]::new()
$buffer.Add($infoCaixa)
```

---

## Sequência de Pré-Cargas (ordem de execução)

```
1. Get-EXOMailbox -Properties $camposCaixa → $caixas [OTIMIZADO]
2. Get-MgSubscribedSku -All → $skuMap (tabela hash SkuId → SkuPartNumber) [NOVO]
3. Get-MgUser -All -Property $propriedadesGraph -ExpandProperty manager → Popula $detalheCredenciais, $licencasPorUPN e $gerentePorUPN [CONSOLIDADO]
```

> **Atenção:** Os passos de carregamento do Graph estão 100% consolidados em uma única chamada de rede paginada automaticamente pelo SDK, reduzindo drasticamente o overhead de conexão.

---

## Impacto Estimado

| Métrica | Antes | Depois |
|---------|-------|--------|
| Chamadas Graph por execução | ~8.000 | ~3–5 paginadas |
| Chamadas Exchange por execução | ~4.000–8.000 | ~4.000 (incontornável) |
| Alocações de memória do buffer | ~4.000 realocações | O(1) amortizado |
| Tempo estimado de execução | ~60–90 min | ~15–25 min |

---

## Arquivos Afetados

- **[MODIFY]** `listarCaixasPostais.ps1` — Implementação das otimizações

---

## Riscos e Mitigações

| Risco | Mitigação |
|-------|-----------|
| `ExpandProperty manager` pode falhar para usuários sem gerente | Verificação `if ($null -ne $_.Manager)` |
| `assignedLicenses` retorna SkuId (não SkuPartNumber) | Dicionário `$skuPorId` via `Get-MgSubscribedSku` |
| Combinar múltiplas propriedades num único `Get-MgUser -All` pode exceder limite de `$select` | Manter chamadas separadas se necessário |
| `Get-EXOMailbox -Properties` pode não aceitar todos os campos de `$camposCaixa` | Testar e ajustar a lista de propriedades |
