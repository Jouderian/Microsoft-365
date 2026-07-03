<#
  .SYNOPSIS
    Lista caixas compartilhadas e caixas com delegações de acesso no Exchange Online
  .DESCRIPTION
    O script se conecta ao Exchange Online, busca todas as caixas postais e filtra apenas os registros do tipo SharedMailbox ou UserMailbox que possuam membros com permissão explícita de acesso. Inclui caixas compartilhadas sem membros para fins de auditoria.
  .AUTHOR
    Jouderian Nobre
  .VERSION
    01 (13/05/25) - Criacao do script
    02 (14/05/25) - Mostra tambem as caixas compartilhadas sem membros
    03 (27/02/26) - Adiciona coluna MailboxType ao relatorio
    04 (27/02/26) - Passa a consultar todas as caixas postais sem filtrar por SharedMailbox
    05 (27/02/26) - Filtra resultados para incluir apenas SharedMailbox ou UserMailbox com membros
    06 (05/04/26) - Atualizacao da documentacao
  .OUTPUT
    Arquivo CSV com a relacao de caixas compartilhadas e seus membros.
#>

Clear-Host

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"
#--------------------------------------------------------------------- VARIAVEIS
$indice = 0
$Results = @()
$inicio = Get-Date
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaDeCaixasCompartilhadas.csv"

#-------------------------------------------------------------------- VALIDACOES
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema."
try {
  Connect-ExchangeOnline -showbanner:$false -ErrorAction Stop
} catch {
  Write-Host "Erro ao conectar ao Exchange Online: $($_.Exception.Message)" -ForegroundColor Red
  Exit
}

Write-Host "`n`n`n`n`n`n`nInicio:" $inicio
Write-Host "Pesquisando relacao de caixas postais (todos os tipos)..."
$Mailboxes = Get-Mailbox -ResultSize Unlimited
$totalCaixas = $Mailboxes.Count

Write-Host "Analisando $totalCaixas caixas postais..."
foreach ($Mailbox in $Mailboxes){

  $indice++

  if ($indice % 10 -eq 0){
    Write-Progress -Activity "Exportando caixas" -Status "Progresso: $indice de $totalCaixas extraidas" -PercentComplete (($indice / $totalCaixas) * 100)
  }

  try {
    $Permissions = Get-MailboxPermission -Identity $Mailbox.PrimarySmtpAddress

    # Filtrar apenas os usuários com permissões explícitas
    $Members = $Permissions | Where-Object { $_.User -notlike "NT AUTHORITY\SELF" -and $_.User -notlike "S-1-*" }

    # se não for shared e não tiver membros, ignorar
    if (
      $Mailbox.RecipientTypeDetails -ne 'SharedMailbox' -and
      $Members.Count -eq 0
    ){
      continue
    }
  } catch {
    Write-Host "Erro ao processar a caixa postal $($Mailbox.PrimarySmtpAddress): $($_.Exception.Message)" -ForegroundColor Red
    continue
  }

  if ($Members.Count -eq 0){
    $Results += [PSCustomObject]@{
      SharedMailbox = $Mailbox.PrimarySmtpAddress
      MailboxType   = $Mailbox.RecipientTypeDetails
      Membros = "SEM MEMBROS"
    }
    continue
  }

  foreach ($Member in $Members){
    $Results += [PSCustomObject]@{
      SharedMailbox = $Mailbox.PrimarySmtpAddress
      MailboxType   = $Mailbox.RecipientTypeDetails
      Membros = $Member.User
    }
  }
}
Write-Progress -Activity "Exportando caixas compartilhadas" -PercentComplete 100

$Results | Export-Csv -Path $arquivo -NoTypeInformation -Encoding UTF8

$final = Get-Date
Write-Host "`nInicio: $inicio Final: $final > Tempo:" (NEW-TIMESPAN -Start $inicio -End $final).ToString()

Disconnect-ExchangeOnline -Confirm:$false