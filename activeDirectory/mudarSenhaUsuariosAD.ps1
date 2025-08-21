#-------------------------------------------------------------------------------
# Descrição: Redefine as senhas de uma lista de credenciais
# Versao: 1 (22/08/23) Jouderian Nobre: 
#-------------------------------------------------------------------------------

Clear-Host

$Users = Import-Csv -Delimiter:";" -Path "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\mudarSenhas.csv"
#$Users | Format-Table

$Users | ForEach-Object {
  Write-Host $_.contaAD
  $senha = ConvertTo-SecureString -AsPlainText $_.Senha -force

  Set-ADAccountPassword -Identity $_.contaAD `
    -Reset `
    -NewPassword $senha
}