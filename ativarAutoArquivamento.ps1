#--------------------------------------------------------------------------------------------------------
# Descricao: Ativar o autoarquivamento das caixas postais
# Versao 1 (02/02/22) - Jouderian Nobre: Criacao do script
# Versao 2 (28/10/24) - Jouderian Nobre: Melhoria no processamento e registro de acoes
# Versao 3 (29/12/24) - Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
#--------------------------------------------------------------------------------------------------------

$indice = 0
$inicio = Get-Date
$arquivoEntrada = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\eMails.txt"

Clear-Host
Connect-ExchangeOnline

Write-Host "`n`n`n`n`n`n`nInicio:" $inicio
$caixasPostais = Import-Csv -Delimiter:";" -Path $arquivoEntrada
$totalCaixasPostais = $caixasPostais.Count

Foreach ($caixaPostal in $caixasPostais){
  $indice++

  Write-Progress -Activity "Atualizando credenciais" -Status "Progresso: $indice de $totalCaixasPostais atualizados" -PercentComplete (($indice / $totalCaixasPostais) * 100)

  Enable-Mailbox -Identity $caixaPostal.eMail -Archive
  Enable-Mailbox -Identity $caixaPostal.eMail -AutoExpandingArchive
}

Write-Progress -Activity "Atualizando credenciais" -PercentComplete 100

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()