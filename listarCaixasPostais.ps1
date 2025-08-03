#--------------------------------------------------------------------------------------------------------
# Descricao: Extrair uma listagem com todas as caixas postais do Exchange (Microsoft 365)
# Versao 01 (03/11/22) Jouderian Nobre
# :::
# Versao 14 (08/01/25) Jouderian Nobre: Inclusao da ocupacao da caixa de arquivamento
# Versao 15 (10/01/25) Jouderian Nobre: Inclusao de novas licencas na relacao
# Versao 16 (17/01/25) Jouderian Nobre: Remocao da coluna itens da caixa postal
# Versao 17 (20/02/25) Jouderian Nobre: Inclusao da licenca PowerApps Premium
# Versao 18 (24/03/25) Jouderian Nobre: Adequacao para usar o MgGraph e seus comandos
# Versao 19 (14/04/25) Jouderian Nobre: Otimizacao do script com uso de funcoes
# Versao 20 (28/05/25) Jouderian Nobre: Portando o script para usar Get-EXOMailbox e melhoria nos logs
# Versao 21 (03/08/25) Jouderian Nobre: Otimizacao do script para melhorar a performance
#--------------------------------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$indice = 0
$buffer = @()
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaCaixasPostais_$($inicio.ToString('MMMyy')).txt"
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaDeCaixasPostais.csv"

gravaLOG -arquivo $logs -texto "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))"
gravaLOG -arquivo $logs -texto "Iniciando a exportacao de caixas postais do Microsoft 365..."

# Validacoes
VerificaModulo -NomeModulo "Microsoft.Graph" -MensagemErro "O modulo Microsoft Graph e necessario e nao esta instalado no sistema."
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema."

# Conexoes
try {
  Import-Module -Name Microsoft.Graph.Users
  Connect-MgGraph -Scopes "User.Read.All", "MailboxSettings.Read", "Directory.Read.All" -NoWelcome
} catch {
  gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Erro ao conectar ao Microsoft Graph: $($_.Exception.Message)" -erro:$true
  Exit
}

try {
  Import-Module ExchangeOnlineManagement
  Connect-ExchangeOnline -ShowBanner:$false
} catch {
  gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Erro ao conectar ao Exchange Online: $($_.Exception.Message)" -erro:$true
  Exit
}

#busca as caixas postais
gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Pesquisando Relacao de Caixas Postais no ExchangeOnline..."
$Caixas = Get-EXOMailbox -ResultSize Unlimited -PropertySets All | Select-Object Id, Guid, DisplayName, UserPrincipalName, Office, RecipientTypeDetails, IsDirSynced, AccountDisabled, IsShared, LitigationHoldEnabled, ArchiveStatus, ArchiveGuid, Alias
$total = $caixas.Count

gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Gravando $($total) caixas postais no arquivo $($arquivo)"
Out-File -FilePath $arquivo -InputObject "Nome,UPN,Cidade,UF,Empresa,Escritorio,Departamento,Cargo,Gerente,CC,nomeCC,Tipo,AD,Desabilitada,SenhaForte,SenhaNaoExpira,Compartilhada,Encaminhada,Litigio,usado(GB),Arquivamento,Arquivamento(GB),Criacao,MudancaSenha,ultimoSyncAD,ultimoAcesso,conta,objectId,Licencas,outrasLicencas" -Encoding UTF8

