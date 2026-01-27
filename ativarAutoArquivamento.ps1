#--------------------------------------------------------------------------------------------------------
# Descricao: Ativar o autoarquivamento das caixas postais
# Versao 1 (02/02/22) Jouderian Nobre: Criacao do script
# Versao 2 (28/10/24) Jouderian Nobre: Melhoria no processamento e registro de acoes
# Versao 3 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
# Versao 4 (27/01/26) Jouderian Nobre: Passa a analisar todas as caixas postais e ativa das que nao possuem
#--------------------------------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$indice = 0
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\autoArquivamento_$($inicio.ToString('MMMyy')).txt"

gravaLOG -arquivo $logs -texto "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))"

# Validacoes
VerificaModulo -arquivoLogs $logs -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema."

# Conexoes
try {
  Import-Module ExchangeOnlineManagement
  Connect-ExchangeOnline -ShowBanner:$false
} catch {
  gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('HH:mm:ss')) - ao conectar ao Exchange Online: $($_.Exception.Message)" -erro:$true
  Exit
}

gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('HH:mm:ss')) - Buscando caixas postais de usuario..."
$caixasPostais = Get-Mailbox -Filter "RecipientTypeDetails -eq 'UserMailbox'" -ResultSize Unlimited

$totalCaixasPostais = $caixasPostais.Count
gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('HH:mm:ss')) - Total de caixas postais encontradas: $totalCaixasPostais"

$ativadasComSucesso = 0
$comErro = 0
$jaPossui = 0

Foreach ($caixaPostal in $caixasPostais){
  $indice++
  Write-Progress -Activity "Ativando autoarquivamento" -Status "Progresso: $indice de $totalCaixasPostais processadas" -PercentComplete (($indice / $totalCaixasPostais) * 100)

  try {
    # Verifica se o arquivo nao esta ativo OU se nao tem auto-expansao
    if (
      $caixaPostal.ArchiveStatus -eq 'None' -or
      $caixaPostal.AutoExpandingArchiveEnabled -eq $false
    ){
      gravaLOG -arquivo $logs -texto "$indice/$totalCaixasPostais - $($caixaPostal.DisplayName) ($($caixaPostal.PrimarySmtpAddress)) - Status Arquivo: $($caixaPostal.ArchiveStatus) / AutoExpansao: $($caixaPostal.AutoExpandingArchiveEnabled)"

      # Ativa o arquivo se nao estiver ativo
      if ($caixaPostal.ArchiveStatus -eq 'None'){
        Enable-Mailbox -Identity $caixaPostal.PrimarySmtpAddress -Archive -WarningAction SilentlyContinue -ErrorAction Stop
        gravaLOG -arquivo $logs -texto "  Arquivamento ativado"
      }

      # Ativa o auto-expandindo arquivo se nao estiver ativo (quando limite de 100GB eh atingido, expande)
      if ($caixaPostal.AutoExpandingArchiveEnabled -eq $false){
        Enable-Mailbox -Identity $caixaPostal.PrimarySmtpAddress -AutoExpandingArchive -WarningAction SilentlyContinue -ErrorAction Stop
        gravaLOG -arquivo $logs -texto "  Arquivamento auto-expandindo ativado"
      }

      $ativadasComSucesso++
    } else {
      $jaPossui++
    }
  } catch {
    gravaLOG -arquivo $logs -texto "$($_.Exception.Message)" -erro:$true
    $comErro++
  }
}

Write-Progress -Activity "Ativando autoarquivamento" -PercentComplete 100

# Finalizando o script
$final = Get-Date
gravaLOG -arquivo $logs -texto "Autoarquivamento ativado com sucesso: $ativadasComSucesso / Ja possuem arquivo e auto-expansao: $jaPossui / Erros: $comErro"
gravaLOG -arquivo $logs -texto "$($final.ToString('dd/MM/yy HH:mm:ss')) - Tempo de duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())"