#--------------------------------------------------------------------------------------------------------
# Descricao: Listar todos os membros de uma caixa postal compartilhada no Exchange Online (M365)
# Versao 1 (13/05/25) Jouderian Nobre
#--------------------------------------------------------------------------------------------------------

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
  Connect-ExchangeOnline
} catch {
  Write-Host "Erro ao conectar ao Exchange Online: $_" -ForegroundColor Red
  Exit
}

Write-Host "`n`n`n`n`n`n`nInicio:" $inicio
Write-Host "Pesquisando Relacao de Caixas Compartilhadas..."
$SharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited
$totalCaixas = $SharedMailboxes.Count

foreach ($Mailbox in $SharedMailboxes){

  $indice++

  if ($indice % 10 -eq 0){ # Atualiza o progresso a cada 10 caixas processadas
    Write-Progress -Activity "Exportando caixas compartilhadas" -Status "Progresso: $indice de $totalCaixas extraidas" -PercentComplete (($indice / $totalCaixas) * 100)
  }

  try {
    # Obter permissões de acesso à caixa postal compartilhada
    $Permissions = Get-MailboxPermission -Identity $Mailbox.PrimarySmtpAddress

    # Filtrar apenas os usuários com permissões explícitas
    $Members = $Permissions | Where-Object { $_.User -notlike "NT AUTHORITY\SELF" -and $_.User -notlike "S-1-*" }

    # Adicionar os resultados à lista
    foreach ($Member in $Members){
      $Results += [PSCustomObject]@{
        SharedMailbox = $Mailbox.PrimarySmtpAddress
        User = $Member.User
        AccessRights = ($Member.AccessRights -join ", ")
      }
    }
  } catch {
    Write-Host "Erro ao processar a caixa postal $($Mailbox.PrimarySmtpAddress): $($_.Exception.Message)" -ForegroundColor Red
  }
}
Write-Progress -Activity "Exportando caixas compartilhadas" -PercentComplete 100

#$Results | Format-Table -AutoSize

$Results | Export-Csv -Path $arquivo -NoTypeInformation -Encoding UTF8

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()

Disconnect-ExchangeOnline -Confirm:$false