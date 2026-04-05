#--------------------------------------------------------------------------------------------------------
# Descricao: Importa os membros de um Grupo
# Versao 1 (25/07/23) Jouderian Nobre
# Versao 2 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
# Versao 3 (05/04/26) Jouderian Nobre: Atualizacao da documentacao
#--------------------------------------------------------------------------------------------------------
<#
.SYNOPSIS
  Importa os membros de um Grupo
.DESCRIPTION
  O script se conecta ao ambiente do Azure AD, importa as informações gravadas no arquivo CSV e adiciona os membros ao grupo.
.AUTHOR
  Jouderian Nobre
.VERSION
  01 (25/07/23) - Criacao do script
  02 (29/12/24) - Passa a ler a variavel do Windows para local do arquivo
  03 (05/04/26) - Atualizacao da documentacao
#>

Clear-Host

# Declarando variaveis
$membros = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\eMails.txt"
$grupoSegurancaID = "0912d354-1b0a-4JD5-b382-23101dadad52" # nomeGrupo

# Conexao ao Azure AD
Import-Module AzureAD
Connect-AzureAD

Get-Content $membros | ForEach-Object {
  $usuarioAD = Get-AzureADUser -ObjectId $_
  Write-Host $_ "=>" $usuarioAD.ObjectId

  Add-AzureADGroupMember `
    -ObjectId $grupoSegurancaID `
    -RefObjectId $usuarioAD.ObjectId
}