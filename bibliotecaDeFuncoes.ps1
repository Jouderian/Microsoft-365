#--------------------------------------------------------------------------------------------------------
# Autor: Jouderian Nobre
# Descricao: Biblioteca de funcoes de uso geral
# Versao: 1 (27/09/24) Jouderian: Criacao do script
# Versao: 2 (10/10/24) Jouderian: Criacao da funcao de gravacao de LOGs
# Versao: 3 (10/04/25) Jouderian: Criacao da funcao de geracao de senha aleatoria
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
