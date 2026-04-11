# Plano de Implementação: Refatoração de Listas e Grupos

## Arquitetura
A alteração fará uso os mesmos módulos atuais: `ExchangeOnlineManagement` e `Microsoft.Graph`. 

### `listarMembrosListas.ps1`
1. Introdução de `[CmdletBinding()]` e `Param()`.
2. O Parametro `-Acao` aceitará validação Set `ApenasListar` (Default) e `ListarEApagar`.
3. Substituição da remoção compulsória no bloco de DL (Distribution List) para atuar condicionalmente de acordo com a Ação.
4. Extensão da condicional para abarcar os Security Groups no final do laço de MsGraph (`Remove-MgGroup`).

### `apagarListasSemMembros.ps1`
Uma abstração focada. Irá iterar:
1. `Get-DistributionGroup` com filtragem para remoção dos itens `Get-DistributionGroupMember` onde `-eq 0`.
2. `Get-MgGroup` com filtro para os `SecurityEnabled` onde `Get-MgGroupMember` seja 0, invocando `Remove-MgGroup` em seguida.
3. Será amparado pelo `. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"` para logging.

## Dependências
Permanece o mesmo escopo de Azure. Sem alterações em permissão de OAUTH ou afins.
