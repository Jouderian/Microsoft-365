<#
  .SYNOPSIS
    Extrai uma listagem com todas as caixas postais do Exchange (Microsoft 365).
  .DESCRIPTION
    O script se conecta ao ambiente do Microsoft 365, busca todas as caixas postais existentes e extrai uma série de informações sobre cada caixa postal, como nome, UPN, cidade, empresa, tipo, tamanho utilizado, entre outros. As informações são gravadas em um arquivo CSV para análise posterior.
  .AUTHOR
    Jouderian Nobre
  .VERSION
    01 (16/07/24) Jouderian Nobre: Criacao do script
    02 (05/04/26) Jouderian Nobre: Atualizacao da documentacao
  .OUTPUT
    Arquivo CSV com a relacao de caixas postais
#>

Clear-Host

VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema." -arquivoLogs $logs

# Conexoes
try {
  Import-Module ExchangeOnlineManagement
  Connect-ExchangeOnline -ShowBanner:$false
}
catch {
  gravaLOG -texto "Erro ao conectar ao Exchange Online: $($_.Exception.Message)" -tipo Erro -arquivo $logs -mostraTempo:$true
  Exit
}

$inicio = Get-Date

Write-Host Inicio: $inicio
Write-Host Pesquisando Relacao de Caixas Postais no ExchangeOnline...

$caixas = Get-Mailbox -ResultSize Unlimited -Filter 'DeliverToMailboxAndForward -eq $true' -ExpandProperty ForwardingSmtpAddress

$totalCaixas = $caixas.Count
$indice = 0

Write-Host "Tipo,Nome,UPN,Destino"

foreach ($caixa in $caixas) {

  $indice++
  Write-Progress -Activity "Analisando caixas postais" -Status "Progresso: $($indice) de $($totalCaixas)" -PercentComplete ($indice / $totalCaixas * 100)

  Write-Host "$($caixa.RecipientTypeDetails),$($caixa.Name),$($caixa.UserPrincipalName),$($caixa.ForwardingSmtpAddress)"
}

Write-Progress -Activity "Analisando caixas postais" -PercentComplete 100

# Finalizando o script
$final = Get-Date
Write-Host "`nInicio: $inicio"
Write-Host "Final: $final"
Write-Host "Tempo de duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())"