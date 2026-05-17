<#
  .SYNOPSIS
    Auditoria offline de GPOs aplicadas a usuários e OUs no AD DS.
  .DESCRIPTION
    Varre os usuários do Active Directory, agrupa por OU/Container, analisa os links de GPOs efetivos e heranças (com suporte a fallback automático para o container CN=Users), aplicando regras heurísticas de permissões e WMI para gerar um relatório analítico "tech-style" em HTML.
  .AUTHOR
    Felipe Aquino
  .CREATED
    05/04/26
  .VERSION
    02 (17/05/26) - Jouderian Nobre: remoção de parâmetros RSoP inoperantes, padronização camelCase, refatoração de performance e incorporação de logs persistentes autônomos.
  .OUTPUT
    Relatório HTML (GPO_Audit_Report.html) e arquivo de log de execução (.log) na mesma pasta do script.
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [string]$searchBase,

  [Parameter(Mandatory = $false)]
  [switch]$includeUsersSample,

  [Parameter(Mandatory = $false)]
  [ValidateRange(1, 200)][int]$usersSampleSize = 10,

  [Parameter(Mandatory = $false)]
  [string]$logPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = if ($PSScriptRoot){ $PSScriptRoot } else { (Get-Location).Path }

if (-not $logPath){
  $logPath = Join-Path $scriptRoot "validaGPOs_execution.log"
}
$script:logExecutionPath = $logPath

# ---------------- Console & Log helpers ----------------
function Grava-LogLocal {
  param(
    [Parameter(Mandatory = $true)][string]$texto,
    [ValidateSet('INF', 'OK', 'WRN', 'ERR', 'STP')][string]$tipo = 'INF'
  )

  $prefixo = @{
    INF = '[INFO ] ';
    OK  = '[OK   ] ';
    WRN = '[AVISO] ';
    ERR = '[ERRO ] ';
    STP = '[PASSO] '
  }[$tipo]

  $color = @{
    INF = 'Cyan';
    OK  = 'Green';
    WRN = 'Yellow';
    ERR = 'Red';
    STP = 'Magenta'
  }[$tipo]

  if (-not $color){ $color = 'White' }

  $mensagem = "$prefixo$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) $texto"

  Write-Host $mensagem -ForegroundColor $color
  if ($script:logExecutionPath){
    try {
      Add-Content -Path $script:logExecutionPath -Value $mensagem -Encoding UTF8
    } catch {
      Write-Host "Falha ao gravar no arquivo de log: $($_.Exception.Message)" -ForegroundColor Red
    }
  }
}

function Verifica-ModuloLocal {
  param([Parameter(Mandatory = $true)][string]$nomeModulo)

  $modulo = Get-Module -Name $nomeModulo -ListAvailable
  if (-not $modulo){
    Grava-LogLocal -texto "Módulo '$nomeModulo' não encontrado localmente." -tipo ERR
    $confirm = Read-Host "O módulo '$nomeModulo' (RSAT) é obrigatório. Deseja tentar instalá-lo da PSGallery agora? [S]im ou [N]ão"
    if ($confirm -match '^[sS]'){
      Grava-LogLocal -texto "Instalando o módulo '$nomeModulo' na sessão atual..." -tipo STP
      try {
        Install-Module -Name $nomeModulo -Repository PSGallery -AllowClobber -Scope CurrentUser -Force
        Grava-LogLocal -texto "Módulo '$nomeModulo' instalado com sucesso." -tipo OK
      } catch {
        Grava-LogLocal -texto "Falha ao instalar módulo '$nomeModulo': $($_.Exception.Message). Instale o RSAT e tente novamente." -tipo ERR
        Exit 1
      }
    } else {
      Grava-LogLocal -texto "Execução abortada devido à falta do módulo '$nomeModulo'." -tipo ERR
      Exit 1
    }
  }
  Import-Module $nomeModulo -ErrorAction Stop
}

# ---------------- Helpers robustos ----------------
function Count-Items { param($value) return @($value).Count }

