#-------------------------------------------------------------------------------
# Descricao: Expirar as seções dos usuários no M365 que estao expirados do AD
# Versao: 1 (03/05/23) Jouderian Nobre
# Versao: 2 (07/01/25) Jouderian Nobre: Inclusão no log da data de expiracao antes da remocao
#-------------------------------------------------------------------------------

Clear-Host

$Modules = Get-Module -Name AzureAD -ListAvailable
if($Modules.count -eq 0){
  Write-Host Instale o modulo do AzureAD usando o comando abaixo:`n  Install-Module AzureAD -ForegroundColor yellow
  Exit
}
Connect-AzureAD -AccountId jouderian.nobre.infra@grupoElfa.onMicrosoft.com

$inicio = Get-Date

Write-Host Inicio: $inicio
Write-Host Pesquisando relacao de credenciais expiradas...
$usuarios = Search-ADAccount -AccountExpired -UsersOnly
$totalUsuarios = $usuarios.Count
$indice = 0

Foreach ($usuario in $usuarios){

  $indice++
  Write-Host $usuario.UserPrincipalName "($indice/$totalUsuarios)"

  if($usuario.Enabled){
      $userID = Get-AzureADUser -ObjectId $usuario.UserPrincipalName
#      if($userID.POBox -eq 'O365' -or $userID.POBox -eq 'NOGAL'){
        Revoke-AzureADUserAllRefreshToken -ObjectID $userID.ObjectId
#      }
  }else{
    Write-Host "  => Usuário bloqueado, vencimento removido: $($usuario.AccountExpirationDate.ToString('dd/MM/yy HH:mm'))"
    Clear-ADAccountExpiration -Identity $Usuario.SamAccountName
  }
}

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()