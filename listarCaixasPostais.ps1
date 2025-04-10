#--------------------------------------------------------------------------------------------------------
# Descricao: Extrair uma listagem com todas as caixas postais do Microsoft 365
# Versao 01 (03/11/22) Jouderian Nobre
# Versao 02 (17/11/22) Jouderian Nobre
# Versao 03 (21/11/22) Jouderian Nobre
# Versao 04 (02/12/22) Jouderian Nobre
# Versao 05 (11/01/23) Jouderian Nobre
# Versao 06 (11/03/23) Jouderian Nobre
# Versao 07 (26/06/23) Jouderian Nobre
# Versao 08 (26/07/23) Jouderian Nobre: Inclusao do momento do ultimo ADsync, CC e Gerente
# Versao 09 (28/09/23) Jouderian Nobre: Melhoria no tratamento do MFA
# Versao 10 (29/02/24) Jouderian Nobre: Melhoria na gravacao do arquivo e remocao do MFA
# Versao 11 (18/05/24) Jouderian Nobre: Inclusao da licenca Microsoft Copilot
# Versao 11 (06/07/24) Jouderian Nobre: Inclusao da licenca PowerAutomate Premium
# Versao 12 (16/07/24) Jouderian Nobre: Inclusao sinalizador de encaminhamento
# Versao 13 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
# Versao 14 (08/01/25) Jouderian Nobre: Inclusao da ocupacao da caixa de arquivamento
# Versao 15 (10/01/25) Jouderian Nobre: Inclusao de novas licencas na relacao
# Versao 16 (17/01/25) Jouderian Nobre: Remocao da coluna itens da caixa postal
# Versao 17 (20/02/25) Jouderian Nobre: Inclusao da licenca PowerApps Premium
# Versao 18 (24/03/25) Jouderian Nobre: Adequacao para usar o MgGraph e seus comandos
#--------------------------------------------------------------------------------------------------------

Clear-Host

#--------------------------------------------------------------------- VARIAVEIS
$indice = 0
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaDeCaixasPostais.csv"
$EXOMgmtModule = Get-Module ExchangeOnlineManagement -ListAvailable
$MsGraphModule = Get-Module Microsoft.Graph -ListAvailable

#-------------------------------------------------------------------- VALIDACOES
if( $null -eq $MsGraphModule ){
  gravaLOG -arquivo $arquivoLogs -texto "O modulo Microsoft Graph e necessario e nao esta instalado no sistema" -erro:$true
  $confirm = Read-Host Are you sure you want to install Microsoft Graph module? [Y] Yes [N] No  
  if($confirm -match "[yY]"){
    Write-host "Instalando o modulo Microsoft Graph..."
    Install-Module -Name Microsoft.Graph -Scope CurrentUser -AllowClobber
    Write-host "O modulo Microsoft Graph foi instalado com sucesso" -ForegroundColor Magenta 
  } else {
    Write-host "Saindo. `nNota: O modulo Microsoft Graph nao esta disponivel em seu sistemapara executar o script" -ForegroundColor Red
    Exit 
  }
}
Import-Module -Name Microsoft.Graph.Users
Connect-MgGraph -Scopes "User.Read.All", "MailboxSettings.Read", "Directory.Read.All" -NoWelcome

if( $null -eq $EXOMgmtModule ){
  gravaLOG -arquivo $arquivoLogs -texto "O modulo Microsoft Exchange Online Management e necessario e nao esta instalado no sistema" -erro:$true
  $confirm = Read-Host Are you sure you want to install Microsoft Exchange Online Management module? [Y] Yes [N] No  
  if( $confirm -match "[yY]" ){
    Write-host "Instalando o modulo Microsoft Exchange Online Management..."
    Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -AllowClobber
    Write-host "Microsoft Exchange Online Management module is installed in the machine successfully" -ForegroundColor Magenta 
  } else {
    Write-host "Exiting. `nNote: Microsoft Exchange Online Management module must be available in your system to run the script" -ForegroundColor Red
    Exit 
  } 
}
Connect-ExchangeOnline

