#--------------------------------------------------------------------------------------------------------
# Descricao: Importa os membros para uma lista de distribuição
# Versao 1 (27/08/25) Jouderian Nobre
#--------------------------------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$listaDistribuicao = Read-Host "Informe o eMail da Lista de Distribuicao"
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\eMails.txt"

# Validacoes
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema."

# Conectar ao Exchange Online
try {
  Import-Module ExchangeOnlineManagement
  Connect-ExchangeOnline -ShowBanner:$false
} catch {
  Write-Host "Erro ao conectar o Exchange: $($_.Exception.Message)" -ForegroundColor Red
  Exit
}

# Ler os eMails do CSV
$membros = Import-Csv -Path $arquivo

# Adicionar cada eMail à lista de distribuição
foreach ($membro in $membros){
  try {
    Add-DistributionGroupMember -Identity $listaDistribuicao -Member $membro.eMail
    Write-Host "Adicionado: $($membro.eMail)" -ForegroundColor Green
  } catch {
    Write-Host "Erro ao adicionar: $($membro.eMail) - $($_.Exception.Message)" -ForegroundColor Red
  }
}

# Desconectar do Exchange Online
Disconnect-ExchangeOnline -Confirm:$false