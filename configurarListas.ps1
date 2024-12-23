#-------------------------------------------------------------------------------
# Descricao: Configurar as Listas de Distribuições
# Versao: 1 - 12/12/24 (Jouderian Nobre)
#-------------------------------------------------------------------------------

Clear-Host

#--------------------------------------------------------- Conectando ao servico
$Modules = Get-Module -Name ExchangeOnlineManagement -ListAvailable
if($Modules.count -eq 0){
  Write-Host Instale o modulo do ExchangeOnlineManagement usando o comando abaixo:`n  Install-Module ExchangeOnlineManagement -ForegroundColor yellow
  Exit
}
Connect-ExchangeOnline

#---------------------------------------------------------- Declarando variaveis
$inicio = Get-Date

$moderadores = @(
  "grilo@grupo.com.br",
  "ramos@grupo.com.br",
  "domingos@grupo.com.br",
  "silva@grupo.com.br",
  "costa@grupo.com.br",
  "giacomel@grupo.com.br"
)

$listas = @(
  "554418ca-82d6-4jdd-8e17-8a88026fe1cc",
  "4bce5189-b7e7-49dc-a5c5-c82e715ede8c",
  "df17c848-9f93-4kfc-a5e8-fcda455c8ae1",
)

Write-Host "`n`n`n`n`n`n`nInicio:" $inicio
Write-Host "Configuran as Listas de Distribuicao abaixo: "
Foreach ($lista in $listas){

  Write-Host "  $((Get-DistributionGroup -Identity $lista)): $($lista)"

  Set-DistributionGroup `
    -Identity $lista `
    -HiddenFromAddressListsEnabled $true `
    -ModerationEnabled $true `
    -ModeratedBy $moderadores `
    -BypassModerationFromSendersOrMembers @() `
    -SendModerationNotifications Internal

  #Set-DistributionGroup -Identity $lista -BypassModerationFromSendersOrMembers @{Add="comunicacao@grupoelfa.com.br",Remove="comunicacao@grupoelfa.com.br"}
}

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()