function Get-PropValue {
  param(
    [Parameter(Mandatory = $true)]
    $obj,
    [string[]]$names,
    $default = $null
  )
  foreach ($n in $names){
    if ($null -ne $obj -and $obj.PSObject.Properties.Match($n).Count -gt 0){
      return $obj.$n
    }
  }
  return $default
}

function Convert-ToGuidLoose {
  param([Parameter(Mandatory = $true)]$value)

  if ($null -eq $value){ return $null }
  if ($value -is [Guid]){ return $value }

  $s = "$value".Trim()
  if (-not $s){ return $null }

  try { return [Guid]$s } catch { }

  $m = [regex]::Match($s, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')
  if ($m.Success){
    try { return [Guid]$m.Value } catch { return $null }
  }

  return $null
}

function Html-Encode([string]$s){
  if ($null -eq $s){ return "" }
  return [System.Net.WebUtility]::HtmlEncode($s)
}

function Get-OuDnFromUserDn {
  param([Parameter(Mandatory = $true)][string]$userDn)
  return ($userDn -replace '^[^,]+,', '')
}

function Is-CnUsersContainer {
  param([Parameter(Mandatory = $true)][string]$dn)
  return ($dn -match '^CN=Users,')
}

# ---------------- GPO permissions summary ----------------
function Get-ApplyPrincipalsSummary {
  param([Parameter(Mandatory = $true)][Guid]$gpoId)
  $broadPrincipals = @("Authenticated Users", "Domain Users", "Everyone")

  try { $perms = Get-GPPermission -Guid $gpoId -All -ErrorAction Stop }
  catch {
    return [pscustomobject]@{
      CanRead = $false; BroadApply = $false; BroadApplyWho = @(); DenyApplyWho = @();
      RawNote = "Falha ao ler permissões: $($_.Exception.Message)"
    }
  }

  $apply = $perms | Where-Object { $_.Permission -match "GpoApply" }
  $deny = $perms | Where-Object { $_.Permission -match "GpoDeny" }

  $broadApplyWho = @(
    $apply | Where-Object { $broadPrincipals -contains $_.Trustee.Name } |
    Select-Object -ExpandProperty Trustee | ForEach-Object { $_.Name }
  ) | Sort-Object -Unique

  $denyApplyWho = @(
    $deny | Select-Object -ExpandProperty Trustee | ForEach-Object { $_.Name }
  ) | Sort-Object -Unique

  [pscustomobject]@{
    CanRead       = $true
    BroadApply    = (Count-Items $broadApplyWho) -gt 0
    BroadApplyWho = $broadApplyWho
    DenyApplyWho  = $denyApplyWho
    RawNote       = ""
  }
}

function Get-GpoFacts {
  param([Parameter(Mandatory = $true)][Guid]$gpoId)
  $gpo = Get-GPO -Guid $gpoId -ErrorAction Stop

  $userEnabled = $true
  switch ($gpo.GpoStatus){
    "AllSettingsDisabled"  { $userEnabled = $false }
    "UserSettingsDisabled" { $userEnabled = $false }
    default                { $userEnabled = $true }
  }

  $wmiName = $null
  try { $wmiName = $gpo.WmiFilter } catch { }

  $permInfo = Get-ApplyPrincipalsSummary -gpoId $gpo.Id

  [pscustomobject]@{
    Id                  = $gpo.Id
    DisplayName         = $gpo.DisplayName
    Owner               = $gpo.Owner
    DomainName          = $gpo.DomainName
    CreationTime        = $gpo.CreationTime
    ModificationTime    = $gpo.ModificationTime
    GpoStatus           = $gpo.GpoStatus
    UserSettingsEnabled = $userEnabled
    WmiFilter           = $wmiName
    PermCanRead         = $permInfo.CanRead
    BroadApply          = $permInfo.BroadApply
    BroadApplyWho       = $permInfo.BroadApplyWho
    DenyApplyWho        = $permInfo.DenyApplyWho
    PermNote            = $permInfo.RawNote
  }
}

# ---------------- GP Inheritance (robusto) ----------------
function Get-EffectiveGpLinksForTarget {
  param(
    [Parameter(Mandatory = $true)]
    [string]$targetDn,
    [string]$labelOuDn
  )

  $inh = Get-GPInheritance -Target $targetDn -ErrorAction Stop

  $block = [bool](Get-PropValue -Obj $inh -Names @(
      "BlockInheritance", "InheritanceBlocked", "IsInheritanceBlocked", "GpoInheritanceBlocked"
    ) -Default $false)

  $direct = @(Get-PropValue -Obj $inh -Names @("GpoLinks", "GPOLinks") -Default @())
  $inherited = @(Get-PropValue -Obj $inh -Names @("InheritedGpoLinks", "InheritedGPOLinks") -Default @())

  $links = @()

  foreach ($l in $direct){
    $links += [pscustomobject]@{
      Scope       = "Direct"
      DisplayName = (Get-PropValue $l @("DisplayName", "Name") "")
      GpoId       = (Get-PropValue $l @("GpoId", "Id", "Guid") $null)
      Enabled     = [bool](Get-PropValue $l @("Enabled") $true)
      Enforced    = [bool](Get-PropValue $l @("Enforced") $false)
      Order       = [int](Get-PropValue $l @("Order", "Precedence") 0)
      SomPath     = $labelOuDn
    }
  }

  foreach ($l in $inherited){
    $som = Get-PropValue $l @("SomPath", "SOMPath", "Som", "SOM", "SomName", "SOMName") ""
    if (-not $som){ $som = "<Inherited>" }

    $links += [pscustomobject]@{
      Scope       = "Inherited"
      DisplayName = (Get-PropValue $l @("DisplayName", "Name") "")
      GpoId       = (Get-PropValue $l @("GpoId", "Id", "Guid") $null)
      Enabled     = [bool](Get-PropValue $l @("Enabled") $true)
      Enforced    = [bool](Get-PropValue $l @("Enforced") $false)
      Order       = [int](Get-PropValue $l @("Order", "Precedence") 0)
      SomPath     = $som
    }
  }

  [pscustomobject]@{
    OuDn             = $labelOuDn
    BlockInheritance = $block
    Links            = ($links | Sort-Object Scope, Order)
  }
}

function Get-EffectiveGpLinksForOu {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ouOrContainerDn,
    [string]$domainDn
  )
  if (Is-CnUsersContainer -Dn $ouOrContainerDn){
    return Get-EffectiveGpLinksForTarget -TargetDn $domainDn -LabelOuDn $ouOrContainerDn
  }
  return Get-EffectiveGpLinksForTarget -TargetDn $ouOrContainerDn -LabelOuDn $ouOrContainerDn
}

