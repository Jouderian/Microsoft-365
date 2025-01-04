#--------------------------------------------------------------------------------------------------------
# Descricao: Mover credenciais de OUs
# Versao 01 (03/01/25) Jouderian Nobre
#--------------------------------------------------------------------------------------------------------

$usuariosBloqueados = Get-ADUser `
  -Filter * `
  -SearchBase "OU=2024,OU=Desligados,OU=0-IntegracaoRM,OU=Unidades,DC=grupoelfa,DC=srv" `
  -SearchScope OneLevel `
  -Properties `
    ObjectGUID, `
    CanonicalName, `
    DisplayName, `
    EmailAddress, `
    POBox `
  Where-Object {
    $_.Enabled -eq $false -and $_.POBox -eq $null
  }

Foreach ($Usuario in $usuariosBloqueados){
  Write-Host "$($Usuario.CanonicalName): $($Usuario.EmailAddress)"
  Move-ADObject -Identity $Usuario.ObjectGUID -TargetPath "OU=2024,OU=Archived,DC=grupoelfa,DC=srv"
}

Write-Host "Total de credenciais movidas: $($usuariosBloqueados.Count)"