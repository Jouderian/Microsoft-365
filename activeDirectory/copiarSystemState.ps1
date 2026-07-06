#--------------------------------------------------------------------------------------------------------
# Autor: Jouderian Nobre
# Descricao: Copia de Segurança do AD
# Versao: 1 (31/07/25) Jouderian Nobre
#--------------------------------------------------------------------------------------------------------

Clear-Host

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

# Declarando variaveis
$inicio = Get-Date
$retrencao = 7 # Número máximo de backups a manter
$localCopia = "D:\backupAD"
$logs = "C:\ScriptsRotinas\backupAD\LOGs\backupAD_$($inicio.ToString('MMMyy')).txt"
$arquivo = "$localCopia\copiaAD_$($inicio.ToString('yyyyMMMdd_HHmm'))"

gravaLOG -arquivo $logs -texto "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))"

# Cria diretório de backup se não existir
if (-not (Test-Path $arquivo)){
  New-Item -Path $arquivo -ItemType Directory | Out-Null
}

# Realiza backup do estado do sistema (inclui AD, SYSVOL, registro, etc)
gravaLOG -arquivo $logs -texto "Iniciando a copia do estado do sistema (AD, SYSVOL, registro, etc)..."
try {
  wbAdmin start systemStateBackup -backupTarget:$arquivo -quiet
  gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Copia de Seguranca do AD concluído com sucesso em $arquivo"
} catch {
  gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Realizar Copia de Seguranca do AD: $($_.Exception.Message)" -erro:$true
  Exit
}

# Limpeza de backups antigos (mantém apenas os 7 mais recentes)
$backups = Get-ChildItem -Path $localCopia | Where-Object { $_.PSIsContainer } | Sort-Object CreationTime -Descending
if ($backups.Count -gt $retrencao){
  $toRemove = $backups | Select-Object -Skip $retrencao
  foreach ($item in $toRemove){
    Remove-Item -Path $item.FullName -Recurse -Force
    gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Copia de Seguranca antiga removido: $($item.FullName)"
  }
}

gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Terminada gravacao. Tempo de duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())"