<#
.SYNOPSIS
Inventário de mailboxes (alto desempenho) para Windows PowerShell 5.1
Usa Graph Reports (rápido) e cai para EXO statistics (lento) quando necessário.

.DESCRIPTION
- EXO (Get-EXOMailbox): tipo, encaminhamento, litígio, criação, status de arquivamento (REST V3).
- Graph Users (Get-MgUser): identidade (manager opcional), status da conta, sync AD, políticas de senha, licenças.
- Graph Reports (Get-MgReportMailboxUsageDetail): usado (GB), último uso, arquivamento (Sim/GB) — 1 CSV para todas as caixas.
-> Fallback automático para Get-EXOMailboxStatistics somente se Reports indisponível.

.NOTES
  - Requer PowerShell 5.1
  - Get-EXOMailbox (EXO V3 REST): https://learn.microsoft.com/powershell/module/exchangepowershell/get-exomailbox
  - Instalação do Microsoft Graph SDK (PS 5.1): https://learn.microsoft.com/powershell/microsoftgraph/installation
  - PSModulePath (diferenças PS 5.1 vs 7): https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_psmodulepath
  - Relatório de uso de mailboxes (Graph Reports): https://learn.microsoft.com/powershell/module/microsoft.graph.reports/get-mgreportmailboxusagedetail
#>

param(
  [string]$OutputPath = ".\Mailboxes-Inventory.csv",
  [ValidateSet('D7','D30','D90','D180')]
  [string]$UsagePeriod = 'D180',
  [switch]$SkipManager,
  [ValidateSet('PrimarySmtpAddress','SamAccountName','UPN')]
  [string]$ContaField = 'PrimarySmtpAddress',
  [switch]$ForceExoStats  # força o caminho lento (útil para troubleshooting)
)

#===============================================================================
# 0) Sessao e utilitarios
#===============================================================================

