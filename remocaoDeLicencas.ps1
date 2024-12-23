#-------------------------------------------------------------------------------
# Descrição: Remover as licenças os usuarios do tenant
# Versao: 1 - 02/06/21 (Andre Cardoso)
# Versao: 2 - 31/01/24 (Jouderian Nobre): Remover as licenas de uma lista
#-------------------------------------------------------------------------------

Clear-Host

$Modules = Get-InstalledModule Microsoft.Graph
if($Modules.count -eq 0){
  Write-Host Instale o modulo do Microsoft.Graph usando o comando abaixo:`n  Install-Module Microsoft.Graph -ForegroundColor yellow
  Exit
}
Connect-MgGraph -Scopes User.ReadWrite.All, Organization.Read.All

$arquivo = "C:\Users\jouderian.nobre\OneDrive\Documentos\WindowsPowerShell\listaDeCaixasPostais.csv"
$licencas = 'reseller-account:O365_BUSINESS,reseller-account:O365_BUSINESS_ESSENTIALS'

$inicio = Get-Date

Write-Host Inicio: $inicio
Write-Host Importando caixas para remoção
$Users = Import-Csv -Delimiter:";" -Path $arquivo

Write-Host 'Removendo licenças: ' $licencas
$Users | ForEach-Object {
  Write-Host $_.UPN

  Set-MsolUserLicense `
  -UserPrincipalName $_.UPN `
  -RemoveLicenses reseller-account:O365_BUSINESS
  #-AddLicenses @{Name="Office365F1"}
}

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()


# Business Basic: reseller-account:O365_BUSINESS
# AppsBusiness: reseller-account:O365_BUSINESS_ESSENTIALS