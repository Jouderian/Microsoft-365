<#
  .SYNOPSIS
    Importa os membros para uma lista de distribuição
  .DESCRIPTION
    O script se conecta ao Exchange Online e adiciona em massa os endereços de e-mail lidos de um arquivo TXT a uma lista de distribuição informada interativamente.
  .AUTHOR
    Jouderian Nobre
  .VERSION
    01 (27/08/25) - Criacao do script
    02 (05/04/26) - Atualizacao da documentacao
  .OUTPUT
    Saída no console confirmando cada membro adicionado com sucesso ou reportando erros.
#>

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$listaDistribuicao = Read-Host "Informe o eMail da Lista de Distribuicao"
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\eMails.txt"

# Validacoes
. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

# Conectar ao Exchange Online
try {
  Import-Module ExchangeOnlineManagement
  Connect-ExchangeOnline -ShowBanner:$false
}
catch {
  Write-Host "Erro ao conectar o Exchange: $($_.Exception.Message)" -ForegroundColor Red
  Exit
}

# Ler os eMails do CSV
$membros = Import-Csv -Path $arquivo

# Adicionar cada eMail à lista de distribuição
f
reach ($membro in $membros) {
  try {
    tryte $listaDistribuicao -Member $membro.eMail
    Write-Host "Adicionado: $($membro.eMail)" -ForegroundColor Green
  }
  catchnn
  Write-Host "Erro ao adicionar: $($membro.eMail) - $($_.Exception.Message)" -ForegroundColor Red
}
}

# Desconectar do Exchange Online
Disconnect-ExchangeOnline -Confirm:$falseect-ExchangeOnline -Confirm:$false
} catch {
  Write-Host "Erro ao adicionar: $($membro.eMail) - $($_.Exception.Message)" -ForegroundColor Red
}
}

# Desconectar do Exchange Online
Disconnect-ExchangeOnline -Confirm:$falseect-ExchangiOnlinr -Comfirm:$false:$false