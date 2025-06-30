#--------------------------------------------------------------------------------------------------------
# Autor: Jouderian Nobre
# Descricao: Ajusta as credenciais do AD cujo o UPN esta diferente do SMTP no proxyAddresses
# Versao: 1 (24/06/25) Jouderian Nobre
#--------------------------------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$inicio = Get-Date
$mensagem = "Ajuste do SMTP conflitante com o UPN em $($inicio.ToString('dd/MM/yy HH:mm'))"
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\usuariosDivergentesUPN_SMTP_$((Get-Date).ToString('yymmdd_MMHH')).txt"
$contadores = @{
  Total = 0
  Divergentes = 0
}

gravaLOG -arquivo $logs -texto "$($inicio.ToString('dd/MM/yy HH:mm:ss')) - Iniciando o ajuste dos eMails..."

# Validando e conectando ao Microsoft Graph
VerificaModulo -NomeModulo "ActiveDirectory" -MensagemErro "O módulo Active Directory é necessário e não está instalado no sistema."

gravaLOG -arquivo $logs -texto "$($inicio.ToString('dd/MM/yy HH:mm:ss')) - Buscando usuarios com divergencia entre UPN e SMTP..."

# Busca todas as credenciais habilitadas no AD
$usuarios = Get-ADUser `
  -Filter "POBox -eq 'O365'" `
  -Properties SamAccountName, DisplayName, DistinguishedName, UserPrincipalName, EmailAddress, proxyAddresses, POBox, info

$contadores.Total = $usuarios.Count

# Cria arquivo CSV com cabeçalho
gravaLOG -arquivo $logs -texto "DistinguishedName,UserPrincipalName,proxyAddresses,smtpPrincipal,novosProxies,info"

foreach ($usuario in $usuarios){

  $smtpPrincipal = ($usuario.proxyAddresses | Where-Object { $_ -cmatch "^SMTP:" }) -replace "SMTP:",""
  if (-not $smtpPrincipal){
    continue
  }

  $novosProxies = $usuario.proxyAddresses | ForEach-Object { $_.ToLower() }
  $novosProxies = $novosProxies | Where-Object { $_.trim() -ne "smtp:$($usuario.UserPrincipalName)" }
  $novosProxies = $novosProxies | ForEach-Object { [string]$_ }
  $novosProxies = @($novosProxies)

  if ($usuario.UserPrincipalName -ne $smtpPrincipal){

    $observacao = "$($usuario.info)`r`n$($mensagem)"

    gravaLOG -arquivo $logs -texto "$($usuario.DistinguishedName -replace ',', '/'),$($usuario.UserPrincipalName),$($usuario.proxyAddresses -join ' / '),$($smtpPrincipal -join ' / '),$($novosProxies -join ' / '),$($observacao)"

    # Atualiza credencial
    Set-ADUser `
      -Identity $usuario.DistinguishedName `
      -Replace @{
        proxyAddresses = $novosProxies;
        info = $observacao
      } `
      -Country "BR"

    $contadores.Divergentes++
  }
}

# Grava resumo no log
$final = Get-Date
gravaLOG -arquivo $logs -texto "[RESUMO] Total: $($contadores.Total) / Divergencias: $($contadores.Divergentes) => Duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())"
gravaLOG -arquivo $logs -texto "Arquivo gerado em: $($logs)"