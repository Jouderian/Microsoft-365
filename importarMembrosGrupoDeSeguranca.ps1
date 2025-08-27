#--------------------------------------------------------------------------------------------------------
# Descricao: Importa os membros de um Grupo de Segurança
# Versao 1 (25/07/23) Jouderian Nobre
# Versao 2 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
#--------------------------------------------------------------------------------------------------------

Connect-AzureAD

$grupoSegurancaID = "0912d354-1b0a-4JD5-b382-23101dadad52" # nomeGrupo

Get-Content "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\eMails.txt" | ForEach-Object {
  $usuarioAD = Get-AzureADUser -ObjectId $_
  Write-Host $_ "=>" $usuarioAD.ObjectId

  Add-AzureADGroupMember -ObjectId $grupoSegurancaID -RefObjectId $usuarioAD.ObjectId
}