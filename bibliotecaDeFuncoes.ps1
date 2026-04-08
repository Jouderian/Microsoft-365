<# 
  .SYNOPSIS
    Biblioteca de funcoes de uso geral para scripts em powerShell.
  .AUTHOR
    Jouderian Nobre
  .VERSION
    01 (27/09/24) - Criacao do script
    02 (10/10/24) - Funcao de gravacao de LOGs
    03 (10/04/25) - Funcao de geracao de senha aleatoria
    04 (14/04/25) - Funcao de validacao de modulo e obter descricao de licenca
    05 (30/05/25) - Melhoria na funcao de validacao de modulo
    06 (12/07/25) - Inclusao da licenca Teams Premium na funcao ObterDescricaoLicenca
    07 (06/10/25) - Ajuste no retorno da funcao VerificaModulo
    08 (20/02/25) - Funcao para testar se o acesso tem elevacao de administrador
    09 (02/03/26) - Funcao para remover acentos de um texto
    10 (30/03/26) - Funcao para obter o espaco usado e livre em uma unidade de disco
    11 (05/04/26) - Melhoria na funcao de gravacao de LOGs
#>

function removeQuebraDeLinha {
  <#
    .SYNOPSIS
      Remove as quebras de linha de um texto, substituindo-as por espaços.
    .PARAMETER texto
      O texto do qual as quebras de linha serão removidas.
  #>

  param (
    [Parameter(Mandatory = $true)][string]$texto
  )
  $textoTratado = $texto.replace("
", ' ').replace('`n', ' ').replace('`r', ' ')
  Return $textoTratado
}

function trataTexto {
  <#
    .SYNOPSIS
      Trata um texto, aplicando várias transformações.
    .PARAMETER texto
      O texto a ser tratado.
    .PARAMETER removeQuebraLinha
      Indica se deve remover quebras de linha (opcional, padrão: $true).
    .PARAMETER removeEspacoduplo
      Indica se deve remover espaços duplos (opcional, padrão: $true).
    .PARAMETER notacao
      A notação a ser aplicada ao texto (opcional, padrão: " "): [m]inuscula, [M]aiuscula, [C]amelo.
  #>
  param (
    [Parameter(Mandatory = $true)][string]$texto,
    [Parameter(Mandatory = $false)][boolean]$removeQuebraLinha = $true,
    [Parameter(Mandatory = $false)][boolean]$removeEspacoduplo = $true,
    [Parameter(Mandatory = $false)][string]$notacao = " "
  )
  $textoTratado = $texto.Trim()

  if ($removeQuebraLinha) {
    $textoTratado = removeQuebraDeLinha -texto $textoTratado
  }
  if ($removeEspacoduplo) {
    $textoTratado = $textoTratado.replace('  ', ' ')
  }
  if ($notacao -eq "C") {
    $textoTratado = (Get-Culture).TextInfo.ToTitleCase($textoTratado.ToLower())
    $textoTratado = $textoTratado.replace(' Da ', ' da ').replace(' De ', ' de ').replace(' Di ', ' di ').replace(' Do ', ' do ').replace(' Du ', ' du ').replace(' Das ', ' das ').replace(' Dos ', ' dos ').replace(' Iii', ' III').replace(' Ii', ' II')
  }
  elseif ($notacao -ceq "m") {
    $textoTratado = $textoTratado.ToLower()
  }
  elseif ($notacao -ceq "M") {
    $textoTratado = $textoTratado.ToUpper()
  }
  $textoTratado = $textoTratado.replace(',', ' ')
  
  Return $textoTratado
}

Function gravaLOG {
  <#
    .SYNOPSIS
      Grava uma mensagem de log em um arquivo e exibe no console.
    .PARAMETER texto
      A mensagem de log a ser gravada.
    .PARAMETER tipo
      O tipo de mensagem (Info, Aviso, Erro) para formatação e cor
    .PARAMETER arquivo
      O caminho do arquivo onde o log será gravado.
    .PARAMETER mostraTempo
      Indica se o timestamp deve ser mostrado no console (opcional, padrão: $false).
  #>

  Param (
    [Parameter(Mandatory = $true)][string]$texto,
    [ValidateSet('INF', 'OK', 'WRN', 'ERR', 'STP')][string]$tipo = 'INF',
    [parameter(Mandatory = $true)][string]$arquivo,
    [Parameter(Mandatory = $false)][boolean]$mostraTempo = $false
  )

  $prefix = @{
    INF = '[ℹ️ INFO ]';
    OK  = '[✅ OK   ]';
    WRN = '[⚠️ AVISO]';
    ERR = '[❌ ERRO ]';
    STP = '[🔹 PASSO]'
  }[$tipo]

  $color = @{
    INF = 'Cyan';
    OK  = 'Green';
    WRN = 'Yellow';
    ERR = 'Red';
    STP = 'Magenta'
  }[$tipo]

  if ($mostraTempo) {
    $tempo = "$((Get-Date).ToString('dd/MM/yy HH:mm:ss'))"
  }
  else {
    $tempo = ""
  }
  $mensagem = "$prefix $tempo $texto"

  Write-Host $mensagem -ForegroundColor $color
  Add-Content -Path $arquivo -Value $mensagem
}

function geraSenhaAleatoria {
  <#
    .SYNOPSIS
      Gera uma senha aleatória com base em um conjunto de caracteres especificado.
    .PARAMETER tamanho
      O comprimento da senha a ser gerada (padrão: 16).
    .PARAMETER chars
      Os caracteres a serem usados na geração da senha (padrão: letras minúsculas, maiúsculas, números e símbolos).
  #>
  Param (
    [parameter(Mandatory = $false)][int]$tamanho = 16,
    [parameter(Mandatory = $false)][string]$chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}|;:,.<>?/\~"
  )
  
  $password = -join ((65..90) + (97..122) + (48..57) + (33..47) | Get-Random -Count $tamanho | ForEach-Object { [char]$_ })
  return $password
}

