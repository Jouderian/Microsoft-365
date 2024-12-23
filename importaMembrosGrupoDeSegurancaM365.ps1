#--------------------------------------------------------------------------------------------------------
# Descricao: Importa os membros de um Grupo de Segurança
# Versao: 1 (25/07/23) Jouderian Nobre
#--------------------------------------------------------------------------------------------------------

Connect-AzureAD

$grupoSegurancaID = "0912d354-1b0a-4JD5-b382-23101dadad52" # nomeGrupo

Get-Content "C:\Users\jouderian.nobre\OneDrive\Documentos\WindowsPowerShell\eMails.txt" | ForEach-Object {
  $usuarioAD = Get-AzureADUser -ObjectId $_
  Write-Host $_ "=>" $usuarioAD.ObjectId

  Add-AzureADGroupMember -ObjectId $grupoSegurancaID -RefObjectId $usuarioAD.ObjectId
}