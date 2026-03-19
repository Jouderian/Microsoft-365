#--------------------------------------------------------------------------------------------------------
# Descricao: Limpa o cache do Microsoft Teams para resolver problemas de desempenho, autenticação ou exibição
# Versao 01 (17/03/26) Felipe Aquino
# Versao 02 (19/03/26) Jouderian Nobre: Melhorada para abranger Teams clássico, novo Teams e variações
#--------------------------------------------------------------------------------------------------------
# Observação: Este script deve ser executado no contexto do usuário que utiliza o Teams, pois ele acessa
#             as pastas de cache do usuário
#--------------------------------------------------------------------------------------------------------

Write-Host "Fechando processos do Teams..." -ForegroundColor Cyan

# Processos mais comuns do Teams clássico, novo Teams e variações
$processNames = @(
  "Teams",
  "ms-teams",
  "msteams",
  "Microsoft.Teams",
  "Teams.exe",
  "MSTeams.exe"
)

foreach ($proc in $processNames){
  try {
    Get-Process -Name $proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "Processo $proc fechado." -ForegroundColor Green
  } catch {
    Write-Host "Erro ao fechar $($proc): $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

Start-Sleep -Seconds 3

Write-Host "Limpando cache do Teams..." -ForegroundColor Cyan

# Pastas de cache - Teams clássico (expandido)
$classicPaths = @(
  "$env:APPDATA\Microsoft\Teams\Application Cache\Cache",
  "$env:APPDATA\Microsoft\Teams\Blob_storage",
  "$env:APPDATA\Microsoft\Teams\Cache",
  "$env:APPDATA\Microsoft\Teams\Code Cache",
  "$env:APPDATA\Microsoft\Teams\databases",
  "$env:APPDATA\Microsoft\Teams\GPUCache",
  "$env:APPDATA\Microsoft\Teams\IndexedDB",
  "$env:APPDATA\Microsoft\Teams\Local Storage",
  "$env:APPDATA\Microsoft\Teams\tmp",
  "$env:LOCALAPPDATA\Microsoft\Teams"  # Adicionado para variações
)

# Pastas de cache - Novo Teams (expandido)
$newTeamsPaths = @(
  "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams",
  "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalState",
  "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\TempState"  # Adicionado
)

$allPaths = $classicPaths + $newTeamsPaths

foreach ($path in $allPaths){
  if (Test-Path $path){
    try {
      Write-Host "Limpando: $path"
      Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
      Write-Host "Erro ao limpar $($path): $($_.Exception.Message)" -ForegroundColor Yellow
    }
  } else {
    Write-Host "Caminho não encontrado: $path" -ForegroundColor Yellow
  }
}

Start-Sleep -Seconds 2

Write-Host "Tentando abrir o Teams novamente..." -ForegroundColor Cyan

# Verificar e abrir Novo Teams
$newTeamsPackage = Get-AppxPackage -Name "MSTeams" -ErrorAction SilentlyContinue
if ($newTeamsPackage){
  Write-Host "Abrindo novo Teams..."
  try {
    Start-Process "explorer.exe" "shell:AppsFolder\MSTeams_8wekyb3d8bbwe!MSTeams"
    Start-Sleep -Seconds 2
  } catch {
    Write-Host "Erro ao abrir novo Teams: $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

# Verificar e abrir Teams clássico
$classicTeamsExe = "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe"
if (Test-Path $classicTeamsExe){
  Write-Host "Abrindo Teams clássico..."
  try {
    Start-Process $classicTeamsExe
  } catch {
    Write-Host "Erro ao abrir Teams clássico: $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

Write-Host "Concluído. Se problemas persistirem, considere reiniciar o computador." -ForegroundColor Green