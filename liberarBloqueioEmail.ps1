#--------------------------------------------------------------------------------------------------------
# Descricao: Liberar uma caixa postal bloqueada no ExchangeOnline
# Versao 1 (06/10/25) Jouderian Nobre
#--------------------------------------------------------------------------------------------------------

Clear-Host

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Write-Host "Este script ira Liberar os bloqueios uma caixa postal." -ForegroundColor Red

$caixaPostal = Read-Host "Informe a caixa postal"

VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema."
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -ShowBanner:$false

Get-BlockedSenderAddress
Remove-BlockedSenderAddress -SenderAddress $caixaPostal