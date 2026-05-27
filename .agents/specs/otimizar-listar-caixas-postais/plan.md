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

**Solução:** Usar `Get-MgUser -All -Property assignedLicenses,userPrincipalName` para obter as licenças de todos os usuários em uma única chamada de paginação automática. Montar um dicionário `$licencasPorUPN` indexado por UPN.

```powershell
# PRÉ-LOOP (uma chamada)
$licencasPorUPN = @{}
Get-MgUser -All -Property 'userPrincipalName','assignedLicenses' | ForEach-Object {
  $licencasPorUPN[$_.UserPrincipalName.ToLower()] = $_.AssignedLicenses
}

# DENTRO DO LOOP (acesso O(1))
$licencas = $licencasPorUPN[$caixa.UserPrincipalName.ToLower()]
```

> **Nota:** `assignedLicenses` retorna o SkuId (GUID), não o SkuPartNumber. Portanto, será necessário um segundo dicionário `$skuPorId` construído com `Get-MgSubscribedSku` (também uma única chamada) para mapear SkuId → SkuPartNumber → descrição via `ObterDescricaoLicenca`.

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

**Solução:** Usar `Get-MgUser -All -ExpandProperty manager -Property id,userPrincipalName` para pré-carregar o gerente de todos os usuários de uma vez. Montar `$gerentePorUPN`.

```powershell
# PRÉ-LOOP (uma chamada com expand)
$gerentePorUPN = @{}
Get-MgUser -All -Property 'id','userPrincipalName' -ExpandProperty 'manager' | ForEach-Object {
  $nomeGerente = ""
  if ($_.Manager -ne $null){
    $nomeGerente = $_.Manager.AdditionalProperties['displayName']
  }
  $gerentePorUPN[$_.UserPrincipalName.ToLower()] = $nomeGerente
}

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
1. Get-EXOMailbox -Properties $camposCaixa → $caixas
2. Get-MgSubscribedSku → $skuPorId (map SkuId → SkuPartNumber)
3. Get-MgUser -All -Property $camposDetalhesCaixa → $detalheCredenciais (já existe)
4. Get-MgUser -All -Property 'userPrincipalName','assignedLicenses' → $licencasPorUPN [NOVO]
5. Get-MgUser -All -Property 'id','userPrincipalName' -ExpandProperty 'manager' → $gerentePorUPN [NOVO]
```

> **Atenção:** Os passos 3, 4 e 5 fazem chamadas separadas ao Graph. Podemos otimizar ainda mais combinando os campos em uma única chamada caso a quantidade de `$select` suportada pela API permita. Isso será validado na implementação.

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
