<#
  .SYNOPSIS
    Apaga fisicamente Listas de Distribuição e Grupos de Segurança M365 sem membros do ambiente
  .DESCRIPTION
    Concebido para varrer de forma rapida as Distribution Lists via ExchangeOnline e 
    os Grupos de Segurança via Microsoft Graph buscando grupos sem membros relacionados e promovendo sua exclusão definitiva.
  .AUTHOR
    Jouderian Nobre
  .VERSION
    01 (10/04/26) - Criacao inicial focada em performance e direcionada SDD
  .OUTPUT
    Logs em arquivo txt na pasta do WindowsPowerShell e Console (nao ha geracao de arquivos CSV)
#>

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Setup Inicial
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\apagadasVazias_$($inicio.ToString('yyyyMMdd_HHmmss')).txt"
$indice = 0

gravaLOG "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))" -tipo WRN -arquivo $logs
gravaLOG "Iniciando processo de Caca fantasma: Limpeza de Grupos Vazios" -tipo INF -arquivo $logs -mostraTempo:$true

# Dependências
Write-Host "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Conectando ao Exchange Online..."
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O módulo Exchange Online Management é necessário e não está instalado no sistema." -arquivoLogs $logs
try {
  Connect-ExchangeOnline -ShowBanner:$false
}
catch {
  Write-Host "Erro ao conectar ao Exchange Online: $($_.Exception.Message)" -ForegroundColor Red
  Exit
}

Write-Host "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Conectando ao Microsoft Graph..."
VerificaModulo -NomeModulo "Microsoft.Graph" -MensagemErro "O módulo Microsoft.Graph é necessário e não está instalado no sistema." -arquivoLogs $logs
try {
  Connect-MgGraph -Scopes "Group.ReadWrite.All", "GroupMember.Read.All" -NoWelcome -ErrorAction Stop
}
catch {
  Write-Host "Erro ao conectar ao Microsoft Graph: $($_.Exception.Message)" -ForegroundColor Red
  Exit
}

gravaLOG "Indexando Listas de Distribuicao..." -tipo STP -arquivo $logs
$Listas = Get-DistributionGroup -ResultSize Unlimited
$totalListas = $Listas.Count
gravaLOG "Encontradas $totalListas Listas de Distribuicao (Exchange)." -tipo STP -arquivo $logs

gravaLOG "Indexando Grupos de Seguranca..." -tipo STP -arquivo $logs
$GruposSeguranca = Get-MgGroup -Filter "securityEnabled eq true" -All
$totalGrupos = $GruposSeguranca.Count
gravaLOG "Encontrados $totalGrupos Grupos de Seguranca (MsGraph)." -tipo STP -arquivo $logs

$total = $totalListas + $totalGrupos

# Processamento Listas de Distribuicao
foreach ($Lista in $Listas) {
  $indice++
  Write-Progress -Activity "Verificando e Limpando Diretório" -Status "Analisando Exchange: $($Lista.DisplayName)" -PercentComplete (($indice / $total) * 100)
  
  $Membros = Get-DistributionGroupMember -Identity $Lista.ExternalDirectoryObjectId
  if (($Membros.Length -eq 0) -or ($null -eq $Membros)) {
    if ($Lista.IsDirSynced -eq $true) {
      gravaLOG "$($Lista),$($Lista.PrimarySmtpAddress),$($Lista.ExternalDirectoryObjectId),Bloqueado - Sincronizada localmente via AD" -tipo WRN -arquivo $logs
      continue
    }

    try {
      Remove-DistributionGroup -Identity $Lista.ExternalDirectoryObjectId -Confirm:$false
      gravaLOG "D-LIST,$($Lista.DisplayName),$($Lista.PrimarySmtpAddress),$($Lista.ExternalDirectoryObjectId),Excluida (Sem Membros)" -tipo OK -arquivo $logs
    }
    catch {
      gravaLOG "D-LIST,$($Lista.DisplayName),$($Lista.PrimarySmtpAddress),$($Lista.ExternalDirectoryObjectId),ERRO ao Excluir: $($_.Exception.Message)" -tipo ERR -arquivo $logs
    }
  }
}

# Processamento Grupos de Segurança MSGraph
foreach ($Grupo in $GruposSeguranca) {
  $indice++
  Write-Progress -Activity "Verificando e Limpando Diretório" -Status "Analisando Graph: $($Grupo.DisplayName)" -PercentComplete (($indice / $total) * 100)

  $Membros = Get-MgGroupMember -GroupId $Grupo.Id -All
  if (($Membros.Count -eq 0) -or ($null -eq $Membros)) {
    if ($Grupo.OnPremisesSyncEnabled -eq $true) {
      gravaLOG "S-GROUP,$($Grupo.DisplayName),$($Grupo.Mail),$($Grupo.Id),Bloqueado - Sincronizado localmente via AD" -tipo WRN -arquivo $logs
      continue
    }

    try {
      Remove-MgGroup -GroupId $Grupo.Id
      gravaLOG "S-GROUP,$($Grupo.DisplayName),$($Grupo.Mail),$($Grupo.Id),Excluido (Sem Membros)" -tipo OK -arquivo $logs
    }
    catch {
      gravaLOG "S-GROUP,$($Grupo.DisplayName),$($Grupo.Mail),$($Grupo.Id),ERRO ao Excluir: $($_.Exception.Message)" -tipo ERR -arquivo $logs
    }
  }
}
Write-Progress -Activity "Verificando e Limpando Diretório" -PercentComplete 100

# Desconectar
gravaLOG "Rotinas finalizadas e espurgadas... Desconectando Sessions..." -tipo STP -arquivo $logs
Disconnect-ExchangeOnline -Confirm:$false
Disconnect-MgGraph

$final = Get-Date
gravaLOG "Tempo: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())" -tipo WRN -arquivo $logs
