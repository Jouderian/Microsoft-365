#--------------------------------------------------------------------------------------------------------
# Descricao: Muda o nome da credencial e seu eMail
# Versao 1 (30/01/25) Jouderian Nobre
#--------------------------------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

$indice = 0
$inicio = Get-Date
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\mudancaNomes_" + (Get-date -Uformat "%Y%m%d_%M%H") + ".txt"

Write-Host "`n`n`n`n`n`n`nInicio:" $inicio
Write-Host Selecionando credenciais...

$credenciais = Import-Csv -Delimiter:";" -Path "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\credenciais.csv"
$total = $credenciais.Count

foreach ($credencial in $credenciais){
  $indice++
  Write-Progress -Activity "Mudanco o nome das credenciais" -Status "Progresso: $indice de $total mudado" -PercentComplete ($indice / $total * 100)

  # Obtenha os valores do CSV
  $samAccountNameAtual = $usuario.SamAccountNameAtual
  $upnAtual = $usuario.UPNAtual
  $novoSamAccountName = $usuario.NovoSamAccountName
  $novoUPN = $usuario.NovoUPN

  # Atualize o SamAccountName e o UPN
  Set-ADUser -Identity $samAccountNameAtual -SamAccountName $novoSamAccountName -UserPrincipalName $novoUPN

  # Adicione um apelido para o antigo UPN
  Set-ADUser -Identity $novoSamAccountName -Add @{proxyAddresses="smtp:$upnAtual"}

}