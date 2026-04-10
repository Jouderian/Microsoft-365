<#
  .SYNOPSIS
    Ajusta as credenciais do AD cujo o UPN esta diferente do SMTP no proxyAddresses
  .DESCRIPTION
    Este script ajusta as credenciais do AD cujo o UPN esta diferente do SMTP no proxyAddresses
  .AUTHOR
    Jouderian Nobre
  .CREATED
    08/04/26
  .VERSION
    1 (08/04/26) - Otimizacao de codigo
  .OUTPUT
    Arquivo CSV com os usuarios que tiveram o SMTP ajustado e Log com o resumo da execucao
#>

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$inicio = Get-Date
$mensagem = "Ajuste do SMTP conflitante com o UPN em $($inicio.ToString('dd/MM/yy HH:mm'))"
$arquivoUsuarios = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\usuariosDivergentesUPN_SMTP.csv"
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\usuariosDivergentesUPN_SMTP_$((Get-Date).ToString('yymmdd_MMHH')).txt"
$contadores = @{
  Total       = 0
  Divergentes = 0
}

gravaLOG "Iniciando o ajuste dos eMails..." -tipo WRN -mostraTempo $true -arquivo $logs

VerificaModulo -NomeModulo "ActiveDirectory" -MensagemErro "O módulo Active Directory é necessário e não está instalado no sistema."
Try {
  Import-Module ActiveDirectory -ErrorAction Stop
}
Catch {
  gravaLOG "Erro ao conectar ao Active Directory: $($_.Exception.Message)" -tipo ERR -mostraTempo $true -arquivo $logs
  Exit
}

gravaLOG "Buscando usuarios com divergencia entre UPN e SMTP..." -tipo INF -mostraTempo $true -arquivo $logs

# Busca todas as credenciais habilitadas no AD
$usuarios = Get-ADUser `
  -Filter "POBox -eq 'O365'" `
  -Properties SamAccountName, DisplayName, DistinguishedName, UserPrincipalName, EmailAddress, proxyAddresses, POBox, info

$contadores.Total = $usuarios.Count

# Cria arquivo CSV com cabeçalho
Out-File -FilePath $arquivoUsuarios -InputObject "DistinguishedName,UserPrincipalName,proxyAddresses,smtpPrincipal,novosProxies,info" -Encoding UTF8

foreach ($usuario in $usuarios) {

  $smtpPrincipal = ($usuario.proxyAddresses | Where-Object { $_ -cmatch "^SMTP:" }) -replace "SMTP:", ""
  if (-not $smtpPrincipal) {
    continue
  }

  $novosProxies = $usuario.proxyAddresses | ForEach-Object { $_.ToLower() }
  $novosProxies = $novosProxies | Where-Object { $_.trim() -ne "smtp:$($usuario.UserPrincipalName)" }
  $novosProxies = $novosProxies | ForEach-Object { [string]$_ }
  $novosProxies = @($novosProxies)

  if ($usuario.UserPrincipalName -ne $smtpPrincipal) {

    $observacao = "$($usuario.info)`r`n$($mensagem)"

    Out-File -FilePath $arquivoUsuarios -InputObject  "$($usuario.DistinguishedName -replace ',', '/'),$($usuario.UserPrincipalName),$($usuario.proxyAddresses -join ' / '),$($smtpPrincipal -join ' / '),$($novosProxies -join ' / '),$($observacao)" -Encoding UTF8 -append

    # Atualiza credencial
    Set-ADUser `
      -Identity $usuario.DistinguishedName `
      -Country "BR" `
      -Replace @{
      proxyAddresses = $novosProxies;
      info           = $observacao
    }

    $contadores.Divergentes++
  }
}

# Grava resumo no log
$final = Get-Date
gravaLOG "[RESUMO] Total: $($contadores.Total) / Divergencias: $($contadores.Divergentes) => Duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())" -tipo WRN -arquivo $logs
gravaLOG "Arquivo gerado em: $($arquivoUsuarios)" -tipo INF -mostraTempo $true -arquivo $logs