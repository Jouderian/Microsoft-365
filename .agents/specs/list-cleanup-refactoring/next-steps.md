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

**Proposta:**  
Migrar a busca de membros das Listas de Distribuição também para o **Microsoft Graph**, usando `Get-MgGroupMember` com `-Property "id,displayName,userPrincipalName"` para ambos os tipos de grupo. Isso eliminaria a dependência do Exchange para listagem de membros e unificaria a coluna `eMailMembro` com UPN em todos os casos.

**Impacto:** Médio — requer validar se as DLs do Exchange Online são acessíveis via `Get-MgGroupMember` (elas existem como grupos no Entra ID).

**Critérios de aceitação:**
- [ ] Coluna `eMailMembro` preenchida com UPN para todos os membros (DLs e Grupos de Segurança)
- [ ] Nenhuma regressão na contagem de membros por grupo
- [ ] Script funciona sem conexão ao Exchange Online (apenas Graph)

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
- [ ] Grupos de Segurança com `OnPremisesSyncEnabled = True` **não são removidos** em nenhum cenário
- [ ] Log de auditoria registra grupos AD-sync ignorados com motivo explícito

---

### [P3] Renomear cabeçalho do CSV para refletir UPN

**Problema:**  
O cabeçalho do CSV ainda usa `eMailMembro`, mas a coluna agora contém UPN para Grupos de Segurança.

**Proposta:**  
Alterar o cabeçalho de saída para `upnMembro` e atualizar a documentação associada.

```powershell
Out-File -FilePath $arquivo -InputObject "idGrupo;nomeGrupo;eMailGrupo;adSync;tipoGrupo;idMembro;membro;tipo;upnMembro" -Encoding UTF8
```

**Critérios de aceitação:**
- [ ] Cabeçalho do CSV atualizado para `upnMembro`
- [ ] Documentação em `docs/listarMembrosListas.md` reflete a mudança

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

| ID | Título | Prioridade |
|----|--------|------------|
| P1 | Migrar membros de DLs para Graph (UPN unificado) | Alta |
| P2 | Proteção de Grupos AD-sync no `ListarEApagar` | Alta |
| P3 | Renomear cabeçalho `eMailMembro` → `upnMembro` | Baixa |
| P3 | Subtipo normalizado para Grupos de Segurança | Baixa |
| P4 | Normalizar coluna `tipoMembro` para DLs | Backlog |
