#--------------------------------------------------------------------------------------------------------
# Autor: Jouderian Nobre
# Descricao: Ativar o autoarquivamento das caixas postais
# Versao: 1 - 02/02/22 (Jouderian): Criacao do script
# Versao: 2 - 28/10/24 (Jouderian): Melhoria no processamento e registro de acoes
#--------------------------------------------------------------------------------------------------------

$indice = 0
$inicio = Get-Date

Clear-Host
Connect-ExchangeOnline

Write-Host "`n`n`n`n`n`n`nInicio:" $inicio
$caixasPostais = Import-Csv -Delimiter:";" -Path C:\Users\jouderian.nobre\OneDrive\Documentos\WindowsPowerShell\eMails.txt
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