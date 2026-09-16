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
    12 (20/04/26) - Prefixos de log alterados para texto puro (sem emojis) e encoding UTF-8 com BOM
    13 (16/09/26) - Funcao geraSenhaAleatoria reescrita com gerador criptografico, respeito ao
                    parametro chars e garantia de complexidade; funcao trataTexto passa a colapsar
                    sequencias de espacos e a expor a remocao de virgulas como parametro
    14 (16/09/26) - Funcao removeQuebraDeLinha corrigida: passa a tratar CRLF, LF e CR isolado
                    via expressao regular, no lugar das substituicoes inertes anteriores
#>
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8


function removeQuebraDeLinha {
  <#
    .SYNOPSIS
      Remove as quebras de linha de um texto, substituindo-as por espaços.
    .DESCRIPTION
      Trata as três convenções de fim de linha: CRLF (Windows), LF (Unix) e CR isolado
      (Mac clássico, e o que sobra de textos colados de outras origens). Cada quebra vira
      um único espaço — CRLF não produz espaço duplo.
    .PARAMETER texto
      O texto do qual as quebras de linha serão removidas.
    .OUTPUT
      Retorna o texto em uma única linha.
  #>

  param (
    [Parameter(Mandatory = $true)][string]$texto
  )
  # A alternância trata CRLF como uma unidade antes de considerar o CR isolado
  $textoTratado = $texto -replace '\r?\n|\r', ' '
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
      Indica se deve colapsar sequências de espaços e tabulações em um único espaço
      (opcional, padrão: $true). Não afeta quebras de linha, controladas por $removeQuebraLinha.
    .PARAMETER removeVirgula
      Indica se as vírgulas devem ser substituídas por espaço, para que o texto possa ser
      gravado com segurança em arquivos CSV delimitados por vírgula (opcional, padrão: $true).
    .PARAMETER notacao
      A notação a ser aplicada ao texto (opcional, padrão: " "): [m]inuscula, [M]aiuscula, [C]amelo.
  #>
  param (
    [Parameter(Mandatory = $true)][string]$texto,
    [Parameter(Mandatory = $false)][boolean]$removeQuebraLinha = $true,
    [Parameter(Mandatory = $false)][boolean]$removeEspacoduplo = $true,
    [Parameter(Mandatory = $false)][boolean]$removeVirgula = $true,
    [Parameter(Mandatory = $false)][string]$notacao = " "
  )
  $textoTratado = $texto.Trim()

  if ($removeQuebraLinha){
    $textoTratado = removeQuebraDeLinha -texto $textoTratado
  }
  # A vírgula vira espaço antes do colapso, para que a substituição não deixe espaços duplos
  if ($removeVirgula){
    $textoTratado = $textoTratado.replace(',', ' ')
  }
  if ($removeEspacoduplo){
    # [^\S\r\n] casa espaço em branco horizontal (espaço, tabulação), preservando as quebras
    # de linha. O quantificador + colapsa sequências de qualquer comprimento, e não apenas
    # pares, como fazia o replace('  ', ' ') anterior.
    $textoTratado = ($textoTratado -replace '[^\S\r\n]+', ' ').Trim()
  }
  if ($notacao -eq "C"){
    $textoTratado = (Get-Culture).TextInfo.ToTitleCase($textoTratado.ToLower())
    $textoTratado = $textoTratado.replace(' Da ', ' da ').replace(' De ', ' de ').replace(' Di ', ' di ').replace(' Do ', ' do ').replace(' Du ', ' du ').replace(' Das ', ' das ').replace(' Dos ', ' dos ').replace(' Iii', ' III').replace(' Ii', ' II')
  } elseif ($notacao -ceq "m"){
    $textoTratado = $textoTratado.ToLower()
  } elseif ($notacao -ceq "M"){
    $textoTratado = $textoTratado.ToUpper()
  }
  Return $textoTratado
}

