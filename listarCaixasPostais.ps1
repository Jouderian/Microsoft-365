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
  22 (18/01/26) - Melhoria na validação das dependencias e remoção do campo "SenhaForte"
  23 (15/03/26) - Otimizando a busca de detalhes das caixas postais para reduzir o numero de chamadas ao msGraph
  24 (05/04/26) - Atualizacao da documentacao
  25 (31/05/26) - Otimizacao de altissima performance com pre-carga unica Graph/Exchange e gerenciamento otimizado de memoria
#>

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$indice = 0
$buffer = [System.Collections.Generic.List[string]]::new()
$detalheCredenciais = @{}
$licencasPorUPN = @{}
$gerentePorUPN = @{}
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaCaixasPostais_$($inicio.ToString('MMMyy')).txt"
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaDeCaixasPostais.csv"
$camposCaixa = @(
  'Id', 'Guid', 'DisplayName', 'UserPrincipalName', 'Office', 'RecipientTypeDetails', 'IsDirSynced',
  'AccountDisabled', 'IsShared', 'LitigationHoldEnabled', 'ArchiveStatus', 'ArchiveGuid', 'Alias',
  'ForwardingAddress', 'DeliverToMailboxAndForward'
)
$propriedadesGraph = @(
  'Id', 'UserPrincipalName', 'City', 'State', 'CompanyName', 'Department', 'JobTitle', 'PostalCode',
  'StreetAddress', 'PasswordPolicies', 'CreatedDateTime', 'LastPasswordChangeDateTime', 'OnPremisesLastSyncDateTime',
  'assignedLicenses'
)

gravaLOG "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))" -tipo WRN -arquivo $logs

# Validacoes
VerificaModulo -NomeModulo "Microsoft.Graph" -MensagemErro "O modulo Microsoft Graph e necessario e nao esta instalado no sistema." -arquivoLogs $logs
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema." -arquivoLogs $logs

gravaLOG "Conectando ao Microsoft 365..." -tipo INF -arquivo $logs
# Conexoes
try {
  Import-Module ExchangeOnlineManagement
  Connect-ExchangeOnline -ShowBanner:$false
} catch {
  gravaLOG -texto "Erro ao conectar ao Exchange Online: $($_.Exception.Message)" -tipo ERR -arquivo $logs -mostraTempo:$true
  Exit
}

try {
  Import-Module -Name Microsoft.Graph.Users
  Connect-MgGraph -Scopes "User.Read.All", "MailboxSettings.Read", "Directory.Read.All" -NoWelcome
} catch {
  gravaLOG -texto "Erro ao conectar ao Microsoft Graph: $($_.Exception.Message)" -tipo ERR -arquivo $logs -mostraTempo:$true
  Exit
}

#busca as caixas postais
gravaLOG -texto "Pesquisando relacao de caixas postais no ExchangeOnline..." -tipo INF -arquivo $logs -mostraTempo:$true
$Caixas = Get-EXOMailbox -ResultSize Unlimited -Properties $camposCaixa

$total = $caixas.Count

# Buscando as assinaturas do tenant para tradução das licenças
gravaLOG -texto "Buscando relacao de assinaturas contratadas (SKUs) no Graph..." -tipo INF -arquivo $logs -mostraTempo:$true
$skuMap = @{}
try {
  Get-MgSubscribedSku -All | ForEach-Object {
    $skuMap[$_.SkuId.ToString()] = $_.SkuPartNumber
  }
} catch {
  gravaLOG "Erro ao buscar assinaturas do Graph: $($_.Exception.Message)" -tipo WRN -arquivo $logs
}

# Buscando detalhes consolidados das caixas postais (cadastro, licenças e gerentes)
gravaLOG -texto "Buscando detalhes, licencas e gerentes das $($total) caixas postais encontradas..." -tipo INF -arquivo $logs -mostraTempo:$true
$detalhes = Get-MgUser -All -Property $propriedadesGraph -ExpandProperty manager
Foreach ($detalhe in $detalhes){
  if ($null -ne $detalhe.UserPrincipalName){
    $upnLower = $detalhe.UserPrincipalName.ToLower()
    $detalheCredenciais[$upnLower] = $detalhe
    if ($null -ne $detalhe.AssignedLicenses){
      $licencasPorUPN[$upnLower] = $detalhe.AssignedLicenses
    }
    
    $nomeGerente = ""
    if ($null -ne $detalhe.Manager){
      if ($null -ne $detalhe.Manager.AdditionalProperties -and $detalhe.Manager.AdditionalProperties.ContainsKey('displayName')){
        $nomeGerente = $detalhe.Manager.AdditionalProperties['displayName']
      } elseif ($null -ne $detalhe.Manager.DisplayName){
        $nomeGerente = $detalhe.Manager.DisplayName
      }
    }
    $gerentePorUPN[$upnLower] = $nomeGerente
  }
}
$detalhes = $null

gravaLOG -texto "Gravando caixas postais no arquivo $($arquivo)" -tipo INF -arquivo $logs -mostraTempo:$true
Out-File -FilePath $arquivo -InputObject "Nome,UPN,Cidade,UF,Empresa,Escritorio,Departamento,Cargo,Gerente,CC,nomeCC,Tipo,AD,Desabilitada,SenhaNaoExpira,Compartilhada,Encaminhada,Litigio,usado(GB),Arquivamento,Arquivamento(GB),Criacao,MudancaSenha,ultimoSyncAD,ultimoAcesso,conta,objectId,Licencas,outrasLicencas" -Encoding UTF8

