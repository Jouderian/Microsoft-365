#--------------------------------------------------------------------------------------------------------
# Descricao: Mover credenciais de OUs
# Versao 01 (03/01/25) Jouderian Nobre
#--------------------------------------------------------------------------------------------------------

# Variaveis
$localBusca = "OU=Unidades,DC=grupoelfa,DC=srv" # "OU=Desligados,OU=0-IntegracaoRM,OU=Unidades,DC=grupoelfa,DC=srv" `
$localDestino = "OU=Suspeitos,OU=0-IntegracaoRM,OU=Unidades,DC=grupoelfa,DC=srv"
$escopoBusca = "OneLevel" #Subtree = para busca recursiva

$usuariosBloqueados = Get-ADUser `
  -Filter * `
  -SearchBase $localBusca `
  -SearchScope $escopoBusca `
  -Properties `
    ObjectGUID, `
    CanonicalName, `
    DisplayName, `
    EmailAddress, `
    POBox `
  | Where-Object {
    $_.Enabled -eq $false -and $_.POBox -eq $null
  }

Foreach ($Usuario in $usuariosBloqueados){
  Write-Host "$($Usuario.CanonicalName): $($Usuario.EmailAddress)"
  Move-ADObject -Identity $Usuario.ObjectGUID -TargetPath $localDestino
}

Write-Host "Total de credenciais movidas: $($usuariosBloqueados.Count)"