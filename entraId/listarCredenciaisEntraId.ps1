<#
  .SYNOPSIS
    Lista e audita credenciais (Secrets e Certificados) do Entra ID.
  .DESCRIPTION
    Este script mapeia credenciais associadas às aplicações (App Registrations) e 
    Service Principals (Enterprise Applications) do Microsoft Entra ID.
    Calcula dias restantes até a expiração, obtém os proprietários e permite exportação para CSV.
  .AUTHOR
    Jouderian Nobre
  .CREATED
    04/07/26
  .VERSION
    01 (04/07/26) - Criação inicial guiada por SDD
  .OUTPUT
    Console e arquivo CSV opcional.
  .PARAMETER TipoAplicacao
    Define o escopo da busca. Valores aceitos: AppRegistrations, EnterpriseApps ou Ambos (Padrão: Ambos).
  .PARAMETER DiasParaExpirar
    Filtra as credenciais que expiram em até X dias (ou já expiradas). Se omitido, lista todas.
  .EXAMPLE
    .\listarCredenciaisEntraId.ps1 -TipoAplicacao AppRegistrations -DiasParaExpirar 30
#>

[CmdletBinding()]
param (
  [ValidateSet("AppRegistrations", "EnterpriseApps", "Ambos")][string]$TipoAplicacao = "Ambos",
  [int]$DiasParaExpirar
)

Clear-Host
. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

# Declarando variaveis
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listarCredenciaisEntraId_$($inicio.ToString('yyyyMMdd')).txt"
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\credenciaisEntraID.csv"

gravaLOG "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))" -tipo WRN -arquivo $logs
gravaLOG "Iniciando auditoria de credenciais no EntraID" -tipo INF -arquivo $logs

# Validar módulos necessários
VerificaModulo -NomeModulo "Microsoft.Graph.Authentication" -MensagemErro "Modulo Microsoft.Graph.Authentication ausente no console." -arquivoLogs $logs
VerificaModulo -NomeModulo "Microsoft.Graph.Applications" -MensagemErro "Modulo Microsoft.Graph.Applications ausente no console." -arquivoLogs $logs

# Autenticação
gravaLOG "Tentando se autenticar no msGraph" -tipo INF -arquivo $logs
try {
  Connect-MgGraph -Scopes "Application.Read.All" -NoWelcome -ErrorAction Stop
  gravaLOG "Conectado ao Microsoft Graph com sucesso." -tipo OK -arquivo $logs
} catch {
  gravaLOG "Conectando no Microsoft Graph: $($_.Exception.Message)" -tipo ERR -arquivo $logs -mostraTempo $true
  Exit 1
}

$resultados = @()
$filtrarDias = $PSBoundParameters.ContainsKey('DiasParaExpirar')

