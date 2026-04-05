<#
.SYNOPSIS
  Extrai uma listagem com todas as caixas postais do Exchange (Microsoft 365).
.DESCRIPTION
  O script se conecta ao ambiente do Microsoft 365, busca todas as caixas postais existentes e extrai uma série de informações sobre cada caixa postal, como nome, UPN, cidade, empresa, tipo, tamanho utilizado, entre outros. As informações são gravadas em um arquivo CSV para análise posterior.
.AUTHOR
  Jouderian Nobre
.VERSION
  01 (03/11/22) - Criacao do script
  :::
  14 (08/01/25) - Inclusao da ocupacao da caixa de arquivamento
  15 (10/01/25) - Inclusao de novas licencas na relacao
  16 (17/01/25) - Remocao da coluna itens da caixa postal
  17 (20/02/25) - Inclusao da licenca PowerApps Premium
  18 (24/03/25) - Adequacao para usar o MgGraph e seus comandos
  19 (14/04/25) - Otimizacao do script com uso de funcoes
  20 (28/05/25) - Portando o script para usar Get-EXOMailbox e melhoria nos logs
  21 (03/08/25) - Otimizacao do script para melhorar a performance
  22 (18/01/26) - Melhoria na validação das dependencias e remoção do campo "SenhaForte"
  23 (15/03/26) - Otimizando a busca de detalhes das caixas postais para reduzir o numero de chamadas ao msGraph
  24 (05/04/26) - Atualizacao da documentacao
#>
. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$indice = 0
$buffer = @()
$detalheCredenciais = @{}
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaCaixasPostais_$($inicio.ToString('MMMyy')).txt"
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaDeCaixasPostais.csv"
$camposCaixa = @(
  'Id', 'Guid', 'DisplayName', 'UserPrincipalName', 'Office', 'RecipientTypeDetails', 'IsDirSynced',
  'AccountDisabled', 'IsShared', 'LitigationHoldEnabled', 'ArchiveStatus', 'ArchiveGuid', 'Alias'
)
$camposDetalhesCaixa = @(
  'Id', 'UserPrincipalName', 'City', 'State', 'CompanyName', 'Department', 'JobTitle', 'PostalCode',
  'StreetAddress', 'PasswordPolicies', 'CreatedDateTime', 'LastPasswordChangeDateTime', 'OnPremisesLastSyncDateTime'
)

gravaLOG -texto "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))" -tipo WRN -arquivo $logs -mostraTempo:$true
gravaLOG -texto "Conectando ao Microsoft 365..." -arquivo $logs

# Validacoes
VerificaModulo -NomeModulo "Microsoft.Graph" -MensagemErro "O modulo Microsoft Graph e necessario e nao esta instalado no sistema." -arquivoLogs $logs
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema." -arquivoLogs $logs

# Conexoes
try {
  Import-Module ExchangeOnlineManagement
  Connect-ExchangeOnline -ShowBanner:$false
}
catch {
  gravaLOG -texto "Erro ao conectar ao Exchange Online: $($_.Exception.Message)" -tipo ERR -arquivo $logs -mostraTempo:$true
  Exit
}

try {
  Import-Module -Name Microsoft.Graph.Users
  Connect-MgGraph -Scopes "User.Read.All", "MailboxSettings.Read", "Directory.Read.All" -NoWelcome
}
catch {
  gravaLOG -texto "Erro ao conectar ao Microsoft Graph: $($_.Exception.Message)" -tipo ERR -arquivo $logs -mostraTempo:$true
  Exit
}

#busca as caixas postais
gravaLOG -texto "Pesquisando relacao de caixas postais no ExchangeOnline..." -tipo INF -arquivo $logs -mostraTempo:$true
$Caixas = Get-EXOMailbox -ResultSize Unlimited -PropertySets All | Select-Object $camposCaixa

$total = $caixas.Count

#buscando detalhes das caixas postais
gravaLOG -texto "Buscando detalhes das $($total) caixas postais encontradas..." -tipo INF -arquivo $logs -mostraTempo:$true
$detalhe = Get-MgUser -All -Property $camposDetalhesCaixa
Foreach ($caixa in $detalhe) {
  $detalheCredenciais[$caixa.UserPrincipalName.ToLower()] = $caixa
}
$detalhe = $null

gravaLOG -texto "Gravando caixas postais no arquivo $($arquivo)" -tipo INF -arquivo $logs -mostraTempo:$true
Out-File -FilePath $arquivo -InputObject "Nome,UPN,Cidade,UF,Empresa,Escritorio,Departamento,Cargo,Gerente,CC,nomeCC,Tipo,AD,Desabilitada,SenhaNaoExpira,Compartilhada,Encaminhada,Litigio,usado(GB),Arquivamento,Arquivamento(GB),Criacao,MudancaSenha,ultimoSyncAD,ultimoAcesso,conta,objectId,Licencas,outrasLicencas" -Encoding UTF8

