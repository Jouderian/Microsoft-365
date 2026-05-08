<#
  .SYNOPSIS
    Script de limpeza de disco corporativo otimizado para reduzir o espaço ocupado na máquina local.

  .DESCRIPTION
    Limpa arquivos temporários, caches e outros resíduos de lixo eletrônico presentes no sistema operacional
    e em TODOS os perfis de usuários em 'C:\Users'.

    O alcance da limpeza inclui:
    - Pastas temporárias de usuário e nativas de sistema logado
    - Arquivos de cache de todos os navegadores (Google Chrome, Microsoft Edge, Mozilla Firefox)
    - Banco de dados corrompidos ou cheios de miniaturas (Thumbnails) e ícones do File Explorer
    - Históricos e resíduos de instalação ou cache de atualização do Windows Update
    - Limpeza persistente da Lixeira (Recycle Bin)

    Observação técnica: Conta com proteções avançadas anti-deadlock (Timeout programado de 7 minutos
    no serviço 'wuauserv') garantindo o ciclo ininterrupto.

  .PARAMETER MostrarLogTerminal
    Ativa a saída interativa que ecoa os processamentos do log em tempo real para a tela do terminal
    do PowerShell usando cores informativas. Se omisso, restringe os logs puramente ao arquivo log
    gerado no $env:TEMP.

  .EXAMPLE
    .\removerArquivosTemporarios.ps1
    # Inicializa de forma silenciosa. O andamento fica salvo no arquivo de log (ex: Limpeza_Disco.log no %TEMP%).

  .EXAMPLE
    .\removerArquivosTemporarios.ps1 -MostrarLogTerminal
    # Executa a rotina exibindo instantaneamente todo o progresso no painel com identificação de erros, avisos e sucesso.

  .NOTES
    Contexto de Execução: Requer estritamente "Executar como Administrador" (Elevação UAC).

  .AUTHOR
    Felipe Jesus

  .COLABORADOR
    Jouderian Nobre

  .VERSION
    1 (27/03/25) - Criacao do script
    2 (30/03/24) - Ajustes para melhorar a performance, inclusão de mais diretorios e tratamento de erros
    3 (13/04/26) - Alteração para limpar temporários de todos os usuários da máquina e implementação
                   de contingência (Timeout via Job) para WinUpdate e suporte a param -MostrarLogTerminal
#>

[CmdletBinding()]
param (
  [switch]$MostrarLogTerminal
)

#===================================================================== VARIAVEIS
$temporariosUsuario = @()
$temporariosCache = @()
$temporariosNavegador = @()
$arquivoLOG = "$env:TEMP\Limpeza_Disco.log"

$updateCache = @(
  "C:\Windows\SoftwareDistribution\*",
  "C:\Windows\SoftwareDistribution\Download\*"
)

$tempSystem = @(
  "C:\Windows\Temp\*",
  "C:\Windows\System32\wbem\Logs\*",
  "C:\Windows\Logs\CBS\*"
)

$arquivosLOGs = @(
  "C:\Windows\inf\*.log",
  "C:\Windows\Logs\*.log",
  "C:\Windows\Logs\cbs\*.log",
  "C:\Windows\Logs\MoSetup\*.log",
  "C:\Windows\Panther\*.log",
  "C:\Windows\Microsoft.NET\*.log"
)

#======================================================================= FUNÇÕES
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

