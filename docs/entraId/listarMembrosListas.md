# listarMembrosListas.ps1

> **Sinopse**: Lista a relação de membros das Listas de Distribuição e Grupos de Segurança do M365, com suporte a limpeza de grupos vazios.

## Descrição

Conecta ao **Exchange Online** e ao **Microsoft Graph** para exportar todos os membros de:
- **Listas de Distribuição** — via `Get-DistributionGroup` (Exchange Online)
- **Grupos de Segurança** sem e-mail — via `Get-MgGroup -Filter "securityEnabled eq true"` (Graph)

O resultado é gravado em um CSV semicolonado com todos os membros. Grupos e listas sem membros são registrados em um log de auditoria separado com timestamp.

Para **Grupos de Segurança**, os metadados dos membros (`displayName`, `userPrincipalName`, tipo do objeto) são obtidos em **uma única chamada ao Graph por grupo** via `-Property`, eliminando o anti-padrão N+1 que existia anteriormente.

## Detalhes

- **Autor**: Jouderian Nobre
- **Versão Atual**: 08 (12/04/26)
- **Módulos**: `ExchangeOnlineManagement`, `Microsoft.Graph`
- **Escopos Graph**: `Group.Read.All`, `User.Read.All`

## Parâmetros

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `-Acao` | `string` | `ApenasListar` | `ApenasListar`: apenas exporta. `ListarEApagar`: exporta e **remove** grupos/listas vazios. |

## Saídas

| Arquivo | Descrição |
|---------|-----------|
| `membrosListasGrupos.csv` | CSV com todos os membros (separador `;`) |
| `listasVazias_<timestamp>.txt` | Log de auditoria de grupos/listas vazios ou excluídos |

### Colunas do CSV

| Coluna | Fonte | Descrição |
|--------|-------|-----------|
| `idGrupo` | Exchange / Graph | ID do grupo/lista no EntraID |
| `nomeGrupo` | Exchange / Graph | Nome de exibição |
| `eMailGrupo` | Exchange / Graph | E-mail principal do grupo |
| `adSync` | Exchange / Graph | Sincronizado com AD local (`True`/`False`) |
| `tipoGrupo` | Exchange / Graph | Tipo do recipiente (`MailUniversalDistributionGroup`, `Security`, etc.) |
| `idMembro` | Exchange / Graph | Object ID do membro no EntraID |
| `membro` | Exchange / Graph | Nome de exibição do membro |
| `tipo` | Graph | `User` ou `Other` (grupos, dispositivos, SPs) — apenas Grupos de Segurança |
| `eMailMembro` | Exchange: `PrimarySMTPAddress` / Graph: `userPrincipalName` | Identificador do membro |

> **Nota**: Para Listas de Distribuição, a coluna `eMailMembro` usa `PrimarySMTPAddress` do Exchange (pode vir vazio para contatos externos). Para Grupos de Segurança, usa `userPrincipalName` do Graph.

## Comportamento de Limpeza (`ListarEApagar`)

- **Listas sincronizadas com AD** (`IsDirSynced = True`): **nunca removidas** — apenas registradas no log.
- **Listas vazias cloud-only**: removidas via `Remove-DistributionGroup`.
- **Grupos de Segurança vazios**: removidos via `Remove-MgGroup` (incluindo grupos sincronizados com AD, se vazios no EntraID).

## Exemplos

```powershell
# Apenas listar todos os membros
.\listarMembrosListas.ps1

# Listar e apagar grupos/listas vazios
.\listarMembrosListas.ps1 -Acao ListarEApagar
```

## Histórico de Versões

| Versão | Data | Descrição |
|--------|------|-----------|
| 01 | 25/01/22 | Criação do script |
| 02 | 29/04/25 | Otimização com uso de funções da biblioteca |
| 03 | 28/05/25 | Otimização da lógica de exclusão de listas vazias |
| 04 | 17/12/25 | Inclusão de Grupos de Segurança via Microsoft Graph |
| 05 | 26/03/26 | Otimização de performance |
| 06 | 05/04/26 | Parâmetro `-Acao` para modo listar ou apagar |
| 07 | 11/04/26 | Eliminado `Get-MgUser` por membro (N+1 → 1 chamada/grupo via `-Property`); UPN para Grupos de Segurança |
| 08 | 12/04/26 | Enriquecimento híbrido de UPN para membros de DLs: Graph em lote para membros com EntraID, fallback PrimarySMTPAddress para Mail Contacts externos |