function New-Badge($text, $kind){ "<span class='badge badge-$kind'>$(Html-Encode $text)</span>" }
function New-ScorePill($score){
  $s = [int]$score
  $kind = "warn"
  if ($s -ge 85) { $kind = "ok" } elseif ($s -ge 60) { $kind = "info" }
  "<span class='pill pill-$kind'>$s%</span>"
}

# -------------------- MAIN --------------------
try {
  $nowExecution = Get-Date
  Grava-LogLocal -texto "================ Início da Auditoria de GPOs ================" -tipo STP
  Grava-LogLocal -texto "Executado por: $env:USERNAME" -tipo INF
  Grava-LogLocal -texto "Arquivo de log: $logPath" -tipo INF

  Verifica-ModuloLocal -nomeModulo "ActiveDirectory"
  Verifica-ModuloLocal -nomeModulo "GroupPolicy"

  $domain = Get-ADDomain
  if (-not $searchBase){ $searchBase = $domain.DistinguishedName }
  $domainDn = $domain.DistinguishedName
  $outputPath = Join-Path $scriptRoot "GPO_Audit_Report.html"

  Grava-LogLocal -texto "Domínio: $($domain.DNSRoot)" -tipo INF
  Grava-LogLocal -texto "SearchBase: $searchBase" -tipo INF
  Grava-LogLocal -texto "HTML de saída: $outputPath" -tipo INF

  Grava-LogLocal -texto "Coletando usuários ativos/inativos no AD DS (consulta leve)..." -tipo INF
  $users = Get-ADUser -Filter * -SearchBase $searchBase -SearchScope Subtree -Properties Enabled
  if (-not $users){
    throw "Nenhum usuário encontrado em '$searchBase'."
  }
  $totalUserCount = Count-Items $users
  Grava-LogLocal -texto "Usuários coletados: $totalUserCount" -tipo OK

  $byOu = $users | Group-Object -Property { Get-OuDnFromUserDn $_.DistinguishedName }
  $totOus = Count-Items $byOu
  Grava-LogLocal -texto "Total de OUs/Containers com usuários detectados: $totOus" -tipo INF

  $ouResults = @()
  $gpoCache = @{}

  Grava-LogLocal -texto "Iniciando a auditoria offline de GPO e heranças..." -tipo STP
  $i = 0

  foreach ($grp in @($byOu)){
    $i++
    $ouDn = $grp.Name
    $ouUserCount = [int]$grp.Count
    $enabledUsers = Count-Items ($grp.Group | Where-Object { $_.Enabled -eq $true })
    $disabledUsers = $ouUserCount - $enabledUsers

    Grava-LogLocal -texto ("[{0}/{1}] Processando OU: {2} (Users: {3})" -f $i, $totOus, $ouDn, $ouUserCount) -tipo INF

    try {
      $inherit = Get-EffectiveGpLinksForOu -ouOrContainerDn $ouDn -domainDn $domainDn
    } catch {
      Grava-LogLocal -texto "  -> Falha ao ler herança/links de GPO: $($_.Exception.Message)" -tipo WRN
      $ouResults += [pscustomobject]@{
        OuDn = $ouDn; UserCount = $ouUserCount; EnabledUsers = $enabledUsers; DisabledUsers = $disabledUsers
        BlockInheritance = $null; InheritanceReadable = $false; InheritanceError = $_.Exception.Message
        Links = @()
        AmostraUsers = ""
      }
      continue
    }

    $linksExpanded = @()

    foreach ($lnk in @($inherit.Links)){
      $gid = Convert-ToGuidLoose -Value $lnk.GpoId

      if (-not $gid){
        $linksExpanded += [pscustomobject]@{
          OuDn                     = $ouDn
          Scope                    = $lnk.Scope
          LinkSomPath              = $lnk.SomPath
          LinkOrder                = $lnk.Order
          LinkEnabled              = $lnk.Enabled
          LinkEnforced             = $lnk.Enforced
          GpoId                    = "INVALID_GUID"
          GpoName                  = ($lnk.DisplayName)
          GpoStatus                = "Unknown"
          UserSettingsEnabled      = $false
          WmiFilter                = $null
          BroadApply               = $false
          BroadApplyWho            = ""
          AppliesAllUsersHeuristic = $false
          Reasons                  = "Link encontrado mas GUID veio inválido (Get-GPInheritance)."
          Score                    = 0
          Modified                 = $null
          PermNote                 = ""
        }
        continue
      }

      if (-not $gpoCache.ContainsKey($gid)){
        try {
          $gpoCache[$gid] = Get-GpoFacts -gpoId $gid
        } catch {
          $gpoCache[$gid] = [pscustomobject]@{
            Id = $gid; DisplayName = $lnk.DisplayName; Owner = ""; DomainName = $domain.DNSRoot;
            CreationTime = $null; ModificationTime = $null; GpoStatus = "Unknown";
            UserSettingsEnabled = $false; WmiFilter = $null; PermCanRead = $false;
            BroadApply = $false; BroadApplyWho = @(); DenyApplyWho = @(); PermNote = "Falha Get-GPO: $($_.Exception.Message)"
          }
        }
      }

      $gf = $gpoCache[$gid]
      $reasons = @()

      if (-not $lnk.Enabled){ $reasons += "Link OFF" }
      if (-not $gf.UserSettingsEnabled){ $reasons += "UserSettings OFF ($($gf.GpoStatus))" }
      if (-not $gf.PermCanRead){ $reasons += "Sem leitura de permissões" }
      elseif (-not $gf.BroadApply){ $reasons += "Apply restrito" }
      if ($gf.WmiFilter){ $reasons += "WMI Filter" }
      if ((Count-Items $gf.DenyApplyWho) -gt 0){ $reasons += ("GpoDeny: " + ($gf.DenyApplyWho -join ", ")) }

      $appliesAllUsers = ($lnk.Enabled -and $gf.UserSettingsEnabled -and $gf.PermCanRead -and $gf.BroadApply)

      $score = 100
      if (-not $lnk.Enabled){ $score -= 35 }
      if (-not $gf.UserSettingsEnabled){ $score -= 35 }
      if ($gf.PermCanRead -and -not $gf.BroadApply){ $score -= 25 }
      if (-not $gf.PermCanRead){ $score -= 20 }
      if ($gf.WmiFilter){ $score -= 10 }
      if ($score -lt 0){ $score = 0 }

      $linksExpanded += [pscustomobject]@{
        OuDn                     = $ouDn
        Scope                    = $lnk.Scope
        LinkSomPath              = $lnk.SomPath
        LinkOrder                = $lnk.Order
        LinkEnabled              = $lnk.Enabled
        LinkEnforced             = $lnk.Enforced
        GpoId                    = $gf.Id
        GpoName                  = $gf.DisplayName
        GpoStatus                = $gf.GpoStatus
        UserSettingsEnabled      = $gf.UserSettingsEnabled
        WmiFilter                = $gf.WmiFilter
        BroadApply               = $gf.BroadApply
        BroadApplyWho            = ($gf.BroadApplyWho -join ", ")
        AppliesAllUsersHeuristic = $appliesAllUsers
        Reasons                  = ($reasons -join " | ")
        Score                    = $score
        Modified                 = $gf.ModificationTime
        PermNote                 = $gf.PermNote
      }
    }

    # Lazy loading de amostra de usuários se includeUsersSample estiver ativo
    $sampleText = ""
    if ($includeUsersSample){
      try {
        $sample = Get-ADUser -Filter * -SearchBase $ouDn -SearchScope OneLevel | Select-Object -First $usersSampleSize | ForEach-Object { $_.SamAccountName }
        if ($sample){
          $sampleText = "<br><span style='color:var(--muted)'>Amostra: " + ($sample -join ", ") + "</span>"
        }
      } catch { }
    }

    $ouResults += [pscustomobject]@{
      OuDn                = $ouDn
      UserCount           = $ouUserCount
      EnabledUsers        = $enabledUsers
      DisabledUsers       = $disabledUsers
      BlockInheritance    = $inherit.BlockInheritance
      InheritanceReadable = $true
      InheritanceError    = ""
      Links               = $linksExpanded
      AmostraUsers        = $sampleText
    }
  }

  Grava-LogLocal -texto "Auditoria offline das OUs concluída." -tipo OK

  $allLinks = @(
    foreach ($o in @($ouResults)){
      foreach ($l in @($o.Links)){
        $l | Add-Member -MemberType NoteProperty -Name "AmostraUsers" -Value $o.AmostraUsers -Force
        $l
      }
    }
  )

  $totalLinks = Count-Items $allLinks
  $okLinks = Count-Items ($allLinks | Where-Object { $_.AppliesAllUsersHeuristic -eq $true })
  $warnLinks = $totalLinks - $okLinks
  if ($warnLinks -lt 0){ $warnLinks = 0 }

  Grava-LogLocal -texto "Resumo offline: Links efetivos=$totalLinks | OK(heurística)=$okLinks | Risco=$warnLinks" -tipo INF

  # -------------------- HTML (tech) --------------------
  $css = @"
    :root{
      --bg:#0b1020;
      --text:#e6ecff;
      --muted:#9fb0e6;
      --ok:#28d17c;
      --warn:#ffcc66;
      --bad:#ff5c7a;
      --info:#66b3ff;
      --line:rgba(255,255,255,.10);
      --glow:rgba(102,179,255,.35);
      --mono:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,"Liberation Mono","Courier New",monospace;
      --sans:ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,Arial
    }
    *{box-sizing:border-box}
    body{
      margin:0;
      background:radial-gradient(1200px 600px at 15% 10%, rgba(102,179,255,.18), transparent 55%),radial-gradient(900px 500px at 85% 20%, rgba(40,209,124,.10), transparent 60%),radial-gradient(900px 700px at 60% 90%, rgba(255,92,122,.10), transparent 55%),var(--bg);
      color:var(--text);font-family:var(--sans)
    }
    .header{
      padding:28px 22px;
      border-bottom:1px solid var(--line);
      background:linear-gradient(180deg, rgba(17,26,51,.85), rgba(11,16,32,.85));
      position:sticky;
      top:0;
      z-index:50;
      backdrop-filter:blur(10px)
    }
    .hrow{
      display:flex;gap:16px;
      align-items:flex-end;
      justify-content:space-between;
      flex-wrap:wrap
    }
    .title{font-size:20px;margin:0;}
    .subtitle{
      margin:6px 0 0 0;
      color:var(--muted);
      font-family:var(--mono);
      font-size:12px
    }
    .container{padding:18px 22px 40px 22px;max-width:1400px;margin:0 auto}
    .grid{
      display:grid;
      grid-template-columns:repeat(12,1fr);
      gap:14px;
      margin-top:14px
    }
    .card{
      grid-column:span 3;
      background:linear-gradient(180deg, rgba(17,26,51,.92), rgba(15,23,48,.92));
      border:1px solid var(--line);
      border-radius:16px;
      padding:14px;
      box-shadow:0 10px 30px rgba(0,0,0,.35);
      position:relative;
      overflow:hidden
    }
    .card:before{
      content:"";
      position:absolute;
      inset:-2px;background:radial-gradient(600px 140px at 20% 0%, var(--glow), transparent 55%);
      opacity:.35;
      pointer-events:none
    }
    .card h3{
      margin:0 0 8px 0;
      font-size:12px;
      color:var(--muted);
      text-transform:uppercase;
      letter-spacing:.8px
    }
    .card .big{font-size:22px;font-weight:700;margin:0}
    .card .note{margin:6px 0 0 0;color:var(--muted);font-family:var(--mono);font-size:12px}
    @media (max-width: 1100px){.card{grid-column:span 6;}}
    @media (max-width: 640px){.card{grid-column:span 12;}}
    .section{
      margin-top:18px;background:linear-gradient(180deg, rgba(17,26,51,.92), rgba(15,23,48,.92));
      border:1px solid var(--line);
      border-radius:16px;
      padding:14px;
      box-shadow:0 10px 30px rgba(0,0,0,.35)
    }
    .section h2{margin:0 0 10px 0;font-size:14px;}
    .table{width:100%;border-collapse:collapse;margin-top:12px;font-size:12px;}
    .table th,.table td{border-bottom:1px solid var(--line);padding:9px 8px;vertical-align:top;}
    .table th{
      color:var(--muted);
      text-transform:uppercase;
      letter-spacing:.7px;
      font-size:11px;
      text-align:left;
      position:sticky;
      top:86px;
      background:rgba(15,23,48,.92);
      backdrop-filter:blur(8px)
    }
    .badge{
      display:inline-block;
      padding:3px 8px;
      border-radius:999px;
      border:1px solid var(--line);
      font-family:var(--mono);
      font-size:11px;
      margin-right:6px
    }
    .badge-ok{color:var(--ok);border-color:rgba(40,209,124,.35);background:rgba(40,209,124,.08)}
    .badge-warn{color:var(--warn);border-color:rgba(255,204,102,.35);background:rgba(255,204,102,.08)}
    .badge-bad{color:var(--bad);border-color:rgba(255,92,122,.35);background:rgba(255,92,122,.08)}
    .badge-info{color:var(--info);border-color:rgba(102,179,255,.35);background:rgba(102,179,255,.08)}
    .pill{
      display:inline-block;
      padding:3px 8px;
      border-radius:10px;
      font-family:var(--mono);
      font-size:11px;
      border:1px solid var(--line)
    }
    .pill-ok{color:var(--ok);background:rgba(40,209,124,.08);border-color:rgba(40,209,124,.35)}
    .pill-warn{color:var(--warn);background:rgba(255,204,102,.08);border-color:rgba(255,204,102,.35)}
    .pill-info{color:var(--info);background:rgba(102,179,255,.08);border-color:rgba(102,179,255,.35)}
    .searchbar{display:flex;gap:10px;align-items:center}
    input[type="text"]{
      width:420px;
      max-width:85vw;
      padding:10px 12px;
      border-radius:12px;
      border:1px solid var(--line);
      background:rgba(15,23,48,.7);
      color:var(--text);
      outline:none
    }
    input[type="text"]:focus{box-shadow:0 0 0 3px rgba(102,179,255,.18);border-color:rgba(102,179,255,.45)}
    .btn{
      padding:10px 12px;
      border-radius:12px;
      border:1px solid var(--line);
      background:rgba(17,26,51,.85);
      color:var(--text);
      cursor:pointer
    }
    .btn:hover{border-color:rgba(102,179,255,.45)}
    .footer{margin-top:18px;color:var(--muted);font-family:var(--mono);font-size:12px}
"@

  $js = @"
    function applyFilter(){
      const q = (document.getElementById('q').value||'').toLowerCase().trim();
      const rows = document.querySelectorAll('tbody tr[data-row]');
      let visible = 0;
      rows.forEach(
        r => {
          const hay = (r.getAttribute('data-hay')||'').toLowerCase();
          const show = (!q) || hay.includes(q);
          r.style.display = show ? '' : 'none';
          if(show) visible++;
        }
      );
      document.getElementById('visibleCount').textContent = visible.toString();
    }
    function clearFilter(){
      document.getElementById('q').value='';
      applyFilter();
    }
    window.addEventListener('load',()=>{applyFilter();document.getElementById('q').addEventListener('input',applyFilter);});
"@

  $linkRows = @()
  foreach ($l in ($allLinks | Sort-Object OuDn, Scope, LinkOrder, GpoName)){

    $b1 = if ($l.LinkEnabled) { New-Badge "Link ON" "ok" } else { New-Badge "Link OFF" "bad" }

    $bStatus = switch ($l.GpoStatus){
      "AllSettingsDisabled"      { New-Badge "ALL DISABLED" "bad" ; break }
      "UserSettingsDisabled"     { New-Badge "USER DISABLED" "warn"; break }
      "ComputerSettingsDisabled" { New-Badge "COMP DISABLED" "warn"; break }
      default                    { New-Badge ($l.GpoStatus) "info"; break }
    }

    $b2 = if ($l.UserSettingsEnabled){ New-Badge "User ON" "ok" } else { New-Badge "User OFF" "bad" }
    $b3 = if ($l.BroadApply){ New-Badge "Apply amplo" "ok" } else { New-Badge "Apply restrito" "warn" }
    $b4 = if ($l.LinkEnforced){ New-Badge "Enforced" "info" } else { "" }
    $b5 = if ($l.WmiFilter){ New-Badge "WMI Filter" "warn" } else { "" }
    $b6 = if ($l.AppliesAllUsersHeuristic){ New-Badge "OK (heurística)" "ok" } else { New-Badge "Risco" "warn" }
    $score = New-ScorePill $l.Score

    $modified = if ($l.Modified){ (Get-Date $l.Modified -Format "yyyy-MM-dd HH:mm") } else { "" }
    $hay = "$($l.OuDn) | $($l.GpoName) | $($l.Scope) | $($l.LinkSomPath) | $($l.Reasons) | $($l.GpoStatus)"

    $linkRows += @"
      <tr data-row="link" data-hay="$([System.Net.WebUtility]::HtmlEncode($hay))">
        <td><span class="badge badge-info">$(Html-Encode $l.Scope)</span><br><small>$(Html-Encode $l.LinkSomPath)</small></td>
        <td><div style="font-weight:700">$(Html-Encode $l.GpoName)</div><small>ID: $($l.GpoId)</small></td>
        <td>$(Html-Encode $l.OuDn)$($l.AmostraUsers)</td>
        <td>$score<br><small>Mod: $(Html-Encode $modified)</small></td>
        <td>$b1 $bStatus $b2 $b3 $b4 $b5 $b6</td>
        <td><small>$(Html-Encode $l.Reasons)</small></td>
      </tr>
"@
  }

  $html = @"
    <!doctype html>
    <html lang="pt-BR">
    <head>
      <meta charset="utf-8"/>
      <meta name="viewport" content="width=device-width, initial-scale=1"/>
      <title>Relatório de Auditoria de GPOs</title>
      <style>$css</style>
    </head>
    <body>
      <div class="header">
        <div class="hrow">
          <div>
            <h1 class="title">Relatório de Auditoria de GPOs — AD DS</h1>
            <p class="subtitle">
              Domínio: $(Html-Encode $domain.DNSRoot) · SearchBase: $(Html-Encode $searchBase) · Gerado em: $(Html-Encode ($nowExecution.ToString("yyyy-MM-dd HH:mm:ss")))
            </p>
          </div>
          <div class="searchbar">
            <input id="q" type="text" placeholder="Filtrar (OU, GPO, status...)"/>
            <button class="btn" onclick="clearFilter()">Limpar</button>
          </div>
        </div>
      </div>

      <div class="container">
        <div class="grid">
          <div class="card"><h3>Usuários analisados</h3><div class="big">$totalUserCount</div><div class="note">Fonte: AD</div></div>
          <div class="card"><h3>OUs/Containers com usuários</h3><div class="big">$totOus</div><div class="note">CN=Users usa fallback do domínio</div></div>
          <div class="card"><h3>Links efetivos</h3><div class="big">$totalLinks</div><div class="note">Tabela principal</div></div>
          <div class="card"><h3>Linhas visíveis</h3><div class="big" id="visibleCount">$totalLinks</div><div class="note">Filtro em tempo real</div></div>
        </div>

        <div class="section">
          <h2>Tabela — Links efetivos de GPO por OU</h2>
          <table class="table">
            <thead>
              <tr><th>Escopo</th><th>GPO</th><th>OU/Container do usuário</th><th>Score</th><th>Status</th><th>Motivos</th></tr>
            </thead>
            <tbody>
              $($linkRows -join "`n")
            </tbody>
          </table>
        </div>

        <div class="footer">
          HTML: $(Html-Encode $outputPath) · Arquivo de Log: $(Html-Encode $logPath)
        </div>
      </div>

      <script>$js</script>
    </body>
    </html>
"@

  $html | Out-File -FilePath $outputPath -Encoding UTF8
  Grava-LogLocal -texto "Relatório gerado em HTML com sucesso: $outputPath" -tipo OK
  Grava-LogLocal -texto "================ Auditoria de GPOs Concluída ================" -tipo STP
} catch {
  Grava-LogLocal -texto "ERRO FATAL DURANTE A EXECUÇÃO DO SCRIPT: $($_.Exception.Message)" -tipo ERR
  if ($_.ScriptStackTrace){
    Grava-LogLocal -texto "Stack Trace: $($_.ScriptStackTrace)" -tipo ERR
  }
}