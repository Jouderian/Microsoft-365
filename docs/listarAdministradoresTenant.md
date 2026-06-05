# listarAdministradoresTenant.ps1

> **Sinopse**: Lista todos os usuários com papéis administrativos no tenant M365 via Microsoft Graph.

## Descrição
O script se conecta ao Microsoft Graph, busca todos os papéis administrativos (Directory Roles) configurados no tenant do M365, localiza os membros de cada um desses papéis, obtém os detalhes dos usuários correspondentes e exporta as informações para um arquivo CSV.

## Detalhes
- **Autor**: Jouderian Nobre
- **Versão Atual**: 5 (11/02/26) - Migrado para Microsoft Graph
- **Saída**: Arquivo CSV (`$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaDeMembrosAdministrativos.csv`) contendo as seguintes colunas:
  - **grupoId**: ID do papel administrativo.
  - **grupo**: Nome de exibição do papel (ex: Global Administrator).
  - **usuarioID**: ID único do usuário.
  - **usuario**: Nome de exibição do usuário.
  - **UPN**: User Principal Name do usuário.
  - **ativa**: Status da conta (habilitada/desabilitada).

## Módulos / Dependências
- **Microsoft.Graph** (User.Read.All, Directory.Read.All, RoleManagement.Read.Directory)
- **bibliotecaDeFuncoes.ps1** (Carregada a partir de `C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1`)