# ----------------- COLETAR APP REGISTRATIONS -----------------
if ($TipoAplicacao -eq "Ambos" -or $TipoAplicacao -eq "AppRegistrations"){
  gravaLOG "Buscando App Registrations no EntraID..." -tipo STP -arquivo $logs
  try {
    # Obter aplicações com PasswordCredentials e KeyCredentials populados
    $apps = Get-MgApplication -All -Property "id", "displayName", "appId", "passwordCredentials", "keyCredentials" -ErrorAction Stop
    $totalApps = $apps.Count
    gravaLOG "$totalApps App Registrations identificados" -tipo OK -arquivo $logs -mostraTempo $true

    $contador = 0
    foreach ($app in $apps){
      $contador++
      Write-Progress -Activity "Processando App Registrations" -Status "Analisando: $($app.DisplayName) ($contador / $totalApps)" -PercentComplete (($contador / $totalApps) * 100)

      $temSecrets = $null -ne $app.PasswordCredentials -and $app.PasswordCredentials.Count -gt 0
      $temCerts = $null -ne $app.KeyCredentials -and $app.KeyCredentials.Count -gt 0

      if ($temSecrets -or $temCerts){
        $ownersList = "Sem Proprietario"
        try {
          $owners = Get-MgApplicationOwner -ApplicationId $app.Id -ErrorAction Stop
          if ($owners -and $owners.Count -gt 0){
            $ownersNames = @()
            foreach ($owner in $owners){
              if ($owner.AdditionalProperties.ContainsKey('userPrincipalName')){
                $ownersNames += $owner.AdditionalProperties['userPrincipalName']
              } elseif ($owner.AdditionalProperties.ContainsKey('displayName')){
                $ownersNames += $owner.AdditionalProperties['displayName']
              } else {
                $ownersNames += $owner.Id
              }
            }
            $ownersList = $ownersNames -join ", "
          }
        } catch {
          gravaLOG "Obtendo proprietarios para a aplicacao: $($app.DisplayName) (ID: $($app.Id))" -tipo ERR -arquivo $logs -mostraTempo $true
        }

        # Mapear Secrets
        if ($temSecrets){
          foreach ($secret in $app.PasswordCredentials){
            $daysRemaining = (New-TimeSpan -Start (Get-Date) -End $secret.EndDateTime).Days

            if (-not $filtrarDias -or ($daysRemaining -le $DiasParaExpirar)){
              $resultados += [PSCustomObject]@{
                AppType        = "appRegistration"
                AppName        = $app.DisplayName
                AppId          = $app.AppId
                Owners         = $ownersList
                CredentialType = "Secret"
                CredentialName = $secret.DisplayName
                StartDate      = $secret.StartDateTime.ToString("dd-MM-yy")
                EndDate        = $secret.EndDateTime.ToString("dd-MM-yy")
                DaysRemaining  = $daysRemaining
              }
            }
          }
        }

        # Mapear Certificados
        if ($temCerts){
          foreach ($cert in $app.KeyCredentials){
            $daysRemaining = (New-TimeSpan -Start (Get-Date) -End $cert.EndDateTime).Days

            if (-not $filtrarDias -or ($daysRemaining -le $DiasParaExpirar)){
              $resultados += [PSCustomObject]@{
                AppType        = "appRegistration"
                AppName        = $app.DisplayName
                AppId          = $app.AppId
                Owners         = $ownersList
                CredentialType = "Certificate"
                CredentialName = $cert.DisplayName
                StartDate      = $cert.StartDateTime.ToString("dd-MM-yy")
                EndDate        = $cert.EndDateTime.ToString("dd-MM-yy")
                DaysRemaining  = $daysRemaining
              }
            }
          }
        }
      }
    }
  } catch {
    gravaLOG "Obtendo App Registrations: $($_.Exception.Message)" -tipo ERR -arquivo $logs -mostraTempo $true
  }
  Write-Progress -Activity "Processando App Registrations" -Completed
}

