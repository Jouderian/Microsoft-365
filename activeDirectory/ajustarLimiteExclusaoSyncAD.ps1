#--------------------------------------------------------------------------------------------------------
# Descricao: Ajusta temporariamente o limite de exclusões do entraConnectSync e restaura ao final.
# Versao 02 (23/07/25) Jouderian Nobre
#--------------------------------------------------------------------------------------------------------
# Observacao: Este script deve ser executado com permissões administrativas e no computador com o módulo ADSync instalado
#--------------------------------------------------------------------------------------------------------

Import-Module ADSync

Clear-Host

# Declarando variaveis
$sugestao = 0
$novoLimite = 0
$limiteAtual = 0
$usuario = Read-Host "`nInforme o usuário administrador do sincronismo do M365"

# Solicita e valida o novo limite
do {
  $sugestao = Read-Host "`nInforme o novo limite de exclusão temporário (valor inteiro positivo)"
  $validacao = $sugestao -match '^\d+$' -and [int]$sugestao -gt 0
  if (-not $validacao){ Write-Host "Valor inválido. Tente novamente." -ForegroundColor Yellow }
} until ($validacao)
$novoLimite = [int]$sugestao

# Obtém o limite atual
$limiteAtual = Get-ADSyncExportDeletionThreshold -AADUserName $usuario
$limiteAtual = $limiteAtual.AlertThreshold
Write-Host "`n$(Get-Date -Format 'dd/MM/yy HH:mm:ss') | Limite atual: $limiteAtual"

# Define o novo limite temporário
try {
  Enable-ADSyncExportDeletionThreshold -DeletionThreshold $novoLimite -AADUserName $usuario
  Write-Host "`n$(Get-Date -Format 'dd/MM/yy HH:mm:ss') | Novo limite temporário definido: $novoLimite"
} catch {
  Write-Host "Erro ao definir novo limite: $($_.Exception.Message)" -ForegroundColor Red
  exit
}

# Executa a sincronização delta
try {
  Start-ADSyncSyncCycle -PolicyType Delta
  Write-Host "`n$(Get-Date -Format 'dd/MM/yy HH:mm:ss') | Sincronização Delta iniciada..."
} catch {
  Write-Host "Erro ao iniciar sincronização: $($_.Exception.Message)" -ForegroundColor Red
}

Read-Host "`nApos a conclusao do sincrismo pressiona [ENTER]"

# Restaura o limite original
try {
  Enable-ADSyncExportDeletionThreshold -DeletionThreshold $limiteAtual -AADUserName $usuario
  Write-Host "`n$(Get-Date -Format 'dd/MM/yy HH:mm:ss') | Limite restaurado para: $limiteAtual"
} catch {
  Write-Host "Erro ao restaurar limite original: $($_.Exception.Message)" -ForegroundColor Red
}