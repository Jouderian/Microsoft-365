#--------------------------------------------------------------------------------------------------------
# Descricao: Script para ativar o litigio nas caixas postais com licenças: Office 365 E3 e Business Premium
# Versao 1 (23/06/23) Jouderian Nobe
# Versao 2 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
# Versao 3 (28/06/25) Jouderian Nobre: Adequando ao uso da biblioteca de funcoes
#--------------------------------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$inicio = Get-Date
$arquivoEntrada = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\credenciaisLitigio.csv"

# Validacoes
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema."
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-ExchangeOnline -ShowBanner:$false

Write-Host Inicio: $inicio
Write-Host Importantdo relação de caixas postais...
$Usuarios = Import-Csv -Delimiter:";" -Path $arquivoEntrada

$totalUsuarios = $Usuarios.Count
$indice = 0

$Usuarios | ForEach-Object {
  $indice++
  Write-Host $_.eMail "($indice/$totalUsuarios)"

  Set-Mailbox $_.eMail `
    -LitigationHoldEnabled $true `
    -LitigationHoldDuration 2551 # dias
}

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()