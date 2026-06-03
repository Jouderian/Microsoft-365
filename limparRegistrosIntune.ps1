<#
  .SYNOPSIS
    Verifica e ajusta o serviço dmwappushservice e limpa registros de Enrollments do Intune.
  .DESCRIPTION
    Este script assegura que o serviço dmwappushservice esteja em Automatic (sem trigger) e rodando.
    Em seguida, exclui as subchaves em HKLM:\SOFTWARE\Microsoft\Enrollments e ajusta a MmpEnrollmentFlag.
    Por fim, executa um gpupdate /force.
  .AUTHOR
    Jouderian Nobre
  .CREATED
    03/06/26
  .VERSION
    02 (03/06/26) - Refatorado para seguir os padrões SDD de Clean Code e modularização.
  .OUTPUT
    Console
#>

$ErrorActionPreference = "Stop"

function Test-IsAdmin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-ServiceStartMode {
  param([Parameter(Mandatory = $true)][string]$name)

  $svc = Get-CimInstance -ClassName Win32_Service -Filter "Name='$name'" -ErrorAction Stop
  return $svc.StartMode
}

function Test-ServiceHasTriggers {
  param([Parameter(Mandatory = $true)][string]$name)

  $out = & sc.exe qtriggerinfo $name 2>$null
  if (-not $out) { return $false }

  $text = ($out | Out-String)
  return ($text -notmatch "No triggers|Nenhum gatilho|No Trigger|No Triggers")
}

function Remove-ServiceTriggers {
  param([Parameter(Mandatory = $true)][string]$name)

  $null = & sc.exe triggerinfo $name delete 2>$null
}

function Set-ServiceAutomatic {
  param([Parameter(Mandatory = $true)][string]$name)

  $null = & sc.exe config $name start= auto 2>$null
}

function Start-ServiceAndWait {
  param([Parameter(Mandatory = $true)][string]$name)

  $svc = Get-Service -Name $name -ErrorAction Stop
  if ($svc.Status -ne 'Running'){
    Start-Service -Name $name -ErrorAction Stop
    $svc.WaitForStatus('Running', '00:00:20') | Out-Null
  }
}

