#--------------------------------------------------------------------------------------------------------
# Descricao: Script para ativar o litigio nas caixas postais com licenças: Office 365 E3 e Business Premium
# Versao 1 (23/06/23) - Jouderian Nobe
# Versao 2 (29/12/24) - Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
#--------------------------------------------------------------------------------------------------------

Clear-Host
$arquivoEntrada = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\credenciaisLitigio.csv"
$inicio = Get-Date

$Modules = Get-Module -Name ExchangeOnlineManagement -ListAvailable
if($Modules.count -eq 0){
  Write-Host Instale o modulo do ExchangeOnlineManagement usando o comando abaixo:`n  Install-Module ExchangeOnlineManagement -ForegroundColor yellow
  Exit
}
Connect-ExchangeOnline

Write-Host Inicio: $inicio
Write-Host Importantdo relação de caixas postais...
$Usuarios = Import-Csv -Delimiter:";" -Path $arquivoEntrada

$totalUsuarios = $Usuarios.Count
$indice = 0

$Usuarios | ForEach-Object {
  $indice++
  Write-Host $_.eMail "($indice/$totalUsuarios)"

  Set-Mailbox $_.eMail `
    -LitigationHoldEnabled $true `
    -LitigationHoldDuration 2551 # dias
}

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()