Foreach ($caixa in $caixas) {

  $indice++
  $licencas = Get-MgUserLicenseDetail -UserId $caixa.UserPrincipalName
  $detalheCaixa = Get-EXOMailboxStatistics -Identity $caixa.Guid -PropertySets All -Properties LastInteractionTime, TotalItemSize
  $detalheCredencial = $detalheCredenciais[$caixa.UserPrincipalName.ToLower()]

  $tamanho = [math]::Round((($detalheCaixa.TotalItemSize.Value.ToString()).Split('(')[1].Split(' ')[0].Replace(',', '') / 1GB), 2)
  $tamanhoArquivamento = 0

  if ($caixa.ArchiveStatus -eq 'Active') {
    $detalheArquivo = Get-EXOMailboxStatistics -Identity $caixa.Guid  -Archive -PropertySets All -Properties TotalItemSize
    $tamanhoArquivamento = [math]::Round((($detalheArquivo.TotalItemSize.Value.ToString()).Split('(')[1].Split(' ')[0].Replace(',', '') / 1GB), 2)
  }

  $encaminhamento = "true"
  if ($null -eq $caixa.ForwardingAddress) {
    $encaminhamento = "false"
  }

  try {
    $gerente = Get-MgUserManager -UserId $caixa.UserPrincipalName
    $gerente = $gerente.AdditionalProperties.displayName
  }
  catch {
    $gerente = ""
  }

  $infoCaixa = "$($caixa.displayName)," # Nome
  $infoCaixa += "$($caixa.userPrincipalName)," # UPN
  $infoCaixa += "$($detalheCredencial.City)," # Cidade
  $infoCaixa += "$($detalheCredencial.State)," # UF
  $infoCaixa += "$($detalheCredencial.CompanyName)," # Empresa
  $infoCaixa += "$($caixa.Office)," # Escritorio
  $infoCaixa += [System.String]::Concat('"', $detalheCredencial.Department, '",') # Departamento
  $infoCaixa += [System.String]::Concat('"', $detalheCredencial.jobTitle, '",') # Cargo
  $infoCaixa += "$($gerente)," #Gerente
  $infoCaixa += "$($detalheCredencial.postalCode)," # CC
  $infoCaixa += "$($detalheCredencial.streetAddress)," # nomeCC
  $infoCaixa += "$($caixa.recipientTypeDetails)," # Tipo
  $infoCaixa += "$($caixa.isDirSynced)," # AD
  $infoCaixa += "$($caixa.accountDisabled)," # Desabilitada
  $infoCaixa += "$($detalheCredencial.passwordPolicies -contains "DisablePasswordExpiration")," # SenhaNaoExpira
  $infoCaixa += "$($caixa.isShared)," # Compartilhada
  $infoCaixa += "$($encaminhamento)," # Encaminhada
  $infoCaixa += "$($caixa.litigationHoldEnabled)," # Litigio
  $infoCaixa += "$($tamanho)," # usado(GB)
  $infoCaixa += "$($caixa.archiveStatus)," # Arquivamento
  $infoCaixa += "$($tamanhoArquivamento)," # Arquivamento(GB)
  $infoCaixa += "$($detalheCredencial.createdDateTime.ToString('dd/MM/yy HH:mm'))," # Criacao
  $infoCaixa += "$($detalheCredencial.lastPasswordChangeDateTime.ToString('dd/MM/yy HH:mm'))," # MudancaSenha

  $momento = $detalheCredencial.onPremisesLastSyncDateTime # ultimoSyncAD
  if ($null -eq $momento) {
    $infoCaixa += ","
  }
  else {
    $infoCaixa += "$($momento.ToString('dd/MM/yy HH:mm')),"
  }

  $momento = $detalheCaixa.LastInteractionTime # ultimoAcesso
  if ($null -eq $momento) {
    $infoCaixa += ","
  }
  else {
    $infoCaixa += "$($momento.ToString('dd/MM/yy HH:mm')),"
  }

  $infoCaixa += "$($caixa.Alias)," # conta
  $infoCaixa += "$($caixa.Guid)," # objectId

  $licencaPaga = ""
  $outrasLicencas = ""

  Foreach ($licenca in $licencas) {
    $nomeLicenca = ObterDescricaoLicenca -SkuPartNumber $licenca.SkuPartNumber
    if ($null -eq $nomeLicenca) {
      $outrasLicencas += "+$($licenca.SkuPartNumber)"
    }
    else {
      $licencaPaga += "+$($nomeLicenca)"
    }
  }
  $infoCaixa += [System.String]::Concat('"', $licencaPaga, '",') # Licencas
  $infoCaixa += [System.String]::Concat('"', $outrasLicencas, '"') # outrasLicencas

  $buffer += $infoCaixa

  if (
    $indice % 50 -eq 0 -or
    $indice -eq $total
  ) {
    Write-Progress -Activity "Exportando caixas postais" -Status "Progresso: $indice de $total extraidas" -PercentComplete (($indice / $total) * 100)
  }

  if (
    $indice % 250 -eq 0 -or
    $indice -eq $total
  ) {
    gravaLOG -texto "Gravando $($indice) caixas postais. Parcial: $((NEW-TIMESPAN -Start $inicio -End (Get-Date)).ToString())" -tipo INF -arquivo $logs -mostraTempo:$true
  }
  if (
    $indice % 500 -eq 0 -or
    $indice -eq $total
  ) {
    Add-Content -Path $arquivo -Value $buffer -Encoding UTF8
    $buffer = @()
  }

}  

Write-Progress -Activity "Exportando caixas postais" -PercentComplete 100
gravaLOG -texto "Terminada gravacao." -tipo Aviso -arquivo $logs -mostraTempo:$true

# Desconectando dos ambientes
Disconnect-ExchangeOnline -Confirm:$false
Disconnect-MgGraph
gravaLOG -texto "Ambientes desconectados." -tipo INF -arquivo $logs -mostraTempo:$true

# Finalizando o script
$final = Get-Date
gravaLOG -texto "Tempo de duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())" -tipo WRN -arquivo $logs -mostraTempo:$true