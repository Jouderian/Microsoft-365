# Plan: Importar Membros do Grupo de Segurança (Graph)

## Como

1.  **Ferramental Moderno:**
    *   Módulo alvo migra de `AzureAD` *(obsoleto)* para **Microsoft.Graph** (Authentication, Groups e Users).
    *   Escopos na conexão precisam cobrir leitura de grupo e gravação de membro: `Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read.All"`.

2.  **Dados e Parser:**
    *   O `$arquivoCsv` fixará para `$env:ONEDRIVE\Documentos\WindowsPowerShell\membrosGruposSeguranca.csv` por conveniência e facilidade de descoberta do cliente.
    *   Faremos loop na coleção via `foreach` instanciado, acompanhado por relatórios Progress.

3.  **Lógica do Script Modificado:**
    *   Manter a inicialização `Clear-Host` da matriz atual, mas trazer a biblioteca `$PSScriptRoot\bibliotecaDeFuncoes.ps1`.
    *   Validar Módulos antes de seguir.
    *   Capturar os IDs via *Queries*:
        1.  O `$linha.eMailUsuario` chama o `Get-MgUser -UserId`.
        2.  O `$linha.nomeGrupo` chama o `Get-MgGroup` buscando adequadamente na base da Microsoft. *Atenção ao buscar grupo por nome, pode retornar array, devemos prever First ou exigir filtro Exato.*
    *   Vincular através da API Graph nativa: `New-MgGroupMember -GroupId $_Grupo.Id -DirectoryObjectId $_User.Id`.
    *   Tratar falhas nos casos de Grupos inexistentes ou typos no e-Mail com o `gravaLog`.
