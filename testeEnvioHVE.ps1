#--------------------------------------------------------------------------------------------------------
# Descricao: Testar o envio de mensagem usando credencial HVE
# Versao 1 (20/02/25) Jouderian
#--------------------------------------------------------------------------------------------------------

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