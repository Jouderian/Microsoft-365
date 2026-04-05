<#
.SYNOPSIS
  Testar o envio de mensagem usando credencial HVE
.AUTHOR
  Jouderian Nobre
.VERSION
  01 (20/02/25) - Criacao do script
  02 (05/04/26) - Atualizacao da documentacao
#>

param (
  [Parameter(Mandatory = $true)][string]$eMailRemetente,
  [Parameter(Mandatory = $true)][string]$eMailDestinatario,
  [Parameter(Mandatory = $true)][string]$assunto,
  [Parameter(Mandatory = $true)][string]$mensagem
)

$smtpServer = "smtp-hve.office365.com"
$smtpPort = "587"

# Prompt user for sender credentials
$credentials = Get-Credential -UserName $eMailRemetente -Message "Informe a senha de acesso"

# Test HVE account
Send-MailMessage  `
  -From $eMailRemetente  `
  -To $eMailDestinatario  `
  -Subject $assunto  `
  -Body $mensagem  `
  -Credential $credentials `
  -SmtpServer $smtpServer  `
  -Port $smtpPort  `
  -UseSsl