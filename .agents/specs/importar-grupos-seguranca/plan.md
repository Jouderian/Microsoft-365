# Plan: Importar Grupos de Segurança (Graph)

## Como

1.  **Ferramental e Bibliotecas:**
    *   O motor a ser utilizado é o PowerShell (`pwsh` / `powershell`).
    *   O módulo principal para provisionamento de segurança (Identity) será o **Microsoft.Graph**.  (A biblioteca `bibliotecaDeFuncoes.ps1` já conforta validações de instalação usando a assinatura `verificaModulo -NomeModulo "Microsoft.Graph.Groups" ... ` ou genericamente `Microsoft.Graph`).
    *   Iremos instanciar conexões utilizando os escopos básicos: `Group.ReadWrite.All` e `User.Read.All` (ou requerendo interação explícita do administrador no Prompt).

2.  **Dados e Parser:**
    *   O arquivo será importado via `Import-Csv` com separador padrão (`;` ou `,` dependendo da cultura local, recomendado especificar via Input interativo como Windows Form picker ou path em console, que no nosso caso `caminhoArquivo` fixado ou capturado será utilizado).

3.  **Lógica do Script (`importarGruposSeguranca.ps1`):**
    *   Chamar a biblioteca base (`. ".\bibliotecaDeFuncoes.ps1"`).
    *   Validar Módulos: `Microsoft.Graph.Groups` e `Microsoft.Graph.Users`.
    *   Apresentar interface Graph Auth `Connect-MgGraph -Scopes "Group.ReadWrite.All, User.Read.All"`.
    *   Iteração com Tratamento Progressivo (`Write-Progress`).
    *   Dentro de um `foreach` ou `ForEach-Object`:
        1.  Tratar a string "Nome" invocando `trataTexto` se necessário (ou aceitar o formato preenchido do CSV com segurança extraindo acentos via `removerAcentos`). As GroupNames por vezes recusam caracteres impróprios internamente.
        2.  Buscar o userId referente a `$grupo.eMailProprietário` via `Get-MgUser -UserId $.eMailProprietário`.
        3.  Criar o grupo: `New-MgGroup -DisplayName $grupo.Nome -Description $grupo.Descricao -MailEnabled $false -SecurityEnabled $true -MailNickname $apelidoTratadoSemEspacos`.
        4.  Adicionar Proprietário: `New-MgGroupOwnerByRef -GroupId $novoGrupo.Id -DirectoryObjectId $user.Id`.
        5.  `catch` os erros com output apropriado com a função de apoio `gravaLOG`.

4.  **Logging e Retenção:**
    *   Criação de txt em `"$($env:ONEDRIVE)\Documentos\WindowsPowerShell\importarGruposSeguranca_*"`.
