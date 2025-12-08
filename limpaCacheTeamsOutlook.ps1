<#
.SYNOPSIS
  Limpa cache de TODAS as versoes comuns de Microsoft Teams (classico, novo) e Outlook (classico e novo do Windows 11) para o usuario atual, fechando os apps, apagando caches e reabrindo em seguida.

.NOTES
  - Nao requer privilégios administrativos.
  - Executar na sessao do próprio usuario.
#>

# Funcoes utilitarias
function Write-Log {
  param(
    [string]$Message,
    [string]$Level = "INFO"
  )
  $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[$timestamp][$Level] $Message"
}

function Stop-ProcessSafe {
  param(
    [string[]]$Names
  )

  foreach ($name in $Names){
    try {
      $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
      if ($procs) {
        Write-Log "Finalizando processo: $name" "INFO"
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
      } else {
        Write-Log "Processo nao esta em execucao: $name" "DEBUG"
      }
    } catch {
      Write-Log "Erro ao finalizar processo ${name}: $($_.Exception.Message)" "WARN"
    }
  }
}

function Remove-PathSafe {
  param(
    [string]$Path,
    [switch]$Recurse = $true
  )

  try {
    if (Test-Path -LiteralPath $Path){
      Write-Log "Removendo: $Path" "INFO"
      if ($Recurse){
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
      } else {
        Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
      }
    } else {
      Write-Log "Caminho nao encontrado, ignorando: $Path" "DEBUG"
    }
  } catch {
    Write-Log "Erro ao remover ${Path}: $($_.Exception.Message)" "WARN"
  }
}

# Teams classico (cache principal em %APPDATA%\Microsoft\Teams)
function Clear-TeamsClassicRoamingCache {
  Write-Log "=== Limpando cache do Teams (Roaming - classico) ==="

  $teamsRoot = Join-Path $env:APPDATA "Microsoft\Teams"

  $pathsToClear = @(
    "blob_storage",
    "Cache",
    "databases",
    "GPUCache",
    "IndexedDB",
    "Local Storage",
    "tmp",
    "service worker",
    "Code Cache",
    "BrowserMetrics",
    "skylib\contacts",
    "skylib\presence"
  )

  foreach ($rel in $pathsToClear){
    $full = Join-Path $teamsRoot $rel
    Remove-PathSafe -Path $full
  }
}

# Teams classico / Electron em %LOCALAPPDATA%\Microsoft\Teams
function Clear-TeamsLocalElectronCache {
  Write-Log "=== Limpando cache do Teams (Local - Electron/classico) ==="

  $teamsLocalRoot = Join-Path $env:LOCALAPPDATA "Microsoft\Teams"

  $pathsToClear = @(
    "current\blob_storage",
    "current\Cache",
    "current\databases",
    "current\GPUCache",
    "current\IndexedDB",
    "current\Local Storage",
    "current\tmp",
    "current\service worker",
    "current\Code Cache",
    "current\BrowserMetrics"
  )

  foreach ($rel in $pathsToClear){
    $full = Join-Path $teamsLocalRoot $rel
    Remove-PathSafe -Path $full
  }
}

# Novo Teams MSIX (%LOCALAPPDATA%\Packages\MSTeams_8wekyb3d8bbwe)
function Clear-TeamsNewMsixCache {
  Write-Log "=== Limpando cache do novo Teams (MSIX) ==="

  $teamsPkgRoot = Join-Path $env:LOCALAPPDATA "Packages\MSTeams_8wekyb3d8bbwe"

  $pathsToClear = @(
    "LocalCache",
    "LocalState",
    "Cache",
    "Blob_storage",
    "IndexedDB"
  )

  foreach ($rel in $pathsToClear){
    $full = Join-Path $teamsPkgRoot $rel
    Remove-PathSafe -Path $full
  }
}

# Limpeza Outlook (classico e novo)
function Clear-OutlookCache {
  Write-Log "=== Limpando cache do Outlook (classico / novo) ==="

  $classicRoamCache = Join-Path $env:LOCALAPPDATA "Microsoft\Outlook\RoamCache"
  $newOutlookPkg    = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.OutlookForWindows_8wekyb3d8bbwe"
  $newOutlookOlk    = Join-Path $env:LOCALAPPDATA "Microsoft\olk"

  $limpouAlgo = $false

  # Outlook novo – limpa LocalCache e TempState
  if (Test-Path $newOutlookPkg){
    Write-Log "Detectado Outlook novo (Windows 11). Limpando cache do app..." "INFO"

    $pathsNew = @(
      (Join-Path $newOutlookPkg "LocalCache"),
      (Join-Path $newOutlookPkg "TempState")
    )

    foreach ($p in $pathsNew){
      Remove-PathSafe -Path $p
    }

    # pasta auxiliar olk (perfis/cache)
    if (Test-Path $newOutlookOlk){
      Remove-PathSafe -Path $newOutlookOlk
    }

    $limpouAlgo = $true
  }

  # Outlook classico – limpa RoamCache (autocomplete/GAL)
  if (Test-Path $classicRoamCache){
    Write-Log "Detectado Outlook classico. Limpando RoamCache..." "INFO"

    $patterns = @(
      "Stream_Autocomplete*",
      "Stream_AutoComplete*",
      "Stream_Cache*"
    )

    foreach ($pattern in $patterns){
      $files = Get-ChildItem -Path $classicRoamCache -Filter $pattern -ErrorAction SilentlyContinue
      foreach ($file in $files){
        Remove-PathSafe -Path $file.FullName -Recurse:$false
      }
    }

    $limpouAlgo = $true
  }

  if (-not $limpouAlgo) {
    Write-Log "Nenhuma estrutura de cache encontrada para Outlook (novo ou classico). Talvez o app ainda nao tenha sido aberto neste perfil." "WARN"
  }
}

