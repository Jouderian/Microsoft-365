#--------------------------------------------------------------------------------------------------------
# Descricao: Remove os computadores do AD baseado em uma listagem
# Versao 1 (18/03/24) Jouderian Nobre
# Versao 2 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
# Versao 3 (30/06/25) Jouderian Nobre: Otimizacao do script e melhoria nos logs
#--------------------------------------------------------------------------------------------------------

Clear-Host

# Declarando variaveis
$indice = 0
$bufferLog = @()
$inicio = Get-Date
$arquivoLog = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\computadoresRemovidosAD_$($inicio.ToString('yyMMdd_hhmmss')).txt"

Write-Host "`n`n`n`n`n"
Write-Host "$($inicio.ToString('dd/MM/yy HH:mm:ss')) - Abrindo lista de computadores para remover do AD..."

# Conexoes
Import-Module ActiveDirectory

# Importando a lista de computadores a serem removidos do AD
$computadoresAD = Import-Csv -Delimiter:";" -Path "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\removerComputadoresAD.csv"
$total = $computadoresAD.Count

foreach ($computador in $computadoresAD){
  $indice++
  Write-Progress -Activity "Removendo computadores do AD" -Status "Progresso: $indice de $total removidos" -PercentComplete ($indice / $total * 100)

  Try {
    $objetosFilhos = Get-ADObject -SearchBase $computador.nomeDistinto -Filter "*" -ErrorAction Stop
    if ($objetosFilhos.Count -gt 0){
      foreach ($objeto in $objetosFilhos){
        Try {
          Remove-ADObject -Identity $objeto.ObjectGUID -Confirm:$False -ErrorAction Stop
          $bufferLog += "$(Get-Date -Format 'dd/MM/yy HH:mm:ss') | $($computador.nomeDistinto).$($objeto.name) => Filho removido com sucesso"
        } Catch {
          $bufferLog += "$(Get-Date -Format 'dd/MM/yy HH:mm:ss') | $($computador.nomeDistinto).$($objeto.name) => ERRO Objeto Filho: $($_.Exception.Message)"
        }
      }
    }
  } Catch {
    $bufferLog += "$(Get-Date -Format 'dd/MM/yy HH:mm:ss') | $($computador.nomeDistinto) => ERRO ao buscar filhos: $($_.Exception.Message)"
  }

  Try {
    Remove-ADComputer -Identity $computador.nomeDistinto -Confirm:$False -ErrorAction Stop
    $bufferLog += "$(Get-Date -Format 'dd/MM/yy HH:mm:ss') | $($computador.nomeDistinto) => Removido com sucesso"
  } Catch {
    $bufferLog += "$(Get-Date -Format 'dd/MM/yy HH:mm:ss') | $($computador.nomeDistinto) => ERRO: $($_.Exception.Message)"
  }
}

Write-Progress -Activity "Removendo computadores do AD" -PercentComplete 100
$bufferLog | Out-File -FilePath $arquivoLog -Encoding UTF8

# Finalizando o script
$final = Get-Date
Write-Host "$($final.ToString('dd/MM/yy HH:mm:ss')) - Final => Duracao: $(($inicio - $final).TotalMinutes) minutos"