Foreach ($caixa in $caixas){

  $indice++

  $licencas = Get-MgUserLicenseDetail -UserId $caixa.UserPrincipalName

  $detalheCaixa = Get-EXOMailboxStatistics -Identity $caixa.Guid -PropertySets All -Properties LastInteractionTime, TotalItemSize

  $detalheCredencial = Get-MgUser `
    -UserId $caixa.UserPrincipalName `
    -Property Id, DisplayName, City, State, CompanyName, Department, JobTitle, PostalCode, StreetAddress, PasswordPolicies, CreatedDateTime, LastPasswordChangeDateTime, OnPremisesLastSyncDateTime

  $tamanho = [math]::Round((($detalheCaixa.TotalItemSize.Value.ToString()).Split('(')[1].Split(' ')[0].Replace(',','')/1GB),2)
  $tamanhoArquivamento = 0

  if($caixa.ArchiveStatus -eq 'Active'){
    $detalheArquivo = Get-EXOMailboxStatistics -Identity $caixa.Guid  -Archive -PropertySets All -Properties TotalItemSize
    $tamanhoArquivamento = [math]::Round((($detalheArquivo.TotalItemSize.Value.ToString()).Split('(')[1].Split(' ')[0].Replace(',','')/1GB),2)
  }

  $encaminhamento = "true"
  if($null -eq $caixa.ForwardingAddress){
    $encaminhamento = "false"
  }

  try {
    $gerente = Get-MgUserManager -UserId $caixa.UserPrincipalName
    $gerente = $gerente.AdditionalProperties.displayName
  } catch {
    $gerente = ""
  }

  $infoCaixa = "$($caixa.DisplayName)," # Nome
  $infoCaixa += "$($caixa.UserPrincipalName)," # UPN
  $infoCaixa += "$($detalheCredencial.City)," # Cidade
  $infoCaixa += "$($detalheCredencial.State)," # UF
  $infoCaixa += "$($detalheCredencial.CompanyName)," # Empresa
  $infoCaixa += "$($caixa.Office)," # Escritorio
  $infoCaixa += [System.String]::Concat('"',$detalheCredencial.Department,'",') # Departamento
  $infoCaixa += [System.String]::Concat('"',$detalheCredencial.JobTitle,'",') # Cargo
  $infoCaixa += "$($gerente)," #Gerente
  $infoCaixa += "$($detalheCredencial.postalCode)," # CC
  $infoCaixa += "$($detalheCredencial.streetAddress)," # nomeCC
  $infoCaixa += "$($caixa.RecipientTypeDetails)," # Tipo
  $infoCaixa += "$($caixa.IsDirSynced)," # AD
  $infoCaixa += "$($caixa.AccountDisabled)," # Desabilitada
  $infoCaixa += "$($detalheCredencial.PasswordPolicies -contains "DisableStrongPassword")," # SenhaForte
  $infoCaixa += "$($detalheCredencial.PasswordPolicies -contains "DisablePasswordExpiration")," # SenhaNaoExpira
  $infoCaixa += "$($caixa.IsShared)," # Compartilhada
  $infoCaixa += "$($encaminhamento)," # Encaminhada
  $infoCaixa += "$($caixa.LitigationHoldEnabled)," # Litigio
  $infoCaixa += "$($tamanho)," # usado(GB)
  $infoCaixa += "$($caixa.ArchiveStatus)," # Arquivamento
  $infoCaixa += "$($tamanhoArquivamento)," # Arquivamento(GB)
  $infoCaixa += "$($detalheCredencial.CreatedDateTime.ToString('dd/MM/yy HH:mm'))," # Criacao
  $infoCaixa += "$($detalheCredencial.LastPasswordChangeDateTime.ToString('dd/MM/yy HH:mm'))," # MudancaSenha

  $momento = $detalheCredencial.OnPremisesLastSyncDateTime # ultimoSyncAD
  if($null -eq $momento){
    $infoCaixa += ","
  } Else {
    $infoCaixa += "$($momento.ToString('dd/MM/yy HH:mm')),"
  }

  $momento = $detalheCaixa.LastInteractionTime # ultimoAcesso
  if($null -eq $momento){
    $infoCaixa += ","
  } Else {
    $infoCaixa += "$($momento.ToString('dd/MM/yy HH:mm')),"
  }

  $infoCaixa += "$($caixa.Alias)," # conta
  $infoCaixa += "$($caixa.Guid)," # objectId

  $licencaPaga = ""
  $outrasLicencas = ""

  Foreach ($licenca in $licencas){
    $nomeLicenca = ObterDescricaoLicenca -SkuPartNumber $licenca.SkuPartNumber
    if($null -eq $nomeLicenca){
      $outrasLicencas += "+$($licenca.SkuPartNumber)"
    } else {
      $licencaPaga += "+$($nomeLicenca)"
    }
  }
  $infoCaixa += [System.String]::Concat('"',$licencaPaga,'",') # Licencas
  $infoCaixa += [System.String]::Concat('"',$outrasLicencas,'"') # outrasLicencas

  $buffer += $infoCaixa

  # Atualiza a cada 50 caixas processadas
  if (
    $indice % 250 -eq 0 -or
    $indice -eq $total
  ){
    Write-Progress -Activity "Exportando caixas postais" -Status "Progresso: $indice de $total extraidas" -PercentComplete (($indice / $total) * 100)
    Add-Content -Path $arquivo -Value $buffer -Encoding UTF8
    $buffer = @()

    if (
      $indice % 500 -eq 0 -or
      $indice -eq $total
    ){
      gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Gravando $($indice) caixas postais. Parcial: $((NEW-TIMESPAN -Start $inicio -End (Get-Date)).ToString())"
    }
  }
}

Write-Progress -Activity "Exportando caixas postais" -PercentComplete 100
gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Terminada gravacao."

# Desconectando dos ambientes
Disconnect-ExchangeOnline -Confirm:$false
Disconnect-MgGraph -Confirm:$false

# Finalizando o script
gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Ambientes desconectados."
$final = Get-Date
gravaLOG -arquivo $logs -texto "$($final.ToString('dd/MM/yy HH:mm:ss')) - Tempo de duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())"