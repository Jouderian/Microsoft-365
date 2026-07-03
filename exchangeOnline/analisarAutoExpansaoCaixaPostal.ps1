<#
.SYNOPSIS
  Audita o Archive e a Auto-Expanding Archive das caixas postais no Exchange Online.

.PARAMETER UserPrincipalName
  UPN de um usuário específico. Se omitido, roda para todos os usuários com mailbox.

.PARAMETER ExportCsvPath
  Caminho opcional para exportar o relatório em CSV.

.NOTES
  - O Auto-Expanding é disparado quando o arquivo atinge ~90 GB e pode levar até 30 dias para provisionar novos shards. (Fonte: Microsoft Learn)
  - Cada shard do arquivo tem quota ~100 GB; o total do arquivo pode atingir ~1,5 TB. (Fonte: Exchange Team Blog)
#>

param(
  [Parameter(Mandatory = $false)][string]$UserPrincipalName,
  [Parameter(Mandatory = $false)][string]$ExportCsvPath
)

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$caixas = @()
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\analiseAutoExpsansao_$($inicio.ToString('MMMyy')).txt"

gravaLOG -texto "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))" -tipo WRN -arquivo $logs
gravaLOG -texto "Iniciando a analise de Auto-Expanding Archive no Microsoft 365..." -tipo INF -arquivo $logs

# Validacoes
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema." -arquivoLogs $logs

# Conexoes
try {
  Import-Module ExchangeOnlineManagement -ErrorAction Stop
  Connect-ExchangeOnline -ShowBanner:$false
}
catch {
  gravaLOG "$((Get-Date).ToString('HH:mm:ss')) - ao conectar ao Exchange Online: $($_.Exception.Message)" -tipo ERR -arquivo $logs
  break
}

