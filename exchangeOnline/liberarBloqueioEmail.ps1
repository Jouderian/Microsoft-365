<#
  .SYNOPSIS
    Libera uma caixa postal bloqueada no Exchange Online
  .DESCRIPTION
    O script se conecta ao Exchange Online e remove o bloqueio de envio de uma caixa postal específica, informada interativamente pelo operador.
  .AUTHOR
    Jouderian Nobre
  .VERSION
    01 (06/10/25) - Criacao do script
    02 (05/04/26) - Atualizacao da documentacao
  .OUTPUT
    Saída no console com o status da operação de liberação.
#>

Clear-Host

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Write-Host "Este script ira Liberar os bloqueios uma caixa postal." -ForegroundColor Red

$caixaPostal = Read-Host "Informe a caixa postal"

VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema."
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -ShowBanner:$false

Get-BlockedSenderAddress
Remove-BlockedSenderAddress -SenderAddress $caixaPostal