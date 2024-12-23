# Descricao: Bloquear os Usuários suspeitos
# Versao: 1 - 19/07/22 - Jouderian Nobre
# Versao: 2 - 18/07/23 - Jouderian Nobre: Alem do bloqueio passamos a identificar a credencial e move-la para uma OU
#--------------------------------------------------------------------------------------------------------

param (
  [string]$arquivo,
  [string]$contaAD
)

if($arquivo -ne $null){
  $Usuarios = Import-Csv -Delimiter:";" -Path "C:\Users\jouderian.nobre\OneDrive\Documentos\WindowsPowerShell\bloquearUsuariosAD.csv"
}

Foreach ($Usuario in $Usuarios){
  Write-Host $Usuario.contaAD

#  Set-ADUser -Identity $Usuario.contaAD `
#    -description "Desativado em $(date -format 'dd/MM/yy')." `
#    -Enabled $false
#  Get-ADUser -Identity $Usuario.contaAD | Move-ADObject -TargetPath "OU=Desligados,OU=0-IntegracaoRM,OU=Unidades,DC=grupoelfa,DC=srv"

  Set-ADUser -Identity $Usuario.contaAD `
    -description "Conta suspeita de inatividade em $(Get-date -format 'MMM/yy')." `
    -Enabled $false
  Get-ADUser -Identity $Usuario.contaAD | Move-ADObject -TargetPath "OU=Suspeitos,OU=0-IntegracaoRM,OU=Unidades,DC=grupoelfa,DC=srv"

}


#Set-Mailbox -Identity adalton.guarda -HiddenFromAddressLists $true -Context "grupoelfa.srv"
#Get-ADObject -Filter {Name -eq ObjectName} -Properties * | Set-ADObject -add @{mailnickname=AttributeValue}