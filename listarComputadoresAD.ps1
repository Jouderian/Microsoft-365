﻿#--------------------------------------------------------------------------------------------------------
# Descricao: Relacao de computadores do AD
# Versao 1 (06/02/23) Jouderian Nobre
# Versao 2 (18/03/24) Jouderian Nobre: Melhoria para extracao dos dados
# Versao 3 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
# Versao 4 (20/03/25) Jouderian Nobre: Incluindo a ultima alteração da maquina no AD
#--------------------------------------------------------------------------------------------------------

Clear-Host
Import-Module ActiveDirectory

$indice = 0
$inicio = Get-Date
$periodo = $inicio.AddDays(-90)
$situacao = ""
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\computadoresAD.csv"

Write-Host `n`n`n`n`n
Write-Host Inicio: $inicio
Write-Host Consultado computadores no AD...
$computadoresAD = Get-ADComputer -Filter * -Properties Name,LastLogonDate,Modified,OperatingSystem,OperatingSystemVersion,IPv4Address,IPv6Address,DNSHostName,DistinguishedName
$total = $computadoresAD.Count

Write-Output "Nome,ultimoAcesso,ultimaModificacao,sistemaOperacional,versaoSO,IPv4,IPv6,DNSHostName,nomeDistinto,situacao" > $arquivo

foreach ($computador in $computadoresAD){
  $indice++
  Write-Progress -Activity "Listando computadores" -Status "Progresso: $indice de $total catalogado" -PercentComplete ($indice / $total * 100)

#  $ultimoUsuario = Get-WinEvent -ComputerName $computador.Name -LogName Security -FilterXPath "*[System[EventID=4624]]" | Select-Object -First 1 -Property @{Name="User";Expression={$_.Properties[5].Value}}

if($computador.Modified -cgt $periodo){
  $situacao = "Normal"
} else {
  $situacao = "Expirado"
}
$nomeDistinto = [System.String]::Concat("""","$($computador.DistinguishedName)",""",",$situacao)

#  Echo "$($computador.Name),$($computador.LastLogonDate.ToString('dd/MM/yy HH:mm')),$($computador.OperatingSystem),$($computador.OperatingSystemVersion),$($computador.IPv4Address),$($computador.IPv6Address),$($computador.DNSHostName),$($nomeDistinto),$($ultimoUsuario.User)" >> $arquivo
  Write-Output "$($computador.Name),$($computador.LastLogonDate.ToString('dd/MM/yy HH:mm')),$($computador.Modified.ToString('dd/MM/yy HH:mm')),$($computador.OperatingSystem),$($computador.OperatingSystemVersion),$($computador.IPv4Address),$($computador.IPv6Address),$($computador.DNSHostName),$($nomeDistinto)" >> $arquivo
}

Write-Progress -Activity "Listando computadores" -PercentComplete 100

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()