function verificaModulo {
  <#
    .SYNOPSIS
      Verifica se um módulo do PowerShell está instalado e, se não estiver, oferece a opção de instalá-lo.
    .PARAMETER NomeModulo
      O nome do módulo a ser verificado.
    .PARAMETER MensagemErro
      A mensagem de erro a ser exibida se o módulo não estiver instalado.
    .PARAMETER arquivoLogs
      (Opcional) O caminho para um arquivo de log onde a mensagem de erro será registrada. Se não for fornecido, a mensagem será exibida no console.
  #>

  param (
    [parameter(Mandatory = $true)][string]$NomeModulo,
    [parameter(Mandatory = $true)][string]$MensagemErro,
    [parameter(Mandatory = $false)][string]$arquivoLogs
  )

  $modulo = Get-Module -Name $NomeModulo -ListAvailable
  if ($Modulo.count -eq 0) {
    if ($arquivoLogs) {
      gravaLOG -texto $MensagemErro -arquivo $arquivoLogs -tipo Erro
    }
    else {
      Write-Host $MensagemErro -ForegroundColor Red
    }
    $confirm = Read-Host "O módulo $NomeModulo não está instalado. Deseja instalá-lo? [S]im ou [N]ao"
    if ($confirm -match "[sS]") {
      Write-Host "Instalando o módulo $NomeModulo..."
      Install-Module -Name $NomeModulo -Repository PSGallery -AllowClobber -Scope CurrentUser
      Write-Host "O módulo $NomeModulo foi instalado com sucesso" -ForegroundColor Magenta
      Exit
    }

    Write-Host "Saindo. O módulo $NomeModulo é necessário para executar o script." -ForegroundColor Red
    Exit 1
  }
}

function obterDescricaoLicenca {
  <#
    .SYNOPSIS
      Obtém a descrição de uma licença com base em seu número de parte.
    .PARAMETER SkuPartNumber
      O número de parte da licença.
    .OUTPUT
      Retorna o apelido da licença correspondente ao código fornecido, ou $null se o código não for reconhecido.
  #>

  param (
    [string]$SkuPartNumber
  )

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
    "Microsoft_Teams_Premium" { return "Teams Premium" }
    "PROJECT_P1" { return "Project Plan 1" }
    "PROJECTPROFESSIONAL" { return "Project Plan 3" }
    default { return $null }
  }
}

function testaAcessoAdmin {
  <#
    .SYNOPSIS
      Verifica se o usuário atual tem privilégios de administrador.
    .OUTPUT
      Retorna $true se o usuário tiver privilégios de administrador, caso contrário, retorna $false.
  #>
  $p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function removerAcentos {
  <#
    .SYNOPSIS
      Remove os acentos de um texto, retornando apenas os caracteres sem acentos.
    .PARAMETER texto
      O texto do qual os acentos serão removidos.
    .OUTPUT
      Retorna o texto sem acentos.
  #>

  param (
    [parameter(Mandatory = $true)][string]$texto
  )

  # Normaliza para forma de decomposição (separa letra do acento)
  $normalized = $Texto.Normalize([System.Text.NormalizationForm]::FormD)

  # Remove os caracteres não espaçadores (acentos)
  $stringBuilder = New-Object System.Text.StringBuilder

  foreach ($char in $normalized.ToCharArray()) {
    if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($char) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
      [void]$stringBuilder.Append($char)
    }
  }

  # Retorna para forma normal
  return $stringBuilder.ToString().Normalize([System.Text.NormalizationForm]::FormC)
}

function espacoUsadoDisco {
  <#
    .SYNOPSIS
      Obtém o espaço em disco usado e disponível em uma unidade.
    .PARAMETER Drive
      A letra da unidade a ser verificada (padrão: C).
    .OUTPUT
      Retorna um objeto com as propriedades Total, Usado e Livre, representando o espaço total, usado e livre em bytes, respectivamente. Retorna $null se a unidade não for encontrada.
  #>

  param(
    [string]$Drive = 'C:'
  )
  
  $disco = Get-Volume -DriveLetter ($Drive[0]) -ErrorAction SilentlyContinue
  if ($disco) {
    return @{
      Total = $disco.Size
      Usado = $disco.Size - $disco.SizeRemaining
      Livre = $disco.SizeRemaining
    }
  }
  return $null
}
