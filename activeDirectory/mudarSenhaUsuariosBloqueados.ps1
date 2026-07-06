#--------------------------------------------------------------------------------------------------------
# Descricao: Muda aleatoriamente a senha dos usuarios bloqueados no Active Directory
# Versao 01 (10/04/25) Jouderian Nobre
#--------------------------------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Import-Module ActiveDirectory

$qtd = 0
$lockedAccounts = Get-ADUser -Filter {Enabled -eq $false}
foreach ($account in $lockedAccounts) {
  $newPassword = geraSenhaAleatoria
  Set-ADAccountPassword -Identity $account.SamAccountName -NewPassword (ConvertTo-SecureString -AsPlainText $newPassword -Force)
  Write-Host $account.SamAccountName
  $qtd++
}

Write-Host "Quantidade de credenciais bloqueadas que mudaram a senha: $($qtd)"