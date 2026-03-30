#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Script de limpeza de disco otimizado para reduzir espaço utilizado.

.DESCRIPTION
  Limpa arquivos temporários, cache e outros arquivos descartaveis do sistema operacional.
.AUTHOR
  Felipe Jesus
.VERSION
  01 (27/03/25) Felipe Jesus: Criacao do script
  02 (30/03/24) Jouderian Nobre: Ajustes para melhorar a performance e tratamento de erros
#>

#===================================================================== VARIAVEIS
$tempUser = $env:TEMP
$tempSystem = "C:\Windows\Temp"
$explorerCache = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
$updateCache = "C:\Windows\SoftwareDistribution\Download"
$arquivoLOG = "$env:TEMP\Limpeza_Disco.log"


#================================================================= CONFIGURACOES
# Configurações de rigor do script
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

#======================================================================= FUNÇÕES
function testaAcessoAdmin {
  <#
    .SYNOPSIS
      Verifica se o usuário atual tem privilégios de administrador.
    .OUTPUT
      Retorna $true se o usuário tiver privilégios de administrador, caso contrário, retorna $false.
  #>
  $p  = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function gravaLOG {
  <#
  .SYNOPSIS
    Escreve log formatado no console e arquivo.
  .PARAMETER Mensagem
    A mensagem a ser registrada.
  .PARAMETER tipo
    O tipo de mensagem (Info, Aviso, Erro) para formatação e cor. Padrão é 'Info'.
  #>

  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]$Mensagem,
    
    [ValidateSet('Info', 'Aviso', 'Erro')]
    [string]$tipo = 'Info'
  )

  $timestamp = Get-Date -Format 'dd-mm-yy HH:mm:ss'
  $logMensagem = "[$timestamp] [$tipo] $Mensagem"
  
  # Cores diferentes por nível
  switch ($tipo){
    'Info'  { Write-Host $logMensagem -ForegroundColor Green }
    'Aviso' { Write-Host $logMensagem -ForegroundColor Yellow }
    'Erro'  { Write-Host $logMensagem -ForegroundColor Red }
  }

  # Salvar em arquivo
  Add-Content -Path $arquivoLOG -Value $logMensagem -ErrorAction SilentlyContinue
}

function espacoUsadoDisco {
  <#
    .SYNOPSIS
      Obtém o espaço em disco usado e disponível em uma unidade.
    .PARAMETER Drive
      A letra da unidade a ser verificada (padrão: C).
  #>

  param(
    [string]$Drive = 'C:'
  )
  
  $disco = Get-Volume -DriveLetter ($Drive[0]) -ErrorAction SilentlyContinue
  if ($disco){
    return @{
      Total = $disco.Size
      Usado = $disco.Size - $disco.SizeRemaining
      Livre = $disco.SizeRemaining
    }
  }
  return $null
}

function removeConteudoDiretorio {
  <#
    .SYNOPSIS
      Remove arquivos de um diretório com tratamento de erro melhorado.
    .PARAMETER Path
      O caminho do diretório a ser limpo.
    .PARAMETER Descricao
      Uma descrição do que está sendo removido.
  #>

  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [string]$Descricao
  )
  
  if (-not (Test-Path -Path $Path)){
    gravaLOG "Diretório não encontrado: $Path" -tipo Aviso
    return 0
  }
  
  $itensRemovidos = 0
  try {
    $items = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
    $items | ForEach-Object {
      try {
        Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
        $itensRemovidos++
      } catch {
        gravaLOG "Não foi possível remover: $($_.FullName) - $_" -tipo Aviso
      }
    }
    gravaLOG "$Description - Removidos $itensRemovidos itens" -tipo Info
  } catch {
    gravaLOG "Erro ao limpar $Path : $_" -tipo Erro
  }
  
  return $itensRemovidos
}

function paraProcessos {
  <#
    .SYNOPSIS
      Para um processo do sistema com tratamento seguro.
    .PARAMETER nomeProcesso
      O nome do processo a ser parado.
  #>

  param(
    [Parameter(Mandatory = $true)][string]$nomeProcesso
  )
  
  $processo = Get-Process -Name $nomeProcesso -ErrorAction SilentlyContinue
  if ($processo){
    try {
      $processo | Stop-Process -Force -ErrorAction Stop
      gravaLOG "Processo $nomeProcesso parado com sucesso" -tipo Info
      return $true
    } catch {
      gravaLOG "Erro ao parar $nomeProcesso : $_" -tipo Aviso
      return $false
    }
  }
  return $false
}

function iniciaProcessos {
  <#
    .SYNOPSIS
      Inicia um processo do sistema.
    .PARAMETER nomeProcesso
      O nome do processo a ser iniciado.
  #>

  param(
    [Parameter(Mandatory = $true)]
    [string]$nomeProcesso
  )
  
  try {
    Start-Process -FilePath $nomeProcesso -ErrorAction Stop
    gravaLOG "Processo $nomeProcesso iniciado com sucesso" -tipo Info
    return $true
  } catch {
    gravaLOG "Erro ao iniciar $nomeProcesso : $_" -tipo Aviso
    return $false
  }
}

