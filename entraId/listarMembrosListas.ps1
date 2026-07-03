<#
  .SYNOPSIS
    Lista a relação de membros das Listas de Distribuição e Grupos de Segurança do M365.
  .DESCRIPTION
    Conecta ao Exchange Online e ao Microsoft Graph para exportar todos os membros de:
    - Listas de Distribuição (Exchange Online via Get-DistributionGroup)
    - Grupos de Segurança sem e-mail (EntraID via Get-MgGroup)

    O script opera em dois modos:
    - ApenasListar (padrão): exporta membros e registra grupos/listas vazios em log de auditoria.
    - ListarEApagar: além de exportar, remove grupos e listas vazios (exceto sincronizados com AD).

    Para Grupos de Segurança, os metadados dos membros (displayName, UPN, tipo) são obtidos
    em uma única chamada ao Graph via -Property, eliminando o anti-padrão N+1.

    Para Listas de Distribuição, os membros são obtidos via Get-DistributionGroupMember (fonte
    completa, inclui Mail Contacts externos). Os membros com ExternalDirectoryObjectId têm o UPN
    enriquecido via Graph em lote (Get-MgUser -Filter "id in (...)", uma chamada por lista).
    Mail Contacts puros (sem ExternalDirectoryObjectId) usam PrimarySMTPAddress como fallback.
  .PARAMETER Acao
    Define o comportamento para grupos/listas vazios:
    - ApenasListar: apenas registra no log (padrão).
    - ListarEApagar: remove do ambiente (irreversível).
  .AUTHOR
    Jouderian Nobre
  .VERSION
    01 (25/01/22) - Criacao do script
    02 (29/04/25) - Otimizacao do script com uso de funcoes
    03 (28/05/25) - Otimizando a logica de exclusao das listas vazias
    04 (17/12/25) - Incluindo Grupos de Segurança via Microsoft Graph
    05 (26/03/26) - Otimizacao do script para melhorar a performance
    06 (05/04/26) - Inclusão do parametro Acao para listar ou apagar listas vazias
    07 (11/04/26) - Eliminado Get-MgUser por membro (N+1 → 1 chamada por grupo via -Property) Uso de
                    UPN (userPrincipalName) para membros dos Grupos de Segurança
    08 (12/04/26) - Enriquecimento híbrido de UPN para membros de DLs: Graph em lote para membros
                    com EntraID, fallback PrimarySMTPAddress para Mail Contacts externos
  .OUTPUT
    membrosListasGrupos.csv — CSV com todos os membros, separado por ponto-e-vírgula.
    Colunas: idGrupo; nomeGrupo; eMailGrupo; adSync; tipoGrupo; idMembro; membro; tipo; eMailMembro
    listasVazias_<timestamp>.txt — log de auditoria de grupos/listas vazios ou excluídos.
  .EXAMPLE
    .\listarMembrosListas.ps1
    .\listarMembrosListas.ps1 -Acao ListarEApagar
#>

[CmdletBinding()]
param (
  [ValidateSet("ApenasListar", "ListarEApagar")][string]$Acao = "ApenasListar"
)

. "$env:ONEDRIVE\Documentos\WindowsPowerShell\Scripts\PUBLICO\Microsoft-365\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$indice = 0
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listasVazias_$($inicio.ToString('yyMMdd_HHmmss')).txt"
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\membrosListasGrupos.csv"
$buffer = @()

gravaLOG "Conectando ao Exchange Online..." -mostraTempo $true -tipo WRN
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O módulo Exchange Online Management é necessário e não está instalado no sistema."
try {
  Connect-ExchangeOnline -ShowBanner:$false
} catch {
  gravaLOG "Erro ao conectar ao Exchange Online: $($_.Exception.Message)" -mostraTempo $true -tipo ERR
  Exit
}

gravaLOG "Conectando ao Microsoft Graph..." -mostraTempo $true -tipo INF
VerificaModulo -NomeModulo "Microsoft.Graph" -MensagemErro "O módulo Microsoft.Graph é necessário e não está instalado no sistema."
try {
  Connect-MgGraph -Scopes "Group.Read.All", "User.Read.All" -ErrorAction Stop -NoWelcome
} catch {
  gravaLOG "Erro ao conectar ao Microsoft Graph: $($_.Exception.Message)" -mostraTempo $true -tipo ERR
  Exit
}

gravaLOG "Pesquisando Listas de Distribuicao e Grupos de Segurança..." -mostraTempo $true -tipo INF
$Listas = Get-DistributionGroup -ResultSize Unlimited
gravaLOG "$($Listas.Count) Listas de Distribuicao encontradas." -mostraTempo $true -tipo OK

gravaLOG "Pesquisando Grupos de Segurança..." -mostraTempo $true -tipo INF
$GruposSeguranca = Get-MgGroup -Filter "securityEnabled eq true" -All
gravaLOG "$($GruposSeguranca.Count) Grupos de Segurança encontrados." -mostraTempo $true -tipo OK

$total = $Listas.Count + $GruposSeguranca.Count