function Get-ExchangeMailboxAudit {
  param([string]$Identity)

  # Objeto base
  $result = [ordered]@{
    UPN                                = $Identity
    DisplayName                        = $null
    PrimaryMailboxSize_GB              = $null
    PrimaryProhibitSendReceiveQuota_GB = $null
    PrimaryWarningQuota_GB             = $null

    ArchiveEnabled                     = $false
    AutoExpandingArchiveEnabled        = $false
    ArchiveMailboxSize_GB              = $null
    ArchiveProhibitSendReceiveQuota_GB = $null
    ArchiveWarningQuota_GB             = $null
    ArchiveRecoverableItemsSize_GB     = $null

    ExpansionThresholdReached          = $false
    NearExpansionThreshold             = $false
    ExpansionThreshold_GB              = 90
    Notes                              = $null
    LastMRMRun                         = $null
    LastProcessedByMFA                 = $null
  }

  # Get mailbox with archive properties
  $mbx = Get-Mailbox -Identity $Identity -ErrorAction SilentlyContinue

  if (-not $mbx) {
    gravaLOG "Caixa Postal não encontrada: $Identity" -tipo INF -arquivo $logs
    return $null
  }

  $result.DisplayName = $mbx.DisplayName

  # Quotas primárias
  if ($mbx.ProhibitSendReceiveQuota.Value) {
    $bytes = [long]([regex]::Match($mbx.ProhibitSendReceiveQuota.Value.ToString(), '\((\d+)').Groups[1].Value)
    $result.PrimaryProhibitSendReceiveQuota_GB = [math]::Round(($bytes / 1GB), 2)
  }
  if ($mbx.IssueWarningQuota.Value) {
    $bytes = [long]([regex]::Match($mbx.IssueWarningQuota.Value.ToString(), '\((\d+)').Groups[1].Value)
    $result.PrimaryWarningQuota_GB = [math]::Round(($bytes / 1GB), 2)
  }

  # Estatísticas primárias
  $primaryStats = Get-MailboxStatistics -Identity $Identity -ErrorAction SilentlyContinue
  if ($primaryStats -and $primaryStats.TotalItemSize.Value) {
    $bytes = [long]([regex]::Match($primaryStats.TotalItemSize.Value.ToString(), '\((\d+)').Groups[1].Value)
    $result.PrimaryMailboxSize_GB = [math]::Round(($bytes / 1GB), 2)
  }

  # Propriedades de Arquivo/Auto-Expanding
  # Observação: a propriedade pode aparecer como AutoExpandingArchive/AutoExpandingArchiveEnabled conforme versão do módulo.
  $autoExpProp = $mbx | Select-Object -ExpandProperty AutoExpandingArchive -ErrorAction SilentlyContinue
  if ($null -eq $autoExpProp) {
    # Tentativa alternativa de leitura (algumas builds)
    $autoExpProp = ($mbx | Select-Object -Property * | Select-Object -ExpandProperty AutoExpandingArchiveEnabled -ErrorAction SilentlyContinue)
  }
  $result.AutoExpandingArchiveEnabled = [bool]$autoExpProp

  # Arquivo habilitado?
  if ($mbx.ArchiveStatus -eq 'Active') {
    $result.ArchiveEnabled = $true

    # Quotas do arquivo
    if ($mbx.ArchiveQuota.Value) {
      # $bytes = [long]([regex]::Match($mbx.ArchiveQuota.Value.ToString(), '\((\d+)').Groups[1].Value)
      # $result.ArchiveProhibitSendReceiveQuota_GB = [math]::Round(($bytes / 1GB),2)
      $result.ArchiveProhibitSendReceiveQuota_GB = $mbx.ArchiveQuota.Value
    }
    if ($mbx.ArchiveWarningQuota.Value) {
      # $bytes = [long]([regex]::Match($mbx.ArchiveWarningQuota.Value.ToString(), '\((\d+)').Groups[1].Value)
      # $result.ArchiveWarningQuota_GB = [math]::Round(($bytes / 1GB),2)
      $result.ArchiveWarningQuota_GB = $mbx.ArchiveWarningQuota.Value
    }

    # Estatísticas do arquivo
    $archiveStats = Get-MailboxStatistics -Identity $Identity -Archive -ErrorAction SilentlyContinue
    if ($archiveStats -and $archiveStats.TotalItemSize.Value) {
      $bytes = [long]([regex]::Match($archiveStats.TotalItemSize.Value.ToString(), '\((\d+)').Groups[1].Value)
      $result.ArchiveMailboxSize_GB = [math]::Round(($bytes / 1GB), 2)
      # Recoverable Items no arquivo
      try {
        $ri = Get-MailboxFolderStatistics -Identity $Identity -Archive -FolderScope RecoverableItems -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq 'Recoverable Items' }
        if ($ri) {
          $result.ArchiveRecoverableItemsSize_GB = [math]::Round(($ri.FolderAndSubfolderSize / 1GB), 2)
        }
      }
      catch {}
    }

    # Limiar de expansão (90 GB) – flags
    if ($result.ArchiveMailboxSize_GB -ge 90) {
      $result.ExpansionThresholdReached = $true
    }
    elseif ($result.ArchiveMailboxSize_GB -ge 80) {
      $result.NearExpansionThreshold = $true
    } # aviso preventivo

    # Logs do MRM (Managed Folder Assistant) – útil para saber se a política está movendo itens e se a expansão já foi processada
    try {
      $diag = Export-MailboxDiagnosticLogs -Identity $Identity -ComponentName MRM -Archive -ErrorAction SilentlyContinue | 
      Select-Object -ExpandProperty EventLogs -ErrorAction SilentlyContinue
      if ($diag) {
        # Extrai algumas pistas úteis
        $mfa = ($diag | Select-String -Pattern 'Start.*Assistant|End.*Assistant|Processed' -SimpleMatch).Line
        $result.LastMRMRun = ($mfa | Select-Object -Last 1)
        # Alguns tenants exibem carimbo tipo "LastProcessedTime" no blob JSON
        $json = (Export-MailboxDiagnosticLogs -Identity $Identity -ComponentName MRM -Archive -ErrorAction SilentlyContinue).MailboxLog
        if ($json) {
          $obj = $null
          try {
            $obj = $json | ConvertFrom-Json -ErrorAction Stop
          }
          catch {}
          if ($obj -and $obj.MRMAssistant) {
            $result.LastProcessedByMFA = $obj.MRMAssistant.LastEndTime
          }
        }
      }
    }
    catch {
      # Silencia erros de parsing; informação é opcional
    }
  }
  else {
    $result.Notes = "Arquivo Online não habilitado."
  }

  # Observação para contexto operacional
  if ($result.ExpansionThresholdReached -and -not $result.AutoExpandingArchiveEnabled) {
    $result.Notes = ($result.Notes + " Arquivo ≥90 GB, porém Auto-Expanding desabilitado; considere habilitar.").Trim()
  }

  return [pscustomobject]$result
}

gravaLOG "Buscando caixas postais..." -tipo INF -arquivo $logs

if ($UserPrincipalName) {
  $caixas = @($UserPrincipalName)
}
else {
  # Todos usuários com caixa (exclui recursos/shared se desejar ajustar o filtro)
  $caixas = (Get-Mailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited | Select-Object -ExpandProperty UserPrincipalName)
}

gravaLOG "Buscando informacoes de Archive e Auto-Expanding Archive para $($caixas.Count) caixas postais..." -tipo INF -arquivo $logs
$report = foreach ($caixa in $caixas) {
  Get-ExchangeMailboxAudit -Identity $caixa
}

# Exibição
$report | Sort-Object -Property ArchiveMailboxSize_GB -Descending | Format-Table -AutoSize

if ($ExportCsvPath) {
  $report | Export-Csv -Path $ExportCsvPath -NoTypeInformation -Encoding UTF8
  gravaLOG "Relatório exportado para: $ExportCsvPath" -tipo INF -arquivo $logs -mostraTempo $true
}

# Dicas de ação
Write-Host "`nDicas:"
Write-Host " - Para habilitar Auto-Expanding Archive em um usuário: Enable-Mailbox -Identity <UPN> -AutoExpandingArchive"
Write-Host " - A expansão é acionada ao atingir ~90 GB no arquivo e pode levar até 30 dias para provisionar."
Write-Host " - Cada shard do arquivo tem ~100 GB de quota; o total pode chegar a ~1,5 TB."

$final = Get-Date
gravaLOG "Tempo de duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())" -tipo WRN -arquivo $logs -mostraTempo $true