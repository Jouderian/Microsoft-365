<#
  .SYNOPSIS
    Limpa o cache das aplicacoes Microsoft Teams e Microsoft Outlook para o usuario atual.
  .DESCRIPTION
    Este script fecha com seguranca os processos das aplicacoes Microsoft Teams e Microsoft Outlook,
    remove os arquivos e pastas temporarios e de cache e reabre as aplicacoes.
    Oferece flexibilidade permitindo rodar para ambas as aplicacoes por padrao, ou restringindo a
    apenas uma delas via parametros.
  .AUTHOR
    Felipe Aquino
  .CREATED
    17/03/26
  .VERSION
    02 (19/03/26) Jouderian Nobre: Melhorada para abranger Teams clássico, novo Teams e variações
    03 (17/05/26) Jouderian Nobre: Unificacao completa do codigo
  .PARAMETER
    -somenteTeams: Limpa apenas o cache do Microsoft Teams.
    -somenteOutlook: Limpa apenas o cache do Microsoft Outlook.
#>

param(
  [switch]$somenteTeams,
  [switch]$somenteOutlook
)

# ---------------- Controle de Execucao ----------------
$limparTeams = $true
$limparOutlook = $true

if ($somenteTeams -or $somenteOutlook){
  $limparTeams = $somenteTeams
  $limparOutlook = $somenteOutlook
}

# ---------------- Funcoes Utilitarias ----------------
function Write-Log {
  param(
    [string]$message,
    [string]$level = "INFO"
  )
  $timestamp = (Get-Date).ToString("dd-MM-yy HH:mm:ss")
  Write-Host "[$timestamp][$level] $message"
}

function Stop-ProcessSafe {
  param(
    [string[]]$names
  )

  foreach ($name in $names){
    try {
      $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
      if ($procs){
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
    [string]$path,
    [switch]$recurse = $true
  )

  try {
    if (Test-Path -LiteralPath $path){
      Write-Log "Removendo: $path" "INFO"
      if ($recurse){
        Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
      } else {
        Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
      }
    } else {
      Write-Log "Caminho nao encontrado, ignorando: $path" "DEBUG"
    }
  } catch {
    Write-Log "Erro ao remover ${path}: $($_.Exception.Message)" "WARN"
  }
}

# ---------------- Funcoes de Limpeza ----------------

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
    "skylib\presence",
    "Application Cache\Cache"
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
    "IndexedDB",
    "TempState" # Adicionado de limparCacheTeams.ps1
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
  $newOutlookPkg = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.OutlookForWindows_8wekyb3d8bbwe"
  $newOutlookOlk = Join-Path $env:LOCALAPPDATA "Microsoft\olk"

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

  if (-not $limpouAlgo){
    Write-Log "Nenhuma estrutura de cache encontrada para Outlook (novo ou classico). Talvez o app ainda nao tenha sido aberto neste perfil." "WARN"
  }
}

# ---------------- Funcoes de Inicializacao ----------------
function Start-TeamsSafe {
  Write-Log "=== Reabrindo Microsoft Teams ==="

  $started = $false

  try {
    # Novo Teams via protocolo (funciona para MSIX e, muitas vezes, para o classico)
    Start-Process "ms-teams:" -ErrorAction Stop
    Write-Log "Teams iniciado via protocolo ms-teams:" "INFO"
    $started = $true
  } catch {
    Write-Log "Falha ao iniciar Teams via ms-teams:. Tentando via Update.exe padrao do Teams classico..." "WARN"
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
    # Tentativa alternativa via explorer shell
    try {
      Start-Process "explorer.exe" "shell:AppsFolder\MSTeams_8wekyb3d8bbwe!MSTeams" -ErrorAction Stop
      Write-Log "Teams iniciado via explorer shell" "INFO"
      $started = $true
    } catch {
      Write-Log "Erro ao iniciar Teams via explorer shell: $($_.Exception.Message)" "WARN"
    }
  }

  if (-not $started){
    # Tentativa via Teams.exe classico diretamente
    $classicTeamsExe = "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe"
    if (Test-Path $classicTeamsExe){
      try {
        Start-Process $classicTeamsExe -ErrorAction Stop
        Write-Log "Teams classico iniciado via executavel direto" "INFO"
        $started = $true
      } catch {
        Write-Log "Erro ao iniciar Teams classico via executavel: $($_.Exception.Message)" "ERROR"
      }
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

# ---------------- Execucao Principal ----------------

Write-Log "==== INICIO DA LIMPEZA DE CACHE ===="

# 1. Fechar Aplicativos Condicionalmente
if ($limparTeams){
  Write-Log "Fechando processos do Teams..." "INFO"
  Stop-ProcessSafe -names @(
    "ms-teams",        # novo Teams (ms-teams.exe)
    "MSTeams",         # algumas builds
    "teams",           # Teams classico (Teams.exe)
    "msteams",         # algumas builds
    "Microsoft.Teams"  # novo Teams (MSIX)
  )
}

if ($limparOutlook){
  Write-Log "Fechando processos do Outlook..." "INFO"
  Stop-ProcessSafe -names @(
    "olk",
    "HxOutlook",
    "HxTsr",
    "HxMail",
    "outlook"
  )
}

# Aguardar finalizacao completa dos processos
Start-Sleep -Seconds 2

# 2. Limpar Caches Condicionalmente
if ($limparTeams){
  Clear-TeamsClassicRoamingCache
  Clear-TeamsLocalElectronCache
  Clear-TeamsNewMsixCache
}

if ($limparOutlook){
  Clear-OutlookCache
}

Write-Log "Limpeza de cache concluida." "INFO"

# 3. Reabrir Aplicativos Condicionalmente
if ($limparTeams){
  Start-TeamsSafe
}

if ($limparOutlook){
  Start-OutlookSafe
}

Write-Log "==== FIM DA LIMPEZA DE CACHE ===="