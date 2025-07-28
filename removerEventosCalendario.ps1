#--------------------------------------------------------------------------------------------------------
# Descricao: Remoção de eventos de uma credencial
# Versao 01 (06/02/23) Jouderian Nobre:
# Versao 02 (04/07/23) Jouderian Nobre: Passa a perguntar a caixa postal ao usuário
#--------------------------------------------------------------------------------------------------------

Clear-Host

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Write-Host "Este script ira remover todos os eventos da caixa postal nos ultimos 120 dias." -ForegroundColor Red
$caixaPostal = Read-Host "Informe a caixa postal"

VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema."
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -ShowBanner:$false

Remove-CalendarEvents `
  -Identity $caixaPostal `
  -Confirm:$false `
  -CancelOrganizedMeetings `
  -QueryWindowInDays 120