Out-File -FilePath $arquivo -InputObject "idGrupo;nomeGrupo;eMailGrupo;adSync;tipoGrupo;idMembro;membro;tipo;eMailMembro" -Encoding UTF8
Foreach ($Lista in $Listas){

  $indice++
  Write-Progress -Activity "Exportando Listas/Grupos" -Status "Progresso: $indice/$total - $($Lista.DisplayName)" -PercentComplete (($indice / $total) * 100)

  $Membros = Get-DistributionGroupMember -Identity $Lista.ExternalDirectoryObjectId
  if ($Membros.Length -eq 0){

    if ($Lista.IsDirSynced -eq $true){
      gravaLOG "$($Lista.DisplayName);$($Lista.PrimarySmtpAddress);$($Lista.ExternalDirectoryObjectId);Sincronizada AD" -arquivo $logs
      continue
    }

    if ($Acao -eq "ListarEApagar"){
      # Removendo listas vazias
      try {
        Remove-DistributionGroup -Identity $Lista.ExternalDirectoryObjectId -Confirm:$false
        gravaLOG "$($Lista.DisplayName);$($Lista.PrimarySmtpAddress);$($Lista.ExternalDirectoryObjectId);Excluida" -arquivo $logs
      } catch { 
        gravaLOG "$($Lista.DisplayName);$($Lista.PrimarySmtpAddress);$($Lista.ExternalDirectoryObjectId);ERRO: $($_.Exception.Message)" -arquivo $logs -tipo ERR
      }
    } else {
      gravaLOG "$($Lista.DisplayName);$($Lista.PrimarySmtpAddress);$($Lista.ExternalDirectoryObjectId);Lista vazia" -arquivo $logs
    }
    continue
  }

  # Separa membros com e sem representação no Entra ID
  $membrosComID = $Membros | Where-Object { $_.ExternalDirectoryObjectId }

  # Enriquece UPN via Graph em lote — uma chamada por lista, não por membro
  # O filtro 'id in (...)' do Graph suporta até 15 IDs por requisição
  $upnMap = @{}
  if ($membrosComID){
    $ids = @($membrosComID | ForEach-Object { $_.ExternalDirectoryObjectId })
    $tamanhLote = 15
    for ($i = 0; $i -lt $ids.Count; $i += $tamanhLote){
      $lote = $ids[$i..([Math]::Min($i + $tamanhLote - 1, $ids.Count - 1))]
      $filtro = "id in ('" + ($lote -join "','") + "')"
      $usuarios = Get-MgUser -Filter $filtro -Property "id,userPrincipalName" -ConsistencyLevel eventual -ErrorAction SilentlyContinue
      foreach ($u in $usuarios){
        $upnMap[$u.Id] = $u.UserPrincipalName
      }
    }
  }

  Foreach ($Membro in $Membros){
    # Usa UPN do Entra ID quando disponível; fallback para PrimarySMTPAddress (Mail Contacts externos)
    $eMail = if ($Membro.ExternalDirectoryObjectId -and $upnMap.ContainsKey($Membro.ExternalDirectoryObjectId)) {
      $upnMap[$Membro.ExternalDirectoryObjectId]
    } else {
      $Membro.PrimarySMTPAddress
    }
    $buffer += "$($Lista.ExternalDirectoryObjectId);$($Lista.DisplayName);$($Lista.PrimarySMTPAddress);$($Lista.IsDirSynced);$($Lista.RecipientType);$($Membro.ExternalDirectoryObjectId);$($Membro.DisplayName);$($Membro.RecipientType);$eMail"
  }

  Add-Content -Path $arquivo -Value $buffer -Encoding UTF8
  $buffer = @()
}

Foreach ($Grupo in $GruposSeguranca){

  $indice++
  Write-Progress -Activity "Exportando Listas/Grupos" -Status "Progresso: $indice/$total - $($Grupo.DisplayName)" -PercentComplete (($indice / $total) * 100)

  # Solicita mail e @odata.type junto com os membros para evitar N chamadas extras de Get-MgUser
  # @odata.type é retornado automaticamente pelo Graph — não pode ser incluído no $select
  $Membros = Get-MgGroupMember -GroupId $Grupo.Id -All -Property "id,displayName,userPrincipalName"
  if ($Membros.Count -eq 0){
    if ($Grupo.OnPremisesSyncEnabled -eq $true){
      gravaLOG "$($Grupo.DisplayName);$($Grupo.Mail);$($Grupo.Id);Sincronizado AD — ignorado" -arquivo $logs
      continue
    }

    if ($Acao -eq "ListarEApagar"){
      try {
        Remove-MgGroup -GroupId $Grupo.Id
        gravaLOG "$($Grupo.DisplayName);$($Grupo.Mail);$($Grupo.Id);Grupo de Segurança excluido" -arquivo $logs
      } catch {
        gravaLOG "$($Grupo.DisplayName);$($Grupo.Mail);$($Grupo.Id);ERRO: $($_.Exception.Message)" -arquivo $logs -tipo ERR
      }
    } else {
      gravaLOG "$($Grupo.DisplayName);$($Grupo.Mail);$($Grupo.Id);Grupo de Segurança vazio" -arquivo $logs
    }
    continue
  }

  Foreach ($Membro in $Membros){
    # Get-MgGroupMember retorna DirectoryObject: apenas Id é propriedade direta.
    # displayName, mail e @odata.type chegam em AdditionalProperties via -Property.
    $odataType = $Membro.AdditionalProperties['@odata.type']
    $tipo = if ($odataType -eq '#microsoft.graph.user') { 'User' } else { 'Other' }
    $nome = $Membro.AdditionalProperties['displayName']
    $upn = $Membro.AdditionalProperties['userPrincipalName']
    $buffer += "$($Grupo.Id);$($Grupo.DisplayName);$($Grupo.Mail);$($Grupo.OnPremisesSyncEnabled);Security;$($Membro.Id);$nome;$tipo;$upn"
  }

  Add-Content -Path $arquivo -Value $buffer -Encoding UTF8
  $buffer = @()
}

Write-Progress -Activity "Exportando Listas/Grupos" -Completed

gravaLOG "Desconectando..." -tipo INF -mostraTempo $true
Disconnect-ExchangeOnline -Confirm:$false
Disconnect-MgGraph

$final = Get-Date
gravaLOG "Duração total: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())" -tipo WRN