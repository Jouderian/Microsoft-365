<#
  .SYNOPSIS
   Script para ativar o litigio nas caixas postais com licenças: Office 365 E3 e Business Premium
  .AUTHOR
   Jouderian Nobre
  .VERSION
   1 (23/06/23) - Criacao do script
   2 (29/12/24) - Passa a ler a variavel do Windows para local do arquivo
   3 (28/06/25) - Adequando ao uso da biblioteca de funcoes
   4 (05/04/26) - Atualizacao da documentacao
#>

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\ativarLitigio_$($inicio.ToString('MMMyy')).txt"
$arquivoEntrada = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\credenciaisLitigio.csv"

# Validacoes
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema." -arquivoLogs $logs

gravaLOG "Inicio: $inicio" -tipo WRN -arquivo $logs -mostraTempo:$true
gravaLOG "Importando relação de caixas postais..." -tipo INF -arquivo $logs

try {
  Import-Module ExchangeOnlineManagement -ErrorAction Stop
  Connect-ExchangeOnline -ShowBanner:$false
  gravaLOG "Conectado ao Exchange Online" -tipo OK -arquivo $logs -mostraTempo:$true
}
catch {
  gravaLOG "Erro ao conectar ao Exchange Online: $($_.Exception.Message)" -tipo ERR -arquivo $logs -mostraTempo:$true
  Exit
}

$Usuarios = Import-Csv -Delimiter:";" -Path $arquivoEntrada

$totalUsuarios = $Usuarios.Count
$indice = 0

$Usuarios | ForEach-Object {
  $indice++
  gravaLOG $_.eMail "($indice/$totalUsuarios)" -tipo STP -arquivo $logs

  Set-Mailbox $_.eMail `
    -LitigationHoldEnabled $true `
    -LitigationHoldDuration 2551 # dias
}

$final = Get-Date
gravaLOG "Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()" -tipo WRN -arquivo $logs -mostraTempo:$true