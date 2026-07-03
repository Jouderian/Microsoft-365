<#
.SYNOPSIS
  Remove do EntraID os dispositivos sem uso a mais de 190 dias (licença maternidade)
.DESCRIPTION
  O script se conecta ao ambiente do Microsoft 365, busca todos os dispositivos existentes e extrai uma série de informações sobre cada dispositivo, como nome, UPN, cidade, empresa, tipo, tamanho utilizado, entre outros. As informações são gravadas em um arquivo CSV para análise posterior.
.AUTHOR
  Jouderian Nobre
.VERSION
  01 (17/07/25) - Criacao do script
  02 (05/04/26) - Atualizacao da documentacao
#>

# Declarando variaveis
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\removerDispositivos_$($inicio.ToString('MMMyy')).txt"
$limiteDias = 190 # Dias de inatividade (Licenca maternidade + 10 dias de margem de seguranca)
$dataLimite = (Get-Date).AddDays(-$limiteDias)

gravaLOG "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))" -tipo WRN -arquivo $logs -mostraTempo:$true
gravaLOG "Conectando ao Microsoft 365..." -tipo INF -arquivo $logs

# Validacoes
VerificaModulo -NomeModulo "Microsoft.Graph" -MensagemErro "O modulo Microsoft Graph e necessario e nao esta instalado no sistema." -arquivoLogs $logs

try {
  Import-Module -Name Microsoft.Graph.Devices
  Connect-MgGraph -Scopes "Device.ReadWrite.All" -NoWelcome
}
catch {
  gravaLOG "Erro ao conectar ao Microsoft Graph: $($_.Exception.Message)" -tipo ERR -arquivo $logs -mostraTempo:$true
  Exit
}

# Buscar todos os dispositivos
gravaLOG "Buscando dispositivos a serem removidos" -tipo INF -arquivo $logs -mostraTempo:$true
$dispositivosAntigos = Get-MgDevice -All | Where-Object {
  $_.ApproximateLastSignInDateTime -lt $dataLimite
  -and $_.AccountEnabled
}

# Exibir resumo
gravaLOG "$($dispositivosAntigos.Count) dispositivos serao removidos" -tipo INF -arquivo $logs -mostraTempo:$true
$dispositivosAntigos | Select-Object DisplayName, Id, ApproximateLastSignInDateTime | Format-Table

# Validação de confirmação
$confirmacao = Read-Host "Deseja remover esses $($dispositivosAntigos.Count) dispositivos? (s/n)"
if ($confirmacao.ToUpper() -eq "N") {
  gravaLOG "Operação cancelada." -tipo WRN -arquivo $logs -mostraTempo:$true
  exit
}

foreach ($dispositivo in $dispositivosAntigos) {
  try {
    Remove-MgDevice -DeviceId $dispositivo.Id
    gravaLOG "Removido: $($dispositivo.DisplayName) ($($dispositivo.Id))" -tipo OK -arquivo $logs
  }
  catch {
    gravaLOG "Erro ao remover $($dispositivo.DisplayName) ($($dispositivo.Id)): $($_.Exception.Message)" -tipo ERR -arquivo $logs
  }
}

# Desconectando dos ambientes
Disconnect-MgGraph
gravaLOG -texto "Ambientes desconectados." -tipo INF -arquivo $logs -mostraTempo:$true

# Finalizando o script
$final = Get-Date
gravaLOG -texto "Tempo de duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())" -tipo WRN -arquivo $logs -mostraTempo:$true