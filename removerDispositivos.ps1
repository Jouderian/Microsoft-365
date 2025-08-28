#-------------------------------------------------------------------------------
# Descricao: Remove do EntraID os dispositivos sem uso a mais de 180 dias (licença maternidade)
# Versao: 1 (17/07/25) Jouderian Nobre
#-------------------------------------------------------------------------------

# Autenticar no Microsoft Graph
Connect-MgGraph -Scopes "Device.ReadWrite.All" -NoWelcome

# Declarando variaveis
$limiteDias = 190 # Dias de inatividade (Licenca maternidade e margem de seguranca)
$dataLimite = (Get-Date).AddDays(-$limiteDias)

# Buscar todos os dispositivos
$dispositivosAntigos = Get-MgDevice -All | Where-Object {
  $_.ApproximateLastSignInDateTime -lt $dataLimite -and $_.AccountEnabled
}

# Exibir resumo
Write-Host "Dispositivos a serem removidos:" -ForegroundColor Cyan
$dispositivosAntigos | Select-Object DisplayName, Id, ApproximateLastSignInDateTime | Format-Table

# Validação de confirmação
$confirmacao = Read-Host "Deseja remover esses $($dispositivosAntigos.Count) dispositivos? (s/n)"
if ($confirmacao.ToUpper() -eq "N"){
  Write-Host "Operação cancelada." -ForegroundColor Yellow
  exit
}

foreach ($dispositivo in $dispositivosAntigos){
  Remove-MgDevice -DeviceId $dispositivo.Id
  Write-Host "Removido: $($dispositivo.DisplayName) ($($dispositivo.Id))" -ForegroundColor Green
}

# Desconectar do Graph
Disconnect-MgGraph