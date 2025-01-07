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
#--------------------------------------------------------------------------------------------------------

Clear-Host

$Modules = Get-Module -Name ExchangeOnlineManagement -ListAvailable
if($Modules.count -eq 0){
  Write-Host Instale o modulo do ExchangeOnlineManagement usando o comando abaixo:`n  Install-Module ExchangeOnlineManagement -ForegroundColor yellow
  Exit
}
Connect-ExchangeOnline

$Modules = Get-Module -Name MSOnline -ListAvailable
if($Modules.count -eq 0){
  Write-Host Instale o modulo do MSOnline usando o comando abaixo:`n  Install-Module MSOnline -ForegroundColor yellow
  Exit
}
Connect-MsolService

$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaDeCaixasPostais.csv"
$inicio = Get-Date

Write-Host "`n`n`n`n`n`n`nInicio:" $inicio
Write-Host Pesquisando Relacao de Caixas Postais no ExchangeOnline...
$caixas = Get-Mailbox -ResultSize Unlimited

$totalCaixas = $caixas.Count
$indice = 0

Write-Output "Nome,UPN,Cidade,UF,Empresa,Escritorio,Departamento,Cargo,Gerente,CC,nomeCC,Tipo,AD,Desabilitada,SenhaForte,SenhaNaoExpira,Compartilhada,Encaminhada,Litigio,Itens,usado(GB),Arquivamento,Criacao,MudancaSenha,ultimoSyncAD,ultimoAcesso,nomeConta,objectId,Licencas,outrasLicencas" > $arquivo

Foreach ($caixa in $caixas){

  $indice++
  Write-Progress -Activity "Exportando caixas postais" -Status "Progresso: $indice de $totalCaixas extraidas" -PercentComplete (($indice / $totalCaixas) * 100)

  $detalheCaixa = Get-MailboxStatistics -Identity $caixa.ExternalDirectoryObjectId
  $detalheCaixa2 = Get-User -Identity $caixa.ExternalDirectoryObjectId
  $usuario = Get-MsolUser -ObjectId $caixa.ExternalDirectoryObjectId

  $tamanho = [math]::Round((($detalheCaixa.TotalItemSize.Value.ToString()).Split('(')[1].Split(' ')[0].Replace(',','')/1GB),2)

  $infoCaixa = "$($caixa.DisplayName)," # Nome
  $infoCaixa += "$($caixa.UserPrincipalName)," # UPN
  $infoCaixa += "$($usuario.City)," # Cidade
  $infoCaixa += "$($usuario.State)," # UF
  $infoCaixa += "$($detalheCaixa2.Company)," # Empresa
  $infoCaixa += "$($usuario.Office)," # Escritorio
  $infoCaixa += [System.String]::Concat("""","$($usuario.Department)",""",") # Departamento
  $infoCaixa += [System.String]::Concat("""","$($usuario.Title)",""",") # Cargo
  $infoCaixa += "$($detalheCaixa2.Manager)," #Gerente
  $infoCaixa += "$($detalheCaixa2.postalCode)," # CC
  $infoCaixa += "$($detalheCaixa2.streetAddress)," # nomeCC
  $infoCaixa += "$($caixa.RecipientTypeDetails)," # Tipo
  $infoCaixa += "$($caixa.IsDirSynced)," # AD
  $infoCaixa += "$($caixa.AccountDisabled)," # Desabilitada
  $infoCaixa += "$($usuario.StrongPasswordRequired)," # SenhaForte
  $infoCaixa += "$($usuario.PasswordNeverExpires)," # SenhaNaoExpira
  $infoCaixa += "$($caixa.IsShared)," # Compartilhada
  $infoCaixa += "$($caixa.DeliverToMailboxAndForward)," # Encaminhada
  $infoCaixa += "$($caixa.LitigationHoldDuration)," # Litigio
  $infoCaixa += "$($detalheCaixa.ItemCount)," # Itens
  $infoCaixa += "$($tamanho)," # usado(GB)
  $infoCaixa += "$($caixa.ArchiveStatus)," # Arquivamento
  $infoCaixa += "$($usuario.WhenCreated.ToString('dd/MM/yy HH:mm'))," # Criacao
  $infoCaixa += "$($usuario.LastPasswordChangeTimestamp.ToString('dd/MM/yy HH:mm'))," # MudancaSenha

  $momento = $usuario.LastDirSyncTime # ultimoSyncAD
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

  $infoCaixa += "$($caixa.Alias)," # nomeConta
  $infoCaixa += "$($caixa.ExternalDirectoryObjectId)," # objectId

  $licencaPaga = ""
  $outrasLicencas = ""
  $licencas = $usuario.Licenses.AccountSkuId
  Foreach ($licenca in $licencas){
    if($licenca -eq "reseller-account:EXCHANGEDESKLESS"){
      $licencaPaga += "+Online Kiosk" #Apenas eMail de 2Gb
    } elseif($licenca -eq "reseller-account:EXCHANGESTANDARD"){
      $licencaPaga += "+Online Plan1" #Apenas eMail de 50Gb
    } elseif($licenca -eq "reseller-account:EXCHANGEENTERPRISE"){
      $licencaPaga += "+Online Plan2" #Apenas eMail de 100Gb
    } elseif($licenca -eq "reseller-account:DESKLESSPACK"){
      $licencaPaga += "+Office 365 F3" #eMail de 2Gb e msOffice onLine
    } elseif($licenca -eq "reseller-account:O365_BUSINESS_ESSENTIALS"){
      $licencaPaga += "+Business Basic" #eMail de 50Gb e msOffice onLine
    } elseif($licenca -eq "reseller-account:STANDARDPACK"){
      $licencaPaga += "+Office 365 E1" #eMail de 50Gb e msOffice onLine
    } elseif($licenca -eq "reseller-account:O365_BUSINESS_PREMIUM"){
      $licencaPaga += "+Business Standard" #eMail de 50Gb e msOffice presencial
    } elseif($licenca -eq "reseller-account:SPB"){
      $licencaPaga += "+Business Premium" #eMail de 50Gb, msOffice presencial e Windows 10
    } elseif($licenca -eq "reseller-account:ENTERPRISEPACK"){
      $licencaPaga += "+Office 365 E3" #eMail de 100Gb e msOffice presencial
    } elseif($licenca -eq "reseller-account:O365_BUSINESS"){
      $licencaPaga += "+AppsBusiness" #Apenas msOffice presencial
    } elseif($licenca -eq "reseller-account:OFFICESUBSCRIPTION"){
      $licencaPaga += "+AppsEnterprise" #Apenas msOffice presencial
    } elseif($licenca -eq "reseller-account:POWER_BI_PRO"){
      $licencaPaga += "+PowerBI Pro"
    } elseif($licenca -eq "reseller-account:PROJECT_P1"){
      $licencaPaga += "+Project Plan 1" # Apenas Project Online
    } elseif($licenca -eq "reseller-account:PROJECTPROFESSIONAL"){
      $licencaPaga += "+Project Plan 3" # Apenas Project presencial
    } elseif($licenca -eq "reseller-account:Microsoft_365_Copilot"){
      $licencaPaga += "+Copilot 365"
    } elseif($licenca -eq "reseller-account:FLOW_PER_USER"){
      $licencaPaga += "+PowerAutomate" # Power Automate Por User Plan
    } elseif($licenca -eq "reseller-account:POWERAUTOMATE_ATTENDED_RPA"){
      $licencaPaga += "+Automate Premium" # Power Automate Premium
    } else {
      $outrasLicencas += [System.String]::Concat("+", $licenca)
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