Function gravaLOG {
  <#
    .SYNOPSIS
      Grava uma mensagem de log em um arquivo e exibe no console.
    .PARAMETER texto
      A mensagem de log a ser gravada.
    .PARAMETER tipo
      Se informado, o tipo de mensagem (Info, Aviso, Erro) para formatação e cor
    .PARAMETER arquivo
      Se informado, o caminho do arquivo onde o log será gravado.
    .PARAMETER mostraTempo
      Indica se o timestamp deve ser mostrado no console (opcional, padrão: $false).
  #>

  Param (
    [Parameter(Mandatory = $true)][string]$texto,
    [parameter(Mandatory = $false)]
      [string]$arquivo,
      [boolean]$mostraTempo = $false,
      [ValidateSet('INF', 'OK', 'WRN', 'ERR', 'STP')][string]$tipo
  )

  $prefixo = @{
    INF = '[INFO ] ';
    OK  = '[OK   ] ';
    WRN = '[AVISO] ';
    ERR = '[ERRO ] ';
    STP = '[PASSO] ';
    ''  = ''
  }[$tipo]

  $color = @{
    INF = 'Cyan';
    OK  = 'Green';
    WRN = 'Yellow';
    ERR = 'Red';
    STP = 'Magenta';
    ''  = 'White'
  }[$tipo]

  # -or não pode ser usado aqui: em PowerShell retorna booleano. Fallback explícito:
  if (-not $color){ $color = 'White' }

  $tempo = ""
  if ($mostraTempo){
    $tempo = "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) "
  }
  $mensagem = "$prefixo$tempo$texto"

  Write-Host $mensagem -ForegroundColor $color
  if ($arquivo){
    Add-Content -Path $arquivo -Value $mensagem -Encoding UTF8
  }
}

function sorteiaIndicesSeguros {
  <#
    .SYNOPSIS
      Sorteia índices aleatórios criptograficamente seguros no intervalo [0, limite).
    .DESCRIPTION
      Usa o gerador criptográfico do .NET com amostragem por rejeição, descartando os sorteios
      que cairiam na faixa incompleta final do UInt32. Isso elimina o viés de módulo, que faria
      alguns caracteres serem escolhidos com mais frequência que outros.
    .PARAMETER quantidade
      Quantos índices devem ser sorteados.
    .PARAMETER limite
      Limite exclusivo do sorteio: os índices ficam entre 0 e ($limite - 1).
    .OUTPUT
      Retorna um array de inteiros com $quantidade posições.
  #>

  param (
    [parameter(Mandatory = $true)][ValidateRange(1, [int]::MaxValue)][int]$quantidade,
    [parameter(Mandatory = $true)][ValidateRange(1, [int]::MaxValue)][int]$limite
  )

  $gerador = [System.Security.Cryptography.RandomNumberGenerator]::Create()
  try {
    $indices = [int[]]::new($quantidade)
    $bytes = [byte[]]::new(4)

    # Maior múltiplo de $limite que cabe em um UInt32: acima dele o sorteio é descartado
    $teto = [uint32]([math]::Floor([uint32]::MaxValue / $limite) * $limite)

    for ($i = 0; $i -lt $quantidade; $i++){
      do {
        $gerador.GetBytes($bytes)
        $valor = [System.BitConverter]::ToUInt32($bytes, 0)
      } while ($valor -ge $teto)

      $indices[$i] = [int]($valor % $limite)
    }

    # A vírgula preserva o array como um único objeto no retorno
    return , $indices
  } finally {
    $gerador.Dispose()
  }
}