function gravaLOG {
  <#
    .SYNOPSIS
      Escreve log formatado no console e arquivo.
    .PARAMETER Mensagem
      A mensagem a ser registrada.
    .PARAMETER tipo
      O tipo de mensagem (Info, Aviso, Erro) para formatação e cor. Padrão é 'Info'.
    .PARAMETER mostraTempo
      Indica se o timestamp deve ser mostrado no console (padrão: $true).
  #>

  param(
    [Parameter(Mandatory = $true)][string]$Mensagem,
    [ValidateSet('Info', 'Aviso', 'Erro')][string]$tipo = 'Info',
    [Parameter(Mandatory = $false)][boolean]$mostraTempo = $true
  )

  if ($mostraTempo) {
    $tempo = "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) "
  }
  else {
    $tempo = ""
  }
  $logMensagem = "$tempo [$tipo] $Mensagem"

  # Salvar em arquivo
  Add-Content -Path $arquivoLOG -Value $logMensagem -ErrorAction SilentlyContinue

  if ($script:MostrarLogTerminal){
    if ($tipo -eq 'Aviso'){ 
      Write-Host $logMensagem -ForegroundColor Yellow
    } elseif ($tipo -eq 'Erro'){
      Write-Host $logMensagem -ForegroundColor Red
    } else { Write-Host $logMensagem -ForegroundColor White }
  }
}

function espacoUsadoDisco {
  <#
    .SYNOPSIS
      Obtém o espaço em disco usado e disponível em uma unidade.
    .PARAMETER Drive
      A letra da unidade a ser verificada (padrão: C).
    .OUTPUT
      Retorna um objeto com as propriedades Total, Usado e Livre em GB, ou $null se a unidade não for encontrada.
  #>

  param(
    [string]$Drive = 'C:'
  )

  $disco = Get-Volume -DriveLetter ($Drive[0]) -ErrorAction SilentlyContinue
  if ($disco) {
    return @{
      Total = [math]::Round($disco.Size / 1GB, 2)      
      Usado = [math]::Round($disco.Size - $disco.SizeRemaining / 1GB, 2)
      Livre = [math]::Round($disco.SizeRemaining / 1GB, 2)
    }
  }
  return $null
}

function excluirArquivos {
  <#
    .SYNOPSIS
      Exclui arquivos e diretórios especificados.
    .PARAMETER Arquivos
      A lista de arquivos ou diretórios a serem excluídos.
    .PARAMETER Mensagem
      A mensagem a ser registrada no log.
  #>

  param(
    [Parameter(Mandatory)][string[]]$Arquivos,
    [Parameter(Mandatory)][string]$Mensagem
  )

  $grupoAdmin = ([System.Security.Principal.SecurityIdentifier]"S-1-5-32-544").Translate([System.Security.Principal.NTAccount]).Value

  Foreach ($caminho in $Arquivos) {
    $itens = Get-ChildItem -Path $caminho -ErrorAction SilentlyContinue

    if (-not $itens) {
      gravaLOG "Nenhum item encontrado em $caminho" -tipo Aviso
      continue
    }

    try {
      takeown /A /R /D Y /F $caminho | Out-Null
      icacls $caminho /grant "$($grupoAdmin):F" /T /C | Out-Null
    }
    catch {
      gravaLOG "  [ERRO] Erro ao ajustar permissoes em $($caminho): $_" -tipo Erro
    }

    try {
      Remove-Item $caminho -Recurse -Force -ErrorAction SilentlyContinue
      gravaLOG "  [OK] $($Mensagem): '$caminho' excluido com sucesso" -tipo Info
    }
    catch {
      gravaLOG "  [ERRO] Erro ao excluir '$caminho': $_" -tipo Erro
    }
  }
}

#============================================================== SCRIPT PRINCIPAL
clear-host

Write-Host "Log sera salvo em: $arquivoLOG`n" -ForegroundColor Yellow

gravaLOG "Limpeza de disco iniciada..." -tipo Aviso -mostraTempo:$true

# Descobrindo os perfis de usuários e preenchendo as pastas para limpeza
$perfisUsuarios = Get-ChildItem -Path "C:\Users" -Directory -ErrorAction SilentlyContinue | Where-Object { 
  $_.Name -notin @("Public", "Default", "Default User", "All Users", "Publico") 
}