# ----------------- COLETAR ENTERPRISE APPLICATIONS (SERVICE PRINCIPALS) -----------------
if ($TipoAplicacao -eq "Ambos" -or $TipoAplicacao -eq "EnterpriseApps"){
  gravaLOG "Buscando Enterprise Applications (Service Principals) no Entra ID..." -tipo STP -arquivo $logs
  try {
    # Obter service principals com passwordCredentials e keyCredentials
    $sps = Get-MgServicePrincipal -All -Property "id", "displayName", "appId", "passwordCredentials", "keyCredentials", "servicePrincipalType", "appOwnerOrganizationId", "publisherName", "tags" -ErrorAction Stop
    $totalSps = $sps.Count
    gravaLOG "$totalSps Enterprise Applications identificadas" -tipo OK -arquivo $logs -mostraTempo $true

    $contador = 0
    foreach ($sp in $sps){
      $contador++
      Write-Progress -Activity "Processando Enterprise Applications" -Status "Analisando: $($sp.DisplayName) ($contador / $totalSps)" -PercentComplete (($contador / $totalSps) * 100)

      # Filtros de ruído (Excluir Managed Identities, Apps 1st-party da Microsoft e WAAD Integrated)
      if ($sp.ServicePrincipalType -eq "ManagedIdentity"){
        continue
      }
      if ($sp.AppOwnerOrganizationId -eq "f8c544b2-5c81-438b-b40b-41da1a550342" -or $sp.PublisherName -eq "Microsoft Services") {
        continue
      }
      if ($sp.Tags -contains "WindowsAzureActiveDirectoryIntegratedApp"){
        continue
      }

      $temSecrets = $null -ne $sp.PasswordCredentials -and $sp.PasswordCredentials.Count -gt 0
      $temCerts = $null -ne $sp.KeyCredentials -and $sp.KeyCredentials.Count -gt 0

      if ($temSecrets -or $temCerts){
        $ownersList = "Sem Proprietario"
        try {
          $owners = Get-MgServicePrincipalOwner -ServicePrincipalId $sp.Id -ErrorAction Stop
          if ($owners -and $owners.Count -gt 0){
            $ownersNames = @()
            foreach ($owner in $owners){
              if ($owner.AdditionalProperties.ContainsKey('userPrincipalName')){
                $ownersNames += $owner.AdditionalProperties['userPrincipalName']
              } elseif ($owner.AdditionalProperties.ContainsKey('displayName')){
                $ownersNames += $owner.AdditionalProperties['displayName']
              } else {
                $ownersNames += $owner.Id
              }
            }
            $ownersList = $ownersNames -join ", "
          }
        } catch {
          gravaLOG "Obtendo proprietarios para o Service Principal: $($sp.DisplayName) (ID: $($sp.Id))" -tipo ERR -arquivo $logs -mostraTempo $true
        }

        # Mapear Secrets
        if ($temSecrets){
          foreach ($secret in $sp.PasswordCredentials){
            $daysRemaining = (New-TimeSpan -Start (Get-Date) -End $secret.EndDateTime).Days

            if (-not $filtrarDias -or ($daysRemaining -le $DiasParaExpirar)){
              $resultados += [PSCustomObject]@{
                AppType        = "enterpriseApp"
                AppName        = $sp.DisplayName
                AppId          = $sp.AppId
                Owners         = $ownersList
                CredentialType = "Secret"
                CredentialName = $secret.DisplayName
                StartDate      = $secret.StartDateTime.ToString("dd-MM-yy")
                EndDate        = $secret.EndDateTime.ToString("dd-MM-yy")
                DaysRemaining  = $daysRemaining
              }
            }
          }
        }

        # Mapear Certificados
        if ($temCerts){
          foreach ($cert in $sp.KeyCredentials){
            $daysRemaining = (New-TimeSpan -Start (Get-Date) -End $cert.EndDateTime).Days

            if (-not $filtrarDias -or ($daysRemaining -le $DiasParaExpirar)){
              $resultados += [PSCustomObject]@{
                AppType        = "enterpriseApp"
                AppName        = $sp.DisplayName
                AppId          = $sp.AppId
                Owners         = $ownersList
                CredentialType = "Certificate"
                CredentialName = $cert.DisplayName
                StartDate      = $cert.StartDateTime.ToString("dd-MM-yy")
                EndDate        = $cert.EndDateTime.ToString("dd-MM-yy")
                DaysRemaining  = $daysRemaining
              }
            }
          }
        }
      }
    }
  } catch {
    gravaLOG "Obtendo Service Principals: $($_.Exception.Message)" -tipo ERR -arquivo $logs -mostraTempo $true
  }
  Write-Progress -Activity "Processando Enterprise Applications" -Completed
}

gravaLOG "$($resultados.Count) credenciais encontradas nos filtros" -tipo INF -arquivo $logs -mostraTempo $true

# Exportar para CSV
if ($resultados.Count -gt 0){
  try {
    # Garantir que a pasta destino existe
    $diretorioDestino = Split-Path $arquivo -Parent
    if ($diretorioDestino -and -not (Test-Path $diretorioDestino)){
      New-Item -ItemType Directory -Path $diretorioDestino -Force | Out-Null
    }

    $resultados | Export-Csv -Path $arquivo -NoTypeInformation -Encoding utf8 -Delimiter ";"
    gravaLOG "Relatorio exportado com sucesso para: $arquivo" -tipo OK -arquivo $logs
  } catch {
    gravaLOG "Exportando relatorio para CSV: $($_.Exception.Message)" -tipo ERR -arquivo $logs -mostraTempo $true
  }
}

# Desconexão
Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
gravaLOG "Desconectado do Microsoft Graph." -tipo INF -arquivo $logs

$final = Get-Date
gravaLOG "Tempo de Duracao: $((New-TimeSpan -Start $inicio -End $final).ToString())" -tipo WRN -arquivo $logs -mostraTempo $true