function geraSenhaAleatoria {
  <#
    .SYNOPSIS
      Gera uma senha aleatória criptograficamente segura a partir de um conjunto de caracteres.
    .DESCRIPTION
      Sorteia os caracteres com o gerador criptográfico do .NET (não com Get-Random) e com
      reposição, de modo que a senha sempre tenha exatamente o tamanho pedido e possa repetir
      caracteres. Quando $garanteComplexidade está ligado, a senha recebe ao menos um caractere
      de cada classe presente em $chars (minúscula, maiúscula, dígito e símbolo) e em seguida é
      embaralhada, para atender às políticas de senha do Active Directory e do Entra ID.
    .PARAMETER tamanho
      O comprimento da senha a ser gerada, entre 7 e 256 (padrão: 16).
    .PARAMETER chars
      Os caracteres a serem usados na geração da senha. O conjunto padrão não inclui vírgula,
      ponto-e-vírgula nem aspas, que quebrariam os arquivos CSV e de log gerados pelos scripts.
    .PARAMETER garanteComplexidade
      Indica se a senha deve conter ao menos um caractere de cada classe presente em $chars
      (opcional, padrão: $true).
    .OUTPUT
      Retorna a senha como texto puro. Cabe ao chamador convertê-la para SecureString e
      descartar a variável após o uso.
  #>

  Param (
    [parameter(Mandatory = $false)][ValidateRange(7, 256)][int]$tamanho = 16,
    [parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!?@#$%^&*(.)[-]{+}|:<=>/_\~',
    [parameter(Mandatory = $false)][boolean]$garanteComplexidade = $true
  )

  $conjunto = [char[]]@($chars.ToCharArray() | Select-Object -Unique)

  $classes = @(
    @{ nome = 'minuscula'; caracteres = [char[]]@($conjunto | Where-Object { [char]::IsLower($_) }) },
    @{ nome = 'maiuscula'; caracteres = [char[]]@($conjunto | Where-Object { [char]::IsUpper($_) }) },
    @{ nome = 'digito'; caracteres = [char[]]@($conjunto | Where-Object { [char]::IsDigit($_) }) },
    @{ nome = 'simbolo'; caracteres = [char[]]@($conjunto | Where-Object { -not [char]::IsLetterOrDigit($_) }) }
  ) | Where-Object { $_.caracteres.Count -gt 0 }

  if ($garanteComplexidade -and $tamanho -lt $classes.Count){
    throw "Tamanho $tamanho insuficiente: o conjunto informado exige ao menos $($classes.Count) caracteres para garantir a complexidade."
  }

  $senha = [System.Collections.Generic.List[char]]::new($tamanho)

  # Reserva uma posição para cada classe presente no conjunto
  if ($garanteComplexidade){
    foreach ($classe in $classes){
      $indice = (sorteiaIndicesSeguros -quantidade 1 -limite $classe.caracteres.Count)[0]
      $senha.Add($classe.caracteres[$indice])
    }
  }

  # Completa o restante sorteando livremente dentro do conjunto
  $restante = $tamanho - $senha.Count
  if ($restante -gt 0){
    foreach ($indice in (sorteiaIndicesSeguros -quantidade $restante -limite $conjunto.Count)){
      $senha.Add($conjunto[$indice])
    }
  }

  # Embaralha (Fisher-Yates) para que as classes garantidas não fiquem sempre nas primeiras posições
  for ($i = $senha.Count - 1; $i -gt 0; $i--){
    $j = (sorteiaIndicesSeguros -quantidade 1 -limite ($i + 1))[0]
    $troca = $senha[$i]
    $senha[$i] = $senha[$j]
    $senha[$j] = $troca
  }

  return -join $senha
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
  if ($Modulo.count -eq 0){
    if ($arquivoLogs){
      gravaLOG -texto $MensagemErro -tipo ERR -arquivo $arquivoLogs
    } else {
      Write-Host $MensagemErro -ForegroundColor Red
    }
    $confirm = Read-Host "O módulo $NomeModulo não está instalado. Deseja instalá-lo? [S]im ou [N]ao"
    if ($confirm -match "[sS]"){
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

  switch ($SkuPartNumber){
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

  foreach ($char in $normalized.ToCharArray()){
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