foreach ($perfil in $perfisUsuarios) {
  $localAppData = "$($perfil.FullName)\AppData\Local"

  gravaLOG "Identificamos o perfil de usuario: $($perfil.Name)" -tipo Info

  $temporariosUsuario += @(
    "$localAppData\Temp\*",
    "$localAppData\Microsoft\Windows\WebCache\*.log",
    "$localAppData\Microsoft\Windows\SettingSync\*.log",
    "$localAppData\Microsoft\Windows\Explorer\ThumbCacheToDelete\*.tmp",
    "$localAppData\Microsoft\Terminal Server Client\Cache\*.bin"
  )

  $temporariosCache += @(
    "$localAppData\Microsoft\Windows\Explorer\thumbcache_*.db",
    "$localAppData\Microsoft\Windows\Explorer\iconcache_*.db"
  )

  $temporariosNavegador += @(
    "$localAppData\Google\Chrome\User Data\Default\Cache\*",
    "$localAppData\Microsoft\Edge\User Data\Default\Cache\*",
    "$localAppData\Mozilla\Firefox\Profiles\*\cache2\*"
  )
}

# Validar privilégios de administrador
if (-not (testaAcessoAdmin)) {
  Write-Host "ATENCAO!!!`nEste script requer permissões de administrador" -ForegroundColor Red
  exit 1
}

# Mostrar espaÃ§o em disco antes
$discoAntes = espacoUsadoDisco
if ($discoAntes) {
  $usadoGB = $discoAntes.Usado
  $livreGB = $discoAntes.Livre
  gravaLOG "Espaco em disco ANTES: $usadoGB GB usado / $livreGB GB disponivel" -tipo Info
}

gravaLOG "[1/7] Iniciando limpeza de temporários dos usuários" -tipo Aviso
excluirArquivos $temporariosUsuario -Mensagem "Temporários dos usuários"

gravaLOG "[2/7] Iniciando limpeza de temporários do sistema" -tipo Aviso
excluirArquivos $tempSystem -Mensagem "Temporários do sistema"

gravaLOG "[3/7] Iniciando limpeza dos LOGs" -tipo Aviso
excluirArquivos $arquivosLOGs -Mensagem "LOGs do sistema"

gravaLOG "[4/7] Iniciando limpeza de cache de miniaturas" -tipo Aviso
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 700
excluirArquivos $temporariosCache -Mensagem "Cache de miniaturas e de ícones"
Start-Process explorer -ErrorAction SilentlyContinue

gravaLOG "[5/7] Iniciando limpeza de cache de navegadores" -tipo Aviso
excluirArquivos $temporariosNavegador -Mensagem "Cache de navegadores"

gravaLOG "[6/7] Iniciando limpeza de cache do Windows Update" -tipo Aviso
$job = Start-Job -ScriptBlock {
  Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
  Stop-Service bits -Force -ErrorAction SilentlyContinue
}
Wait-Job -Job $job -Timeout 420 | Out-Null
Stop-Job -Job $job -ErrorAction SilentlyContinue
Remove-Job -Job $job -ErrorAction SilentlyContinue

Start-Sleep -Milliseconds 700
excluirArquivos $updateCache -Mensagem "Cache do Windows Update"
Start-Service wuauserv -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 700
Start-Service bits -ErrorAction SilentlyContinue

gravaLOG "[7/7] Iniciando limpeza da lixeira" -tipo Aviso
try {
  Clear-RecycleBin -Force -ErrorAction Stop
  gravaLOG "  [OK] Lixeira esvaziada com sucesso" -tipo Info
}
catch {
  gravaLOG "  [ERRO] Erro ao limpar lixeira: $_" -tipo Erro
}

# Mostrar espaço em disco depois
$discoDepois = espacoUsadoDisco
if ($discoDepois -and $discoAntes) {
  $usadoGBdepois = $discoDepois.Usado
  $livreGBdepois = $discoDepois.Livre
  $liberadoGB = ($discoDepois.Livre - $discoAntes.Livre)

  gravaLOG "Espaco em disco DEPOIS: $usadoGBdepois GB usado / $livreGBdepois GB disponivel" -tipo Info
  gravaLOG "Espaco liberado com a limpeza: $liberadoGB GB" -tipo Aviso
}

gravaLOG "Limpeza de disco concluida" -tipo Aviso
Write-Host "Log salvo em: $arquivoLOG`n" -ForegroundColor Yellow