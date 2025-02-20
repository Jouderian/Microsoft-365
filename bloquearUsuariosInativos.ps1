#--------------------------------------------------------------------------------------------------------
# Descricao:  Script para bloquear usuários suspeitos de inatividade no AD
# Versao 1 (21/05/23) Jouderian Nobe
# Versao 2 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
#--------------------------------------------------------------------------------------------------------

Clear-Host
$arquivoEntrada = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\credenciaisSuspeitasAD.csv"
$arquivoSaida = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\credenciaisBloqueadas.csv"
$inicio = Get-Date

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

Write-Host Inicio: $inicio
Write-Host Pesquisando relacao de credenciais no AD...
$Usuarios = Import-Csv -Delimiter:";" -Path $arquivoEntrada

$totalUsuarios = $Usuarios.Count
$indice = 0

Out-File -FilePath $arquivoSaida -InputObject "Credencial,Nome,eMail,tipoCaixa,Ativa,Empresa,Escritorio,Departamento,Cargo,Gerente,Objeto,Licencas,Grupos,Observacao,Acao" -Encoding UTF8

$Usuarios | ForEach-Object {
  $indice++
  Write-Host $_.contaAD  "($indice/$totalUsuarios)"

  $usuarioAD = get-ADUser `
    -Identity $_.contaAD `
    -properties `
      DisplayName, `
      EmailAddress, `
      Company, `
      office, `
      Department, `
      Title, `
      Manager, `
      CanonicalName, `
      Manager, `
      Description, `
      info

  $usuario365 = Get-MsolUser -UserPrincipalName $usuarioAD.EmailAddress
  $caixa = Get-Mailbox -Identity $_.contaAD

  $infoCredencial = "$($usuarioAD.SamAccountName),"
  $infoCredencial += "$($usuarioAD.DisplayName),"
  $infoCredencial += "$($usuarioAD.EmailAddress),"
  $infoCredencial += "$($caixa.RecipientTypeDetails),"
  $infoCredencial += "$($usuarioAD.Enabled),"
  $infoCredencial += "$($usuarioAD.Company),"
  $infoCredencial += "$($usuarioAD.Office),"
  $infoCredencial += "$($usuarioAD.Department),"
  $infoCredencial += "$($usuarioAD.Title),"
  $infoCredencial += [System.String]::Concat("""","$($usuarioAD.Manager)",""",")
  $infoCredencial += "$($usuarioAD.CanonicalName),"

  If($usuarioAD.Enabled){
    $Observacao = [System.String]::Concat( `
      $usuarioAD.Description, `
      " ~ Usuário bloqueado por falta de acesso em " + $final.ToString("dd/MM/yy HH:mm") `
    )
  } else {
    $Observacao = $usuarioAD.Description
  }

  $informacao = $usuarioAD.info + "`nUsuário bloqueado por falta de acesso em " + $final.ToString("dd/MM/yy HH:mm")

  $licencaPaga = ""
  $licencas = $usuario365.Licenses.AccountSkuId
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
      $licencaPaga += "+Project Plan 1"
    } elseif($licenca -eq "reseller-account:PROJECTPROFESSIONAL"){
      $licencaPaga += "+Project Plan 3"
    } elseif($licenca -eq "reseller-account:FLOW_PER_USER"){
      $licencaPaga += "+PowerAutomate" # Power Automate Por User Plan
    } elseif($licenca -eq "reseller-account:AAD_PREMIUM"){
      $licencaPaga += "+Azure AD P1" #Permite redefinicao de senha pela WEB
    }
#    Set-MsolUserLicense -UserPrincipalName $usuarioAD.EmailAddress -RemoveLicenses $licenca
  }
  $infoCredencial += [System.String]::Concat("""","$($licencaPaga)",""",")

  $nomeGrupos = ""
  $grupos = Get-ADPrincipalGroupMembership -Identity $UsuarioAD | Where-Object {($_.name -notmatch 'Domain Users' -and $_.name -notmatch 'MFA')}
  Foreach ($grupo in $grupos){
    $nomeGrupos += "+" + $grupo.name
#    Remove-ADPrincipalGroupMembership -Identity $UsuarioAD -MemberOf $grupo -Confirm:$False
  }

#  Set-ADUser -Identity $_.contaAD `
#    -Description $Observacao `
#    -OtherAttributes @{info=$informacao} `
#    -Enabled $false

  $infoCredencial += [System.String]::Concat("""","$($nomeGrupos)",""",")
  $infoCredencial += "$($usuarioAD.Description),"
  $infoCredencial += "$($Observacao)"

  Out-File -FilePath $arquivoSaida -InputObject $infoCredencial -Encoding UTF8 -append

}

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()