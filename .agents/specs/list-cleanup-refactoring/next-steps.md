# Spec: Próximos Passos — listarMembrosListas.ps1

## Contexto

Após a sessão de refatoração de 11/04/26, o script `listarMembrosListas.ps1` está estável e funcional. Esta spec registra as melhorias identificadas e ainda pendentes de implementação.

## Melhorias Identificadas

---

### [P1] Normalizar identificador de membro entre DLs e Grupos de Segurança

**Problema:**  
A coluna `eMailMembro` do CSV usa fontes diferentes dependendo do tipo de grupo:
- Listas de Distribuição → `PrimarySMTPAddress` (Exchange) — pode vir **vazio** para contatos externos, guests e grupos aninhados.
- Grupos de Segurança → `userPrincipalName` (Graph) — sempre preenchido para usuários.

---

#### ⚠️ Análise de Viabilidade

**A migração de membros de DLs para `Get-MgGroupMember` é tecnicamente possível, mas com uma limitação crítica:**

> O Microsoft Graph API **só enxerga objetos que existem no Entra ID**. Membros de Listas de Distribuição do tipo **Mail Contact** (contatos externos puros do Exchange) **não possuem representação no Entra ID** e **são invisíveis para `Get-MgGroupMember`**. Usar Graph para buscar membros de DLs causaria **membros faltando no CSV** para qualquer lista que contenha contatos externos.

| Tipo de membro | Existe no Entra ID? | Visível via `Get-MgGroupMember`? |
|----------------|---------------------|-----------------------------------|
| Usuário M365 (cloud) | ✅ Sim | ✅ Sim |
| Usuário sincronizado do AD | ✅ Sim | ✅ Sim |
| Usuário Guest (B2B) | ✅ Sim | ✅ Sim |
| Grupo aninhado | ✅ Sim | ✅ Sim |
| **Mail Contact (externo Exchange)** | ❌ Não | ❌ **NÃO** |
| Mail User (externo sync) | ✅ Sim | ✅ Sim |

**Conclusão:** A migração total para Graph **causaria regressão de dados** — listas com contatos externos teriam membros omitidos no CSV.

---

#### Abordagem Alternativa Recomendada: Abordagem Híbrida com Enriquecimento

Manter `Get-DistributionGroupMember` (Exchange) como fonte de membros —  que é completa — e **enriquecer apenas os membros com `ExternalDirectoryObjectId`** com o UPN via Graph em lote.

**Fluxo proposto:**

```
Para cada Lista:
  1. Get-DistributionGroupMember   → lista completa (incluindo Mail Contacts)
  2. Separar membros COM e SEM ExternalDirectoryObjectId
  3. Para membros COM ID → batch Get-MgUser -Filter "id in (...)" → UPN
  4. Para membros SEM ID (Mail Contacts puros) → fallback: PrimarySMTPAddress
```

**Benefícios:**
- UPN para 95%+ dos membros (usuários M365, synced, guests)
- Sem perda de dados para contatos externos
- Uma única chamada ao Graph por lista (não por membro)

**Critérios de aceitação revisados:**
- [x] UPN preenchido para membros que existem no Entra ID
- [x] `PrimarySMTPAddress` usado como fallback para contatos sem `ExternalDirectoryObjectId`
- [x] Contagem de membros por grupo **idêntica** ao comportamento atual
- [x] Nenhuma regressão para listas com contatos externos

---

### [P2] Proteção para remoção de Grupos de Segurança sincronizados com AD

**Problema:**  
Atualmente, ao usar `-Acao ListarEApagar`, o script remove Grupos de Segurança vazios inclusive os sincronizados com AD (`OnPremisesSyncEnabled = True`). A remoção de grupos AD-synced pelo cloud pode causar conflitos de replicação ou re-criação automática pelo AD Connect.

**Proposta:**  
Adicionar guarda equivalente ao das DLs para Grupos de Segurança:
```powershell
if ($Grupo.OnPremisesSyncEnabled -eq $true) {
  gravaLOG "$($Grupo.DisplayName),...,Sincronizado AD — ignorado" -arquivo $logs
  continue
}
```

**Critérios de aceitação:**
- [x] Grupos de Segurança com `OnPremisesSyncEnabled = True` **não são removidos** em nenhum cenário
- [x] Log de auditoria registra grupos AD-sync ignorados com motivo explícito

---

> **Descartado.** Decisão: manter o cabeçalho `eMailMembro` sem alterações para preservar compatibilidade com consumidores existentes do CSV.

---

### [P3] Adicionar coluna `tipoGrupo` normalizada para Grupos de Segurança

**Problema:**  
Para Listas de Distribuição, a coluna `tipoGrupo` usa `RecipientType` do Exchange (ex: `MailUniversalDistributionGroup`).  
Para Grupos de Segurança, o script grava literalmente `"Security"` — informação útil, mas poderia incluir subtipo (ex: `SecurityEnabled`, `DynamicSecurity`).

**Proposta:**  
Derivar o subtipo do campo `GroupTypes` retornado pelo `Get-MgGroup` e gravar valor como `Security` ou `DynamicSecurity`.

---

### [P4] Exportar coluna `tipoMembro` também para Listas de Distribuição

**Problema:**  
Para DLs, a coluna `tipo` usa `RecipientType` do Exchange (ex: `UserMailbox`, `MailContact`). Para Grupos de Segurança, classifica apenas como `User` ou `Other`. A ausência de normalização dificulta análises cross-tipo.

**Proposta:**  
Mapear os valores de `RecipientType` do Exchange para os equivalentes padronizados:
- `UserMailbox` → `User`
- `MailContact` → `Contact`
- `MailUniversalDistributionGroup` / `GroupMailbox` → `Group`
- Outros → `Other`

## Resumo de Prioridades

| ID | Título | Prioridade | Status |
|----|--------|------------|--------|
| P1 | Migrar membros de DLs para Graph (UPN unificado) | Alta | ✅ Implementado |
| P2 | Proteção de Grupos AD-sync no `ListarEApagar` | Alta | ✅ Implementado |
| P3 | Renomear cabeçalho `eMailMembro` → `upnMembro` | Baixa | ❌ Descartado |
| P3 | Subtipo normalizado para Grupos de Segurança | Baixa | Pendente |
| P4 | Normalizar coluna `tipoMembro` para DLs | Backlog | Pendente |