Foreach ($caixa in $caixas){

  $indice++
  $caixaUPN = $caixa.UserPrincipalName.ToLower()
  $licencas = $licencasPorUPN[$caixaUPN]
  $detalheCaixa = Get-EXOMailboxStatistics -Identity $caixa.Guid -Properties LastInteractionTime, TotalItemSize
  $detalheCredencial = $detalheCredenciais[$caixaUPN]

  $tamanho = 0
  if ($null -ne $detalheCaixa -and $null -ne $detalheCaixa.TotalItemSize){
    try {
      $tamanho = [math]::Round((($detalheCaixa.TotalItemSize.Value.ToString()).Split('(')[1].Split(' ')[0].Replace(',', '') / 1GB), 2)
    } catch {
      $tamanho = 0
    }
  }
  $tamanhoArquivamento = 0

  if ($caixa.ArchiveStatus -eq 'Active'){
    $detalheArquivo = Get-EXOMailboxStatistics -Identity $caixa.Guid -Archive -Properties TotalItemSize
    if ($null -ne $detalheArquivo -and $null -ne $detalheArquivo.TotalItemSize){
      try {
        $tamanhoArquivamento = [math]::Round((($detalheArquivo.TotalItemSize.Value.ToString()).Split('(')[1].Split(' ')[0].Replace(',', '') / 1GB), 2)
      } catch {
        $tamanhoArquivamento = 0
      }
    }
  }

  $encaminhamento = "true"
  if ($null -eq $caixa.ForwardingAddress){
    $encaminhamento = "false"
  }

  $gerente = $gerentePorUPN[$caixaUPN]

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
  $senhaNaoExpira = "false"
  if ($null -ne $detalheCredencial -and $null -ne $detalheCredencial.passwordPolicies){
    $senhaNaoExpira = ($detalheCredencial.passwordPolicies -contains "DisablePasswordExpiration").ToString()
  }
  $infoCaixa += "$senhaNaoExpira," # SenhaNaoExpira
  $infoCaixa += "$($caixa.isShared)," # Compartilhada
  $infoCaixa += "$($encaminhamento)," # Encaminhada
  $infoCaixa += "$($caixa.litigationHoldEnabled)," # Litigio
  $infoCaixa += "$($tamanho)," # usado(GB)
  $infoCaixa += "$($caixa.archiveStatus)," # Arquivamento
  $infoCaixa += "$($tamanhoArquivamento)," # Arquivamento(GB)
  $infoCaixa += "$($detalheCredencial.createdDateTime.ToString('dd/MM/yy HH:mm'))," # Criacao

  $momento = ""
  if ($null -ne $detalheCredencial -and $null -ne $detalheCredencial.lastPasswordChangeDateTime){
    $momento = $detalheCredencial.lastPasswordChangeDateTime.ToString('dd/MM/yy HH:mm')
  }
  $infoCaixa += "$momento," # MudancaSenha

  $momento = ""
  if ($null -ne $detalheCredencial -and $null -ne $detalheCredencial.onPremisesLastSyncDateTime){
    $momento = $detalheCredencial.onPremisesLastSyncDateTime.ToString('dd/MM/yy HH:mm')
  }
  $infoCaixa += "$momento," # ultimoSyncAD

  $momento = ""
  if ($null -ne $detalheCaixa -and $null -ne $detalheCaixa.LastInteractionTime){
    $momento = $detalheCaixa.LastInteractionTime.ToString('dd/MM/yy HH:mm')
  }
  $infoCaixa += "$momento," # ultimoAcesso

  $infoCaixa += "$($caixa.Alias)," # conta
  $infoCaixa += "$($caixa.Guid)," # objectId

  $licencaPaga = ""
  $outrasLicencas = ""

  if ($null -ne $licencas){
    Foreach ($licenca in $licencas){
      if ($null -ne $licenca.SkuId){
        $skuIdStr = $licenca.SkuId.ToString()
        if ($skuMap.ContainsKey($skuIdStr)){
          $skuPart = $skuMap[$skuIdStr]
          $nomeLicenca = ObterDescricaoLicenca -SkuPartNumber $skuPart
          if ($null -eq $nomeLicenca){
            $outrasLicencas += "+$($skuPart)"
          } else {
            $licencaPaga += "+$($nomeLicenca)"
          }
        } else {
          $outrasLicencas += "+$($skuIdStr)"
        }
      }
    }
  }

  $infoCaixa += [System.String]::Concat('"', $licencaPaga, '",') # Licencas
  $infoCaixa += [System.String]::Concat('"', $outrasLicencas, '"') # outrasLicencas

  $buffer.Add($infoCaixa)

  if ($indice % 50 -eq 0 -or $indice -eq $total){
    Write-Progress -Activity "Exportando caixas postais" -Status "Progresso: $indice de $total extraidas" -PercentComplete (($indice / $total) * 100)
  }

  if ($indice % 250 -eq 0 -or $indice -eq $total){
    gravaLOG "Gravando $($indice) caixas postais. Parcial: $((NEW-TIMESPAN -Start $inicio -End (Get-Date)).ToString())" -tipo STP -arquivo $logs -mostraTempo:$true
  }

  if ($indice % 500 -eq 0 -or $indice -eq $total){
    Add-Content -Path $arquivo -Value $buffer -Encoding UTF8
    $buffer = [System.Collections.Generic.List[string]]::new()
  }
}

Write-Progress -Activity "Exportando caixas postais" -PercentComplete 100
gravaLOG "Terminada gravacao." -tipo INF -arquivo $logs -mostraTempo:$true

# Desconectando dos ambientes
Disconnect-ExchangeOnline -Confirm:$false
Disconnect-MgGraph
gravaLOG "Ambientes desconectados." -tipo INF -arquivo $logs -mostraTempo:$true

# Finalizando o script
$final = Get-Date
gravaLOG "Tempo de duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())" -tipo WRN -arquivo $logs -mostraTempo:$true