function controlaServicos {
  <#
    .SYNOPSIS
      Para e inicia um serviço do Windows com tratamento de erro.
    .PARAMETER nomeServico
      O nome do serviço a ser controlado.
    .PARAMETER Acao
      A ação a ser realizada: 'Start' para iniciar ou 'Stop' para parar o serviço.
  #>

  param(
    [Parameter(Mandatory = $true)]
    [string]$nomeServico,
    
    [ValidateSet('Start', 'Stop')]
    [string]$Acao
  )

  try {
    $servico = Get-Service -Name $nomeServico -ErrorAction SilentlyContinue
    if ($servico) {
      if ($Acao -eq 'Stop'){
        $servico | Stop-Service -Force -ErrorAction Stop
      } else {
        $servico | Start-Service -ErrorAction Stop
      }
      gravaLOG "Serviço $nomeServico - Ação $Acao executada" -tipo Info
      return $true
    } else {
      gravaLOG "Serviço $nomeServico não encontrado" -tipo Aviso
      return $false
    }
  } catch {
    gravaLOG "Erro ao controlar serviço $nomeServico : $_" -tipo Aviso
    return $false
  }
}

#============================================================== SCRIPT PRINCIPAL

gravaLOG "LIMPEZA DE DISCO" -tipo Info

# Validar privilégios de administrador
if (-not (testaAcessoAdmin)){
  gravaLOG "ERRO CRÍTICO: Este script requer permissões de administrador!" -tipo Erro
  exit 1
}

gravaLOG "Script iniciado com privilégios administrativos" -tipo Info

# Mostrar espaço em disco antes
$diskBefore = espacoUsadoDisco
if ($diskBefore){
  $usadoGB = [math]::Round($diskBefore.Usado / 1GB, 2)
  $livreGB = [math]::Round($diskBefore.Livre / 1GB, 2)
  gravaLOG "Espaço em disco ANTES: $usadoGB GB usado / $livreGB GB disponível" -tipo Info
}

# ===== LIMPEZA 1: TEMP do usuário =====
gravaLOG " • [1/5] Iniciando limpeza de TEMP do usuário: $tempUser" -tipo Info
removeConteudoDiretorio -Path $tempUser -Descricao "TEMP do usuário"

# ===== LIMPEZA 2: TEMP do sistema =====
gravaLOG " • [2/5] Iniciando limpeza de TEMP do sistema: $tempSystem" -tipo Info
removeConteudoDiretorio -Path $tempSystem -Descricao "TEMP do sistema"

# ===== LIMPEZA 3: Cache de miniaturas =====
gravaLOG " • [3/5] Iniciando limpeza de cache de miniaturas" -tipo Info

if (paraProcessos -nomeProcesso "explorer"){
  Start-Sleep -Milliseconds 500
  removeConteudoDiretorio -Path $explorerCache -Descricao "Cache de miniaturas e ícones"
  iniciaProcessos -nomeProcesso "explorer"
} else {
  gravaLOG "Não foi possível parar o Explorer. Cache pode não ser limpo completamente." -tipo Aviso
}

# ===== LIMPEZA 4: Cache do Windows Update =====
gravaLOG " • [4/5] Iniciando limpeza de cache do Windows Update" -tipo Info

controlaServicos -nomeServico "wuauserv" -Acao "Stop"
controlaServicos -nomeServico "bits" -Acao "Stop"

Start-Sleep -Milliseconds 500
removeConteudoDiretorio -Path $updateCache -Descricao "Cache do Windows Update"

controlaServicos -nomeServico "wuauserv" -Acao "Start"
controlaServicos -nomeServico "bits" -Acao "Start"

# ===== LIMPEZA 5: Lixeira =====
gravaLOG " • [5/5] Iniciando limpeza da lixeira" -tipo Info

try {
  Clear-RecycleBin -Force -ErrorAction Stop
  gravaLOG "Lixeira esvaziada com sucesso" -tipo Info
} catch {
  gravaLOG "Erro ao limpar lixeira: $_" -tipo Aviso
}

# Mostrar espaço em disco depois
$diskAfter = espacoUsadoDisco
if ($diskAfter -and $diskBefore){
  $usadoGBdepois = [math]::Round($diskAfter.Usado / 1GB, 2)
  $livreGBdepois = [math]::Round($diskAfter.Livre / 1GB, 2)
  $liberadoGB = [math]::Round(($diskBefore.Livre - $diskAfter.Livre) / 1GB, 2)

  gravaLOG "Espaço em disco DEPOIS: $usadoGBdepois GB usado / $livreGBdepois GB disponível" -tipo Info
  gravaLOG "Espaço liberado com a limpeza: $liberadoGB GB" -tipo Info
}

gravaLOG "Limpeza de disco concluída" -tipo Info
Write-Host "Log salvo em: $arquivoLOG`n" -ForegroundColor Yellow