# listarAdministradoresTenant.ps1

> **Sinopse**: Lista todos os usuários com papéis administrativos no tenant M365 via Microsoft Graph.

## Descrição
O script se conecta ao Microsoft Graph, busca todos os papéis administrativos (Directory Roles) configurados no tenant do M365, localiza os membros de cada um desses papéis, obtém os detalhes dos usuários correspondentes e exporta as informações para um arquivo CSV.

## Detalhes
- **Autor**: Jouderian Nobre
- **Versão Atual**: 6 (05/06/26) - Melhoria de performance no loop, tratamento de erro e implementa expansão de grupos de segurança associados a papéis e coluna viaGrupo
- **Saída**: Arquivo CSV (`$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaDeMembrosAdministrativos.csv`) contendo as seguintes colunas:
  - **grupoId**: ID do papel administrativo.
  - **grupo**: Nome de exibição do papel (ex: Global Administrator).
  - **usuarioID**: ID único do usuário.
  - **usuario**: Nome de exibição do usuário.
  - **UPN**: User Principal Name do usuário.
  - **ativa**: Status da conta (habilitada/desabilitada).
  - **viaGrupo**: Indica se o privilégio é uma atribuição `Direta` ou o nome do Grupo de Segurança (ex: `SG-INTUNE-Admins`) por meio do qual o usuário obteve acesso.

## Características Especiais
- **Expansão de Grupos:** Caso um papel administrativo seja atribuído a um Grupo de Segurança (como `SG-INTUNE-Admins`), o script detecta o grupo e expande recursivamente todos os seus membros para listar os usuários que de fato herdaram o acesso administrativo.
- **Resiliência:** O script processa cada membro do grupo administrativo dentro de um bloco `try/catch`. Se houver falha ao carregar informações de um usuário específico (como Service Principals ou contas deletadas recentemente), um aviso é exibido no console e a execução continua para os demais membros.
- **Performance:** Utiliza atribuição direta via pipeline do PowerShell no loop principal, eliminando o gargalo de redimensionamento de arrays via operador `+=`.

## Módulos / Dependências
- **Microsoft.Graph** (User.Read.All, Directory.Read.All, RoleManagement.Read.Directory)
- **bibliotecaDeFuncoes.ps1** (Carregada a partir de `C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1`)
