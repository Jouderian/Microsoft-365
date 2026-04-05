<#
.SYNOPSIS
  Ativa o autoarquivamento das caixas postais
.DESCRIPTION
  O script se conecta ao ambiente do Microsoft 365, busca todas as caixas postais existentes e ativa o autoarquivamento das caixas postais que nao possuem.
.AUTHOR
  Jouderian Nobre
.VERSION
  01 (02/02/22) - Criacao do script
  02 (28/10/24) - Melhoria no processamento e registro de acoes
  03 (29/12/24) - Passa a ler a variavel do Windows para local do arquivo
  04 (27/01/26) - Passa a analisar todas as caixas postais e ativa das que nao possuem
.OUTPUTS
  Arquivo CSV com a relacao de caixas postais
#>

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$indice = 0
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\autoArquivamento_$($inicio.ToString('MMMyy')).txt"

gravaLOG "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))" -tipo WRN -arquivo $logs

# Validacoes
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema." -arquivoLogs $logs

# Conexoes
try {
  Import-Module ExchangeOnlineManagement
  Connect-ExchangeOnline -ShowBanner:$false
  gravaLOG "Conectado ao Exchange Online" -tipo OK -arquivo $logs
}
catch {
  gravaLOG "ao conectar ao Exchange Online: $($_.Exception.Message)" -tipo ERR -arquivo $logs
  Exit
}

gravaLOG "Buscando caixas postais de usuario..." -tipo STP -arquivo $logs -mostraTempo:$true
$caixasPostais = Get-Mailbox -Filter "RecipientTypeDetails -eq 'UserMailbox'" -ResultSize Unlimited

$totalCaixasPostais = $caixasPostais.Count
gravaLOG "Total de caixas postais encontradas: $totalCaixasPostais" -tipo STP -arquivo $logs -mostraTempo:$true

$ativadasComSucesso = 0
$comErro = 0
$jaPossui = 0

Foreach ($caixaPostal in $caixasPostais) {
  $indice++
  Write-Progress -Activity "Ativando autoarquivamento" -Status "Progresso: $indice de $totalCaixasPostais processadas" -PercentComplete (($indice / $totalCaixasPostais) * 100)

  try {
    # Verifica se o arquivo nao esta ativo OU se nao tem auto-expansao
    if (
      $caixaPostal.ArchiveStatus -eq 'None' -or
      $caixaPostal.AutoExpandingArchiveEnabled -eq $false
    ) {
      gravaLOG "$indice/$totalCaixasPostais - $($caixaPostal.DisplayName) ($($caixaPostal.PrimarySmtpAddress)) - Status Arquivo: $($caixaPostal.ArchiveStatus) / AutoExpansao: $($caixaPostal.AutoExpandingArchiveEnabled)" -tipo STP -arquivo $logs

      # Ativa o arquivo se nao estiver ativo
      if ($caixaPostal.ArchiveStatus -eq 'None') {
        Enable-Mailbox -Identity $caixaPostal.PrimarySmtpAddress -Archive -WarningAction SilentlyContinue -ErrorAction Stop
        gravaLOG "  Arquivamento ativado" -tipo OK -arquivo $logs
      }

      # Ativa o auto-expandindo arquivo se nao estiver ativo (quando limite de 100GB eh atingido, expande)
      if ($caixaPostal.AutoExpandingArchiveEnabled -eq $false) {
        Enable-Mailbox -Identity $caixaPostal.PrimarySmtpAddress -AutoExpandingArchive -WarningAction SilentlyContinue -ErrorAction Stop
        gravaLOG "  Arquivamento auto-expandindo ativado" -tipo STP -arquivo $logs
      }

      $ativadasComSucesso++
    }
    else {
      $jaPossui++
    }
  }
  catch {
    gravaLOG "$($_.Exception.Message)" -tipo ERR -mostraTempo:$true -arquivo $logs
    $comErro++
  }
}

Write-Progress -Activity "Ativando autoarquivamento" -PercentComplete 100

# Finalizando o script
$final = Get-Date
gravaLOG "Autoarquivamento ativado com sucesso: $ativadasComSucesso / Ja possuem arquivo e auto-expansao: $jaPossui / Erros: $comErro" -tipo OK -mostraTempo:$true -arquivo $logs
gravaLOG "Tempo de duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())" -tipo WRN -arquivo $logs -mostraTempo:$true