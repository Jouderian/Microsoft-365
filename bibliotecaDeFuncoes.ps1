#--------------------------------------------------------------------------------------------------------
# Autor: Jouderian Nobre
# Descricao: Biblioteca de funcoes de uso geral
# Versao: 1 (27/09/24) Jouderian: Criacao do script
# Versao: 2 (10/10/24) Jouderian: Funcao de gravacao de LOGs
# Versao: 3 (10/04/25) Jouderian: Funcao de geracao de senha aleatoria
# Versao: 4 (14/04/25) Jouderian: Funcao de validacao de modulo e obter descricao de licenca
# Versao: 5 (30/05/25) Jouderian: Melhoria na funcao de validacao de modulo
#--------------------------------------------------------------------------------------------------------

function removeQuebraDeLinha{
  param (
    [Parameter(Mandatory=$true)][string]$texto
  )
  $textoTratado = $texto.replace("
", ' ').replace('`n', ' ').replace('`r', ' ')
  Return $textoTratado
}

function trataTexto{
  param (
    [Parameter(Mandatory=$true)][string]$texto,
    [Parameter(Mandatory=$false)][boolean]$removeQuebraLinha = $true, <# Remove quebra de linha #>
    [Parameter(Mandatory=$false)][boolean]$removeEspacoduplo = $true, <# Remove espaco duplo #>
    [Parameter(Mandatory=$false)][string]$notacao = " " <# Escrita de escrita: [m]inuscula, [M]aiuscula, [C]amelo #>
  )
  $textoTratado = $texto.Trim()

  if ($removeQuebraLinha){
    $textoTratado = removeQuebraDeLinha -texto $textoTratado
  }
  if($removeEspacoduplo){
    $textoTratado = $textoTratado.replace('  ', ' ')
  }
  if ($notacao -eq "C"){
    $textoTratado = (Get-Culture).TextInfo.ToTitleCase($textoTratado.ToLower())
    $textoTratado = $textoTratado.replace(' Da ', ' da ').replace(' De ', ' de ').replace(' Di ', ' di ').replace(' Do ', ' do ').replace(' Du ', ' du ').replace(' Das ', ' das ').replace(' Dos ', ' dos ').replace(' Iii', ' III').replace(' Ii', ' II')
  } elseif ($notacao -eq "m"){
    $textoTratado = $texto.ToLower()
  } elseif ($notacao -eq "M"){
    $textoTratado = $texto.ToUpper()
  }
  $textoTratado = $textoTratado.replace(',', ' ')
  
  Return $textoTratado
}

Function gravaLOG {
  Param (
    [parameter(Mandatory=$true)][string]$arquivo,
    [parameter(Mandatory=$true)][string]$texto,
    [parameter(Mandatory=$false)][boolean]$erro = $false
  )

  Out-File $arquivo -InputObject "$(if($erro){ "[ERRO] $texto" } else { $texto })" -Append
  Write-Host "$(if($erro){ "[ERRO] $texto" } else { $texto })"
}

function geraSenhaAleatoria {
  Param (
    [parameter(Mandatory=$false)][int]$tamanho = 16,
    [parameter(Mandatory=$false)][string]$chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()"
  )
  
  $password = -join ((65..90) + (97..122) + (48..57) + (33..47) | Get-Random -Count $tamanho | ForEach-Object {[char]$_})
  return $password
}

function VerificaModulo {
  param (
    [parameter(Mandatory=$true)][string]$NomeModulo,
    [parameter(Mandatory=$true)][string]$MensagemErro
  )

  $modulo = Get-Module -Name $NomeModulo -ListAvailable
  if($Modulo.count -eq 0){
    gravaLOG -arquivo $arquivoLogs -texto $MensagemErro -erro:$true
    $confirm = Read-Host "O módulo $NomeModulo não está instalado. Deseja instalá-lo? [S]im ou [N]ao"
    if ($confirm -match "[sS]"){
      Write-Host "Instalando o módulo $NomeModulo..."
      Install-Module -Name $NomeModulo -Repository PSGallery -AllowClobber -Scope CurrentUser
      Write-Host "O módulo $NomeModulo foi instalado com sucesso" -ForegroundColor Magenta
      Exit
    }

    Write-Host "Saindo. O módulo $NomeModulo é necessário para executar o script." -ForegroundColor Red
    Exit
  }
}

function ObterDescricaoLicenca {
  param ([string]$SkuPartNumber)
  switch ($SkuPartNumber) {
# Licencas Exchange
    "EXCHANGEDESKLESS" { return "Online Kiosk" }
    "EXCHANGESTANDARD" { return "Online Plan1" }
    "EXCHANGEENTERPRISE" { return "Online Plan2" }
# Licencas Business
    "O365_BUSINESS" { return "AppsBusiness" }
    "O365_BUSINESS_ESSENTIALS" { return "Business Basic" }
    "O365_BUSINESS_PREMIUM" { return "Business Standard" }
    "SPB" { return "Business Premium" }
# Licencas Enterprise
    "OFFICESUBSCRIPTION" { return "AppsEnterprise" }
    "M365_F1_COMM" { return "M365 F1" }
    "DESKLESSPACK" { return "O365 F3" }
    "STANDARDPACK" { return "O365  E1" }
    "Office365_E1_Plus" { return "O365 E1 Plus" }
    "ENTERPRISEPACK" { return "O365 E3" }
# Licencas Power
    "POWER_BI_PRO" { return "PowerBI Pro" }
    "POWERAPPS_PER_USER" { return "PowerApps Premium" }
    "FLOW_PER_USER" { return "PowerAutomate" }
    "POWERAUTOMATE_ATTENDED_RPA" { return "Automate Premium" }
# Licencas Diversas
    "Microsoft_365_Copilot" { return "M365 Copilot" }
    "PROJECT_P1" { return "Project Plan 1" }
    "PROJECTPROFESSIONAL" { return "Project Plan 3" }
    default { return $null }
  }
}