# TLS 1.2 e ExecutionPolicy (PS 5.1)
try {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
try {
  if ((Get-ExecutionPolicy -Scope CurrentUser) -ne 'RemoteSigned'){
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
  }
} catch {}


function Convert-BytesToGB {
  param([Nullable[Int64]]$Bytes)
  if (-not $Bytes){ return 0 }
  [math]::Round($Bytes / 1GB, 2)
}


function Test-PolicyFlag {
  param(
    [string]$Policies,
    [string]$Flag
  )
  if ([string]::IsNullOrWhiteSpace($Policies)){ return $false }
  return ($Policies -split '\s*,\s*') -contains $Flag
}


function ajustaHeader { 
  param([string]$name)
  return ($name -replace '[^A-Za-z0-9]', '')
}


function Get-DisplayLicenseNames {
  param(
    $SkuDisplayMap,
    [Guid[]]$AssignedSkuIds
  )
  if (-not $AssignedSkuIds -or $AssignedSkuIds.Count -eq 0){ return "" }
  $names = foreach ($id in $AssignedSkuIds){
    if ($SkuDisplayMap.ContainsKey($id)){
      $SkuDisplayMap[$id]
    } else {
      $id.Guid
    }
  }
  ($names | Sort-Object -Unique) -join '+ '
}


function Get-ContaValue {
  param($caixa,$aad,[string]$ContaField)
  switch ($ContaField){
    'PrimarySmtpAddress' { return $caixa.PrimarySmtpAddress }
    'SamAccountName' {
      if ($aad -and $aad.onPremisesSamAccountName){
        return $aad.onPremisesSamAccountName
      } elseif ($caixa.Alias){
        return $caixa.Alias
      } else {
        return $caixa.PrimarySmtpAddress.Split('@')[0]
      }
    }
    'UPN' {
      if ($aad -and $aad.userPrincipalName){
        return $aad.userPrincipalName
      } else {
        return $caixa.UserPrincipalName
      }
    }
  }
}

#===============================================================================
# 1) Bootstrap: NuGet provider + Graph SDK (PS 5.1)
#===============================================================================
Write-Host "Preparando ambiente (NuGet/Graph)..." -ForegroundColor Cyan
try {
  Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
} catch { Write-Verbose "NuGet provider ja presente ou instalacao nao necessaria." }

# Caminho de módulos do PS 5.1
$myDocs = [Environment]::GetFolderPath('MyDocuments')  # pode estar no OneDrive
$ps51UserModules = Join-Path $myDocs 'WindowsPowerShell\Modules'

function Ensure-Module {
  param([string]$Name)
  if (-not (Get-Module -ListAvailable -Name $Name)){
    try {
      Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
      Install-Module $Name -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
    } catch {
      Write-Warning "Falha ao Install-Module $Name. Tentando Save-Module para $ps51UserModules..."
      New-Item -Path $ps51UserModules -ItemType Directory -Force | Out-Null
      Save-Module -Name $Name -Path $ps51UserModules -Force
    }
  }
  Import-Module $Name -Force -ErrorAction Stop
}

$GraphAuthOK = $false
$GraphReportsOK = $false
try {
  Ensure-Module -Name 'Microsoft.Graph.Authentication'
  $GraphAuthOK = $true
} catch {
  Write-Warning "Microsoft.Graph.Authentication indisponível: $($_.Exception.Message)"
} try {
  Ensure-Module -Name 'Microsoft.Graph.Reports'
  $GraphReportsOK = $true
} catch {
  Write-Warning "Microsoft.Graph.Reports indisponível: $($_.Exception.Message)"
}

#===============================================================================
# 2) Conexões (EXO e Graph)
#===============================================================================
Write-Host "Conectando ao Exchange Online (EXO V3)..." -ForegroundColor Cyan
Connect-ExchangeOnline -ShowBanner:$false

$graphScopes = @('User.Read.All','Directory.Read.All','AuditLog.Read.All')
if ($GraphReportsOK -and -not $ForceExoStats){
  $graphScopes += 'Reports.Read.All'
}

if ($GraphAuthOK){
  Write-Host "Conectando ao Microsoft Graph (escopos: $($graphScopes -join ', '))..." -ForegroundColor Cyan
  try {
    Connect-MgGraph -Scopes $graphScopes | Out-Null; Select-MgProfile -Name 'v1.0'
  } catch {
    Write-Warning "Falha ao conectar no Graph: $($_.Exception.Message)"
  }
} else {
  Write-Warning "Graph Authentication indisponível. Somente dados do EXO serão coletados."
}

#===============================================================================
# 3) SKUs => nomes amigáveis (se Graph disponível)
#===============================================================================
$skuDisplayMap = New-Object 'System.Collections.Generic.Dictionary[Guid,string]'
if ($GraphAuthOK){
  Write-Host "Carregando SKUs do tenant (licenças)..." -ForegroundColor Cyan
  try {
    $subscribedSkus = Get-MgSubscribedSku
    foreach ($sku in $subscribedSkus){
      $display = $null
      if ($sku.AdditionalProperties.ContainsKey('skuDisplayName')){ $display = $sku.AdditionalProperties['skuDisplayName'] }
      if (-not $display){ $display = $sku.SkuPartNumber }
      $skuDisplayMap[$sku.SkuId] = $display
    }
  } catch { Write-Warning "Falha ao carregar SKUs: $($_.Exception.Message)" }
}

#===============================================================================
# 4) Mailboxes (EXO) => propriedades essenciais
#===============================================================================
Write-Host "Carregando mailboxes (EXO)..." -ForegroundColor Cyan
$exoProps = @(
  'DisplayName','UserPrincipalName','ExternalDirectoryObjectId','PrimarySmtpAddress','Alias',
  'RecipientTypeDetails','ForwardingSmtpAddress','ForwardingAddress','DeliverToMailboxAndForward',
  'LitigationHoldEnabled','WhenMailboxCreated'
)
$caixasPostais = Get-EXOMailbox `
  -ResultSize Unlimited `
  -Properties $exoProps `
  -PropertySets Archive `
  -RecipientTypeDetails UserMailbox,SharedMailbox,RoomMailbox,EquipmentMailbox

Write-Host ("Total EXO: {0}" -f $caixasPostais.Count) -ForegroundColor Green

# Indexaçao auxiliar
$caixaByObj = @{}
$caixaByUpn = @{}
foreach ($m in $caixasPostais){
  if ($m.ExternalDirectoryObjectId){ $caixaByObj[$m.ExternalDirectoryObjectId] = $m }
  if ($m.UserPrincipalName){ $caixaByUpn[$m.UserPrincipalName.ToLower()] = $m }
}

#===============================================================================
# 5) Users (Graph) => identidade minima (+manager opcional)
#===============================================================================
$aadById = @{}; $aadByUpn = @{}
if ($GraphAuthOK){
  Write-Host "Carregando usuarios (Graph)..." -ForegroundColor Cyan
  $baseProps = @(
    'id','displayName','userPrincipalName',
    'city','state','companyName','officeLocation','department','jobTitle',
    'accountEnabled','createdDateTime',
    'onPremisesSyncEnabled','onPremisesLastSyncDateTime','onPremisesSamAccountName',
    'passwordPolicies','signInActivity','assignedLicenses'
  )
  try {
    if ($SkipManager){
      $mgUsers = Get-MgUser -All -ConsistencyLevel eventual -Property ($baseProps -join ',')
    } else {
      $mgUsers = Get-MgUser -All -ConsistencyLevel eventual -Property ($baseProps -join ',') -ExpandProperty manager
    }
    foreach ($u in $mgUsers){
      $aadById[$u.Id] = $u
      if ($u.UserPrincipalName){ $aadByUpn[$u.UserPrincipalName.ToLower()] = $u }
    }
  } catch {
    Write-Warning "Falha ao carregar usuários do Graph: $($_.Exception.Message)"
  }
}

#===============================================================================
# 6) Reports (Graph) => uso de mailboxes (rapido) OU fallback p/ EXO stats (lento)
#===============================================================================
$useGraphReport = ($GraphReportsOK -and -not $ForceExoStats)
$usageRows = @{}
if ($useGraphReport){
  Write-Host "Baixando relatorio de uso do Exchange (Graph Reports: $UsagePeriod)..." -ForegroundColor Cyan
  $tempCsv = Join-Path $env:TEMP ("mailbox-usage-{0}.csv" -f $UsagePeriod)
  try {
    Get-MgReportMailboxUsageDetail -Period $UsagePeriod -OutFile $tempCsv | Out-Null
    if (-not (Test-Path $tempCsv)){ throw "Arquivo de relatório não encontrado." }
    $raw = Import-Csv -Path $tempCsv

    function ajustaUsageRow51 {
      param($r)
      $map = @{}
      foreach ($p in $r.PSObject.Properties){
        $map[(ajustaHeader $p.Name)] = $p.Value
      }
      $upn  = $null
      foreach ($k in @('UserPrincipalName','Userprincipalname','User')){
        if ($map.ContainsKey($k)){
          $upn = $map[$k]
          break
        }
      }
      if (-not $upn){ $upn = $r.'User Principal Name' }
      $last = $map['LastActivityDate']
      if (-not $last){ $last = $r.'Last Activity Date' }
      $stor = $map['StorageUsedByte']
      if (-not $stor){
        $stor = $map['StorageUsedInBytes']
        if (-not $stor){
          $stor = $r.'Storage Used (Byte)'
        }
      }
      $hasA = $map['HasArchiveMailbox']
      if (-not $hasA){ $hasA = $r.'Has Archive Mailbox' }
      $arch = $map['ArchiveStorageUsedByte']
      if (-not $arch){
        $arch = $map['ArchiveStorageUsedInBytes']
        if (-not $arch){
          $arch = $r.'Archive Storage Used (Byte)'
        }
      }
      [pscustomobject]@{
        UPN = $upn
        LastActivityDate = $last
        StorageBytes = $stor
        HasArchive = $hasA
        ArchiveBytes = $arch
      }
    }

    foreach ($row in $raw){
      $n = ajustaUsageRow51 $row
      if ($n -and $n.UPN){ $usageRows[$n.UPN.ToLower()] = $n }
    }

    if ($usageRows.Keys | Where-Object { $_ -notlike '*@*' } | Select-Object -First 1){
      Write-Warning "Relatorio de uso parece anonimizado (UPN mascarado). Ajuste Admin Center => Reports para exibir nomes."
    }
  } catch {
    Write-Warning "Falha ao obter/ler relatorio do Graph: $($_.Exception.Message). Usando EXO statistics (lento)."
    $useGraphReport = $false
  }
}

#===============================================================================
# Fallback: EXO statistics (lento)
#===============================================================================
$statsByIdentity = @{}
$archiveBytesByIdentity = @{}
if (-not $useGraphReport){
  Write-Host "Coletando EXO statistics por mailbox (isso pode demorar)..." -ForegroundColor Yellow
  $i = 0; $total = $mailboxes.Count
  foreach ($mb in $mailboxes){
    $i++; Write-Progress -Activity "Get-EXOMailboxStatistics" -Status "$i / $total : $($mb.PrimarySmtpAddress)" -PercentComplete (($i/$total)*100)
    try {
      $s = Get-EXOMailboxStatistics -Identity $mb.Identity -ErrorAction SilentlyContinue
      if ($s){
        $sizeBytes = $null
        if ($s.PSObject.Properties.Name -contains 'TotalItemSizeInBytes' -and $s.TotalItemSizeInBytes) { $sizeBytes = [Int64]$s.TotalItemSizeInBytes }
        $statsByIdentity[$mb.Identity] = [pscustomobject]@{ LastLogonTime = $s.LastLogonTime; SizeBytes = $sizeBytes }
      }
      # Apenas se houver arquivo ativo, coleta tamanho do arquivo
      $hasArchive = ($mb.ArchiveStatus -in @('Active','HostedPending','ActiveHosted')) -or ($mb.ArchiveGuid)
      if ($hasArchive){
        $sa = Get-EXOMailboxStatistics -Identity $mb.Identity -Archive -ErrorAction SilentlyContinue
        if ($sa){
          $aBytes = $null
          if (
            $sa.PSObject.Properties.Name -contains 'TotalItemSizeInBytes' -and
            $sa.TotalItemSizeInBytes
          ){
            $aBytes = [Int64]$sa.TotalItemSizeInBytes
          }
          $archiveBytesByIdentity[$mb.Identity] = $aBytes
        }
      }
    } catch { }
  }
  Write-Progress -Activity "Get-EXOMailboxStatistics" -Completed
}

#===============================================================================
# 7) Montagem do resultado
#===============================================================================
Write-Host "Construindo resultado final..." -ForegroundColor Cyan

$result = foreach ($caixa in $caixasPostais){
  # Match de usuario AAD
  $aad = $null
  if (
    $caixa.ExternalDirectoryObjectId -and
    $aadById.ContainsKey($caixa.ExternalDirectoryObjectId)
  ){
    $aad = $aadById[$caixa.ExternalDirectoryObjectId]
  } elseif (
    $caixa.UserPrincipalName -and
    $aadByUpn.ContainsKey($caixa.UserPrincipalName.ToLower())
  ){
    $aad = $aadByUpn[$caixa.UserPrincipalName.ToLower()]
  }

  # Linha do report (quando usamos Graph)
  $uRow = $null
  if ($useGraphReport -and $caixa.UserPrincipalName){
    $key = $caixa.UserPrincipalName.ToLower()
    if ($usageRows.ContainsKey($key)){ $uRow = $usageRows[$key] }
  }

  # Identidade (preferir Graph)
  $city = if ($aad){ $aad.city } else { $null }
  $state = if ($aad){ $aad.state } else { $null }
  $company = if ($aad){ $aad.companyName } else { $null }
  $office = if ($aad){ $aad.officeLocation } else { $null }
  $dept = if ($aad){ $aad.department } else { $null }
  $title = if ($aad){ $aad.jobTitle } else { $null }
  $accEnabled = if ($aad){ $aad.accountEnabled } else { $null }
  $syncEnabled = if ($aad){ $aad.onPremisesSyncEnabled } else { $null }
  $pwdPolicies = if ($aad){ $aad.passwordPolicies } else { $null }

  # Gerente (se nao pulado)
  $managerName = ""
  if (-not $SkipManager -and $aad){
    try {
      $mgr = $aad.AdditionalProperties['manager']
      if ($mgr){
        if ($mgr.displayName){
          $managerName = $mgr.displayName
        } elseif ($mgr.userPrincipalName){
          $managerName = $mgr.userPrincipalName
        }
      }
    } catch {}
  }

  # Licencas
  $assignedSkuIds = @()
  try {
    if ($aad -and $aad.AdditionalProperties.ContainsKey('assignedLicenses')){
      $assigned = $aad.AdditionalProperties['assignedLicenses']
      if ($assigned){
        foreach ($al in $assigned){ $assignedSkuIds += [Guid]$al.skuId }
      }
    }
  } catch {}
  $licencas = Get-DisplayLicenseNames -SkuDisplayMap $skuDisplayMap -AssignedSkuIds $assignedSkuIds

  # Labels
  $statusLabel = if ($accEnabled -eq $true){ 'Ativa' } else { 'Bloqueada' }
  $syncLabel = if ($syncEnabled){ 'Sim' } else { 'Nao' }
  $strongPwd = if (Test-PolicyFlag $pwdPolicies 'DisableStrongPassword'){ 'Nao' } else { 'Sim' }
  $pwdNeverExp = if (Test-PolicyFlag $pwdPolicies 'DisablePasswordExpiration'){ 'Sim' } else { 'Nao' }
  $isShared = ($caixa.RecipientTypeDetails -eq 'SharedMailbox')
  $isSharedLbl = if ($isShared){ 'Sim' } else { 'Nao' }
  $isFwd = ($caixa.ForwardingSmtpAddress -or $caixa.ForwardingAddress -or $caixa.DeliverToMailboxAndForward)
  $isFwdLbl = if ($isFwd){ 'Sim' } else { 'Nao' }

  # Arquivo via report (preferência) ou EXO status + EXO tamanho (fallback)
  $hasArchive = $false
  $archiveGB = 0
  if ($uRow){
    $hasArchive = ($uRow.HasArchive -eq $true -or $uRow.HasArchive -eq 'True')
    $archiveGB = Convert-BytesToGB $uRow.ArchiveBytes
  } else {
    $hasArchive = ($caixa.ArchiveStatus -in @('Active','HostedPending','ActiveHosted')) -or ($caixa.ArchiveGuid)
    if (-not $useGraphReport -and $archiveBytesByIdentity.ContainsKey($mbx.Identity)){
      $archiveGB = Convert-BytesToGB $archiveBytesByIdentity[$mbx.Identity]
    }
  }
  $archiveLbl = if ($hasArchive){ 'Sim' } else { 'Nao' }

  # Uso e ultimo acesso
  $usedGB = 0
  $lastAccess = $null
  if ($uRow){
    $usedGB = Convert-BytesToGB $uRow.StorageBytes
    $lastAccess = $uRow.LastActivityDate
  } elseif (
    -not $useGraphReport -and
    $statsByIdentity.ContainsKey($mbx.Identity)
  ){
    $usedGB = Convert-BytesToGB $statsByIdentity[$caixa.Identity].SizeBytes
    $lastAccess = $statsByIdentity[$mbx.Identity].LastLogonTime
  }

  # Conta e UPN
  $conta = Get-ContaValue -mbx $caixa -aad $aad -ContaField $ContaField
  $upnOut = Get-ContaValue -mbx $caixa -aad $aad -ContaField 'UPN'

  [pscustomobject]@{
    'Nome' = $caixa.DisplayName
    'UPN' = $upnOut
    'Cidade' = $city
    'UF' = $state
    'Empresa' = $company
    'Escritorio' = $office
    'Departamento' = $dept
    'Cargo' = $title
    'Gerente' = $managerName
    'Tipo' = $caixa.RecipientTypeDetails
    'AD' = $syncLabel
    'Situacao' = $statusLabel
    'senhaForte' = $strongPwd
    'senhaNaoExpira' = $pwdNeverExp
    'Compartilhada' = $isSharedLbl
    'Encaminhada' = $isFwdLbl
    'Litigio' = if ($caixa.LitigationHoldEnabled){ 'Sim' } else { 'Nao' }
    'Usado(GB)' = $usedGB
    'Arquivamento' = $archiveLbl
    'Arquivamento(GB)' = $archiveGB
    'Criacao' = $caixa.WhenMailboxCreated
    'mudancaSenha' = if ($aad){ $aad.signInActivity.lastPasswordChangeDateTime } else { $null }
    'ultimoSyncAD' = if ($aad){ $aad.onPremisesLastSyncDateTime } else { $null }
    'ultimoAcesso' = $lastAccess
    'Conta' = $conta
    'objectId' = $caixa.ExternalDirectoryObjectId
    'Licencas' = $licencas
  }
}

#===============================================================================
# 8) Export
#===============================================================================
$result | Sort-Object Nome | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Inventario gerado: $OutputPath" -ForegroundColor Green

Disconnect-ExchangeOnline -Confirm:$false
Disconnect-MgGraph