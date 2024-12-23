# Descricao: Remoção de eventos de uma credencial
# Versao 01 (06/02/23) - Jouderian Nobre
#--------------------------------------------------------------------------------------------------------

$Modules = Get-Module -Name ExchangeOnlineManagement -ListAvailable
if($Modules.count -eq 0){
  Write-Host Instale o modulo do ExchangeOnlineManagement usando o comando abaixo:`n  Install-Module ExchangeOnlineManagement -ForegroundColor yellow
  Exit
}
Connect-ExchangeOnline

Remove-CalendarEvents -Identity moacir.neto@descarpack.com.br -Confirm:$false -CancelOrganizedMeetings -QueryWindowInDays 120