# Reabrir aplicativos
function Start-TeamsSafe {
  Write-Log "=== Reabrindo Microsoft Teams ==="

  $started = $false

  try {
    # Novo Teams via protocolo (funciona para MSIX e, muitas vezes, para o classico)
    Start-Process "ms-teams:" -ErrorAction Stop
    Write-Log "Teams iniciado via protocolo ms-teams:" "INFO"
    $started = $true
  } catch {
    Write-Log "Falha ao iniciar Teams via ms-Teams:. Tentando via Update.exe padrao do Teams classico..." "WARN"
  }

  if (-not $started){
    $updateExe = Join-Path $env:LOCALAPPDATA "Microsoft\Teams\Update.exe"
    if (Test-Path $updateExe){
      try {
        Start-Process $updateExe -ArgumentList "--processStart `"`"Teams.exe`"`"" -ErrorAction Stop
        Write-Log "Teams classico iniciado via Update.exe" "INFO"
        $started = $true
      } catch {
        Write-Log "Erro ao iniciar Teams classico: $($_.Exception.Message)" "ERROR"
      }
    } else {
      Write-Log "Update.exe do Teams nao encontrado em $updateExe" "WARN"
    }
  }

  if (-not $started){
    Write-Log "Nao foi possivel iniciar o Teams automaticamente. Inicie manualmente se necessario." "ERROR"
  }
}

function Start-OutlookSafe {
  Write-Log "=== Reabrindo Outlook ==="

  $newOutlookPkg = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.OutlookForWindows_8wekyb3d8bbwe"

  $started = $false

  # 1) Tenta Outlook novo (Windows 11 / Store)
  if (Test-Path $newOutlookPkg){
    try {
      Start-Process "explorer.exe" "shell:AppsFolder\Microsoft.OutlookForWindows_8wekyb3d8bbwe!Microsoft.OutlookForWindows" -ErrorAction Stop
      Write-Log "Outlook novo iniciado (app Windows)." "INFO"
      $started = $true
    } catch {
      Write-Log "Erro ao iniciar Outlook novo: $($_.Exception.Message)" "WARN"
    }
  }

  # 2) Se nao conseguiu, tenta Outlook classico
  if (-not $started){
    try {
      $cmd = Get-Command "outlook.exe" -ErrorAction SilentlyContinue
      if ($cmd){
        Start-Process "outlook.exe" -ErrorAction Stop
        Write-Log "Outlook classico iniciado." "INFO"
        $started = $true
      }
    } catch {
      Write-Log "Erro ao iniciar Outlook classico: $($_.Exception.Message)" "WARN"
    }
  }

  if (-not $started){
    Write-Log "Nao foi possivel localizar/abrir Outlook (novo ou classico). Verifique se o app esta instalado." "WARN"
  }
}

# Execucao principal

Write-Log "==== INICIO DA LIMPEZA DE CACHE TEAMS/OUTLOOK ===="

# 1. Fechar Teams e Outlook (varias variacoes de processo)
Write-Log "Fechando Teams e Outlook..." "INFO"
Stop-ProcessSafe -Names @(
  # Teams
  "ms-teams", # novo Teams (ms-teams.exe)
  "MSTeams",  # algumas builds
  "teams",    # Teams classico (Teams.exe)

  # Outlook novo & Mail app
  "olk",
  "HxOutlook",
  "HxTsr",
  "HxMail",

  # Outlook classico
  "outlook"
)

# 2. Limpar caches do Teams (todas as variantes)
Clear-TeamsClassicRoamingCache
Clear-TeamsLocalElectronCache
Clear-TeamsNewMsixCache

# 3. Limpar caches do Outlook (novo/classico)
Clear-OutlookCache

Write-Log "Limpeza de cache concluida." "INFO"

# 4. Reabrir aplicativos
Start-TeamsSafe
Start-OutlookSafe

Write-Log "==== FIM DA LIMPEZA DE CACHE TEAMS/OUTLOOK ===="