function Invoke-IntuneRegistryCleanup {
  $serviceName = "dmwappushservice"
  Write-Host "== Validando serviço: $serviceName ==" -ForegroundColor Cyan

  try {
    $startMode = Get-ServiceStartMode -name $serviceName
    $hasTriggers = Test-ServiceHasTriggers -name $serviceName

    Write-Host "StartMode atual (Win32_Service): $startMode"
    Write-Host "Detectado Trigger Start: $hasTriggers"

    if ($startMode -eq "Disabled" -or $hasTriggers){
      if ($hasTriggers){
        Write-Host "Removendo triggers do serviço (Automatic (Trigger Start) -> Automatic)..." -ForegroundColor Yellow
        Remove-ServiceTriggers -name $serviceName
      }

      Write-Host "Configurando serviço para Automatic..." -ForegroundColor Yellow
      Set-ServiceAutomatic -name $serviceName
    }

    Write-Host "Iniciando/validando execução do serviço..." -ForegroundColor Yellow
    Start-ServiceAndWait -name $serviceName

    $svcNow = Get-Service -Name $serviceName
    Write-Host "Serviço OK: $($svcNow.Name) / Status: $($svcNow.Status)" -ForegroundColor Green
  } catch {
    Write-Host "Falha ao validar/iniciar o serviço $serviceName : $($_.Exception.Message)" -ForegroundColor Red
  }

  Write-Host ""
  Write-Host "== Verificando MmpEnrollmentFlag ==" -ForegroundColor Cyan

  $enrollPath = "HKLM:\SOFTWARE\Microsoft\Enrollments"
  try {
    if (Test-Path $enrollPath){
      $mmpValue = Get-ItemProperty -Path $enrollPath -Name "MmpEnrollmentFlag" -ErrorAction SilentlyContinue

      if ($null -ne $mmpValue){
        $currentFlag = [int]$mmpValue.MmpEnrollmentFlag
        Write-Host "Valor atual de MmpEnrollmentFlag: $currentFlag"

        if ($currentFlag -eq 2){
          Set-ItemProperty -Path $enrollPath -Name "MmpEnrollmentFlag" -Value 0 -Type DWord -ErrorAction Stop
          Write-Host "MmpEnrollmentFlag alterado de 2 para 0 com sucesso." -ForegroundColor Green
        } else {
          Write-Host "MmpEnrollmentFlag não está com valor 2. Nenhuma alteração necessária." -ForegroundColor DarkYellow
        }
      } else {
        Write-Host "Valor MmpEnrollmentFlag não encontrado em $enrollPath." -ForegroundColor DarkYellow
      }
    } else {
      Write-Host "Caminho não existe para verificar MmpEnrollmentFlag: $enrollPath" -ForegroundColor DarkYellow
    }
  } catch {
    Write-Host "Falha ao verificar/alterar MmpEnrollmentFlag: $($_.Exception.Message)" -ForegroundColor Red
  }

  Write-Host ""
  Write-Host "== Excluindo registros de HKLM:\SOFTWARE\Microsoft\Enrollments ==" -ForegroundColor Cyan

  $failedDeletes = New-Object System.Collections.Generic.List[string]
  try {
    if (Test-Path $enrollPath){
      $keys = Get-ChildItem -Path $enrollPath -ErrorAction Stop

      if (-not $keys -or $keys.Count -eq 0){
        Write-Host "Nenhuma subchave encontrada em Enrollments." -ForegroundColor DarkYellow
      } else {
        foreach ($k in $keys){
          try {
            Remove-Item -Path $k.PSPath -Recurse -Force -ErrorAction Stop
            Write-Host "Excluído: $($k.PSChildName)"
          } catch {
            $failedDeletes.Add($k.PSChildName) | Out-Null
            Write-Host "FALHOU: $($k.PSChildName) :: $($_.Exception.Message)" -ForegroundColor Red
            continue
          }
        }
      }
    } else {
      Write-Host "Caminho não existe: $enrollPath" -ForegroundColor DarkYellow
    }
  } catch {
    Write-Host "Falha ao enumerar $($enrollPath): $($_.Exception.Message)" -ForegroundColor Red
  }

  Write-Host ""
  Write-Host "== Resultado da exclusão ==" -ForegroundColor Cyan

  if ($failedDeletes.Count -gt 0){
    Write-Host "As seguintes subchaves NÃO foram excluídas:" -ForegroundColor Yellow
    $failedDeletes | Sort-Object | ForEach-Object { Write-Host " - $_" }
  } else {
    Write-Host "Todas as subchaves foram excluídas com sucesso (ou não havia nada para excluir)." -ForegroundColor Green
  }

  Write-Host ""
  Write-Host "== Executando GPUPDATE /FORCE ==" -ForegroundColor Cyan
  try {
    $p = Start-Process -FilePath "gpupdate.exe" -ArgumentList "/force" -Wait -PassThru -WindowStyle Hidden
    Write-Host "GPUpdate finalizado. ExitCode: $($p.ExitCode)" -ForegroundColor Green
  } catch {
    Write-Host "Falha ao executar gpupdate: $($_.Exception.Message)" -ForegroundColor Red
  }

  Write-Host ""
  Write-Host "Concluído." -ForegroundColor Green
}

# ---------------- MAIN ----------------
try {
  if (-not (Test-IsAdmin)){
    Write-Host "ERRO: execute este script em um PowerShell 'Executar como administrador'." -ForegroundColor Red
    exit 1
  }

  Invoke-IntuneRegistryCleanup
} catch {
  Write-Host "Erro inesperado na execução do script: $($_.Exception.Message)" -ForegroundColor Red
}