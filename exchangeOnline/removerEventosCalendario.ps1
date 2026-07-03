<#
.SYNOPSIS
  Remove eventos de uma caixa postal
.DESCRIPTION
  O script se conecta ao ambiente do Microsoft 365, busca todos os eventos existentes e extrai uma série de informações sobre cada evento, como nome, UPN, cidade, empresa, tipo, tamanho utilizado, entre outros. As informações são gravadas em um arquivo CSV para análise posterior.
.AUTHOR
  Jouderian Nobre
.VERSION
  01 (06/02/23) - Criacao do script
  02 (04/07/23) - Passa a perguntar a caixa postal ao usuário
  03 (05/04/26) - Atualizacao da documentacao
#>

Clear-Host

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Write-Host "Este script ira REMOVER todos os eventos da caixa postal nos ultimos 120 dias." -ForegroundColor Red
$caixaPostal = Read-Host "Informe a caixa postal"

VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema."
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -ShowBanner:$false

Remove-CalendarEvents `
  -Identity $caixaPostal `
  -Confirm:$false `
  -CancelOrganizedMeetings `
  -QueryWindowInDays 120