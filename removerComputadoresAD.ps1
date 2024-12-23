﻿# Descricao: Remove os computadores do AD baseado em uma listagem
# Versao 01 (18/03/24) - Jouderian Nobre
#--------------------------------------------------------------------------------------------------------

Clear-Host
Import-Module ActiveDirectory

$indice = 0
$inicio = Get-Date
$arquivoLog = "C:\Users\jouderian.nobre\OneDrive\Documentos\WindowsPowerShell\computadoresRemovidosAD_" + (Get-date -Uformat "%Y%m%d_%M%H") + ".txt"

Write-Host `n`n`n`n`n
Write-Host Inicio: $inicio
Write-Host Abrindo lista de computadores para remover do AD...

$computadoresAD = Import-Csv -Delimiter:";" -Path "C:\Users\jouderian.nobre\OneDrive\Documentos\WindowsPowerShell\removerComputadoresAD.csv"
$total = $computadoresAD.Count

foreach ($computador in $computadoresAD){
  $indice++
  Write-Progress -Activity "Removendo computadores do AD" -Status "Progresso: $indice de $total removidos" -PercentComplete ($indice / $total * 100)

  $objetosFilhos = Get-ADObject -SearchBase $computador.nomeDistinto -Filter "*"

  foreach ($objeto in $objetosFilhos){
    Try {
      Remove-ADObject -Identity $objeto.ObjectGUID -Confirm:$False
      Echo "R$($computador.nomeDistinto).$($objeto.name) => Filho removido com sucesso" >> $arquivoLog
    } Catch {
      Echo "$($computador.nomeDistinto).$($objeto.name) => ERRO Objeto Filho: $($_)" >> $arquivoLog
    }
  }

  Try {
    Remove-ADComputer -Identity $computador.nomeDistinto -Confirm:$False
    Echo "$($computador.nomeDistinto) => Removido com sucesso" >> $arquivoLog
  } Catch {
    Echo "$($computador.nomeDistinto) => ERRO: $($_)" >> $arquivoLog
  }
}

Write-Progress -Activity "Removendo computadores do AD" -PercentComplete 100

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()