$inicio = Get-Date
Write-Host "`n`n`n`n`n`n`nInicio:" $inicio
Write-Host Pesquisando Relacao de Caixas Postais no ExchangeOnline...
$caixas = Get-MgUser `
  -ALL `
  -ConsistencyLevel eventual `
  -Property "Id,DisplayName,UserPrincipalName,City,State,CompanyName,OfficeLocation,Department,JobTitle,PostalCode,StreetAddress,OnPremisesSyncEnabled,AccountEnabled,PasswordPolicies,CreatedDateTime,LastPasswordChangeDateTime,OnPremisesLastSyncDateTime"

$caixas = $caixas | Where-Object { $_.UserPrincipalName -notlike "*#EXT#*" }

$totalCaixas = $caixas.Count

Write-Output "Nome,UPN,Cidade,UF,Empresa,Escritorio,Departamento,Cargo,Gerente,CC,nomeCC,Tipo,AD,Desabilitada,SenhaForte,SenhaNaoExpira,Compartilhada,Encaminhada,Litigio,usado(GB),Arquivamento,Arquivamento(GB),Criacao,MudancaSenha,ultimoSyncAD,ultimoAcesso,conta,objectId,Licencas,outrasLicencas" > $arquivo

Foreach ($caixa in $caixas){

  $indice++

  Write-Progress -Activity "Exportando caixas postais" -Status "Progresso: $indice de $totalCaixas extraidas" -PercentComplete (($indice / $totalCaixas) * 100)

#  if($caixa.UserPrincipalName.Contains("#EXT#")){ # Credencial de convidado
#    continue
#  }

  $detalheCaixa = Get-MailboxStatistics -Identity $caixa.Id
  $licencas = Get-MgUserLicenseDetail -UserId $caixa.Id
  $tamanho = [math]::Round((($detalheCaixa.TotalItemSize.Value.ToString()).Split('(')[1].Split(' ')[0].Replace(',','')/1GB),2)

  if($detalheCaixa.IsArchiveMailbox -eq 'Active'){
    $detalheArquivo = Get-MailboxStatistics -Identity $caixa.ExternalDirectoryObjectId -Archive
    $tamanhoArquivamento = [math]::Round((($detalheArquivo.TotalItemSize.Value.ToString()).Split('(')[1].Split(' ')[0].Replace(',','')/1GB),2)
  } else {
    $tamanhoArquivamento = 0
  }
  
  try {
    $gerente = Get-MgUserManager -UserId $caixa.Id
    $gerente = $gerente.AdditionalProperties.displayName    
  }
  catch {
    $gerente = ""
  }

  $infoCaixa = "$($caixa.DisplayName)," # Nome
  $infoCaixa += "$($caixa.UserPrincipalName)," # UPN
  $infoCaixa += "$($caixa.City)," # Cidade
  $infoCaixa += "$($caixa.State)," # UF
  $infoCaixa += "$($caixa.CompanyName)," # Empresa
  $infoCaixa += "$($caixa.OfficeLocation)," # Escritorio
  $infoCaixa += [System.String]::Concat("""","$($caixa.Department)",""",") # Departamento
  $infoCaixa += [System.String]::Concat("""","$($caixa.JobTitle)",""",") # Cargo
  $infoCaixa += "$($gerente)," #Gerente
  $infoCaixa += "$($caixa.postalCode)," # CC
  $infoCaixa += "$($caixa.streetAddress)," # nomeCC
  $infoCaixa += "$($detalheCaixa.MailboxTypeDetail.Value)," # Tipo
  $infoCaixa += "$($caixa.OnPremisesSyncEnabled)," # AD
  $infoCaixa += "$($caixa.AccountEnabled)," # Desabilitada
  $infoCaixa += "$($caixa.PasswordPolicies -contains "DisableStrongPassword")," # SenhaForte
  $infoCaixa += "$($caixa.PasswordPolicies -contains "DisablePasswordExpiration")," # SenhaNaoExpira
  $infoCaixa += "," # Compartilhada
  $infoCaixa += "," # Encaminhada
  $infoCaixa += "," # Litigio
  $infoCaixa += "$($tamanho)," # usado(GB)
  $infoCaixa += "$($detalheCaixa.IsArchiveMailbox)," # Arquivamento
  $infoCaixa += "$($tamanhoArquivamento)," # Arquivamento(GB)
  $infoCaixa += "$($caixa.CreatedDateTime.ToString('dd/MM/yy HH:mm'))," # Criacao
  $infoCaixa += "$($caixa.LastPasswordChangeDateTime.ToString('dd/MM/yy HH:mm'))," # MudancaSenha

  $momento = $caixa.OnPremisesLastSyncDateTime # ultimoSyncAD
  if($null -eq $momento){
    $infoCaixa += ","
  } Else {
    $infoCaixa += "$($momento.ToString('dd/MM/yy HH:mm')),"
  }

  $momento = $detalheCaixa.LastUserActionTime # ultimoAcesso
  if($null -eq $momento){
    $infoCaixa += ","
  } Else {
    $infoCaixa += "$($momento.ToString('dd/MM/yy HH:mm')),"
  }

  $infoCaixa += "," # conta
  $infoCaixa += "$($caixa.Id)," # objectId

  $licencaPaga = ""
  $outrasLicencas = ""

  Foreach ($licenca in $licencas){
# Licencas Exchange
    if($licenca.SkuPartNumber -eq "EXCHANGEDESKLESS"){
      $licencaPaga += "+Online Kiosk" #Apenas eMail de 2Gb
    } elseif($licenca.SkuPartNumber -eq "EXCHANGESTANDARD"){
      $licencaPaga += "+Online Plan1" #Apenas eMail de 50Gb
    } elseif($licenca.SkuPartNumber -eq "EXCHANGEENTERPRISE"){
      $licencaPaga += "+Online Plan2" #Apenas eMail de 100Gb
# Licencas Business
    } elseif($licenca.SkuPartNumber -eq "O365_BUSINESS"){
      $licencaPaga += "+AppsBusiness" #Apenas msOffice presencial
    } elseif($licenca.SkuPartNumber -eq "O365_BUSINESS_ESSENTIALS"){
      $licencaPaga += "+Business Basic" #eMail de 50Gb e msOffice onLine
    } elseif($licenca.SkuPartNumber -eq "O365_BUSINESS_PREMIUM"){
      $licencaPaga += "+Business Standard" #eMail de 50Gb e msOffice presencial
    } elseif($licenca.SkuPartNumber -eq "SPB"){
      $licencaPaga += "+Business Premium" #eMail de 50Gb, msOffice presencial e Windows 10
# Licencas Enterprise
    } elseif($licenca.SkuPartNumber -eq "OFFICESUBSCRIPTION"){
      $licencaPaga += "+AppsEnterprise" #Apenas msOffice presencial
    } elseif($licenca.SkuPartNumber -eq "M365_F1_COMM"){
      $licencaPaga += "+M365 F1" #Apenas Colaboracao
    } elseif($licenca.SkuPartNumber -eq "DESKLESSPACK"){
      $licencaPaga += "+O365 F3" #eMail de 2Gb e msOffice onLine
    } elseif($licenca.SkuPartNumber -eq "STANDARDPACK"){
      $licencaPaga += "+O365  E1" #eMail de 50Gb e msOffice onLine
    } elseif($licenca.SkuPartNumber -eq "Office365_E1_Plus"){
      $licencaPaga += "+O365 E1 Plus" #eMail de 50Gb, msOffice onLine e entraID P1
    } elseif($licenca.SkuPartNumber -eq "ENTERPRISEPACK"){
      $licencaPaga += "+O365 E3" #eMail de 100Gb e msOffice presencial
# Licencas Power
    } elseif($licenca.SkuPartNumber -eq "POWER_BI_PRO"){
      $licencaPaga += "+PowerBI Pro"
    } elseif($licenca.SkuPartNumber -eq "POWERAPPS_PER_USER"){
      $licencaPaga += "+PowerApps Premium" # PowerApss Premium
    } elseif($licenca.SkuPartNumber -eq "FLOW_PER_USER"){
      $licencaPaga += "+PowerAutomate" # PowerAutomate Por User Plan
    } elseif($licenca.SkuPartNumber -eq "POWERAUTOMATE_ATTENDED_RPA"){
      $licencaPaga += "+Automate Premium" # Power Automate Premium
# Licencas Diversas
    } elseif($licenca.SkuPartNumber -eq "Microsoft_365_Copilot"){
      $licencaPaga += "+M365 Copilot"
    } elseif($licenca.SkuPartNumber -eq "PROJECT_P1"){
      $licencaPaga += "+Project Plan 1" # Apenas Project Online
    } elseif($licenca.SkuPartNumber -eq "PROJECTPROFESSIONAL"){
      $licencaPaga += "+Project Plan 3" # Apenas Project presencial
    } else {
      $outrasLicencas += [System.String]::Concat("+", $licenca.SkuPartNumber)
    }
  }
  $infoCaixa += [System.String]::Concat("""","$($licencaPaga)",""",") # Licencas
  $infoCaixa += [System.String]::Concat("""","$($outrasLicencas)","""") # outrasLicencas

  Write-Output $infoCaixa >> $arquivo
}

Write-Progress -Activity "Exportando caixas postais" -PercentComplete 100

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()

Disconnect-ExchangeOnline -Confirm:$false
Disconnect-MgGraph