<#
.SYNOPSIS
  Importa os membros de um Grupo
.DESCRIPTION
  O script se conecta ao ambiente do Azure AD, importa as informações gravadas no arquivo CSV e adiciona os membros ao grupo.
.AUTHOR
  Jouderian Nobre
.VERSION
  01 (25/07/23) - Criacao do script
  02 (29/12/24) - Passa a ler a variavel do Windows para local do arquivo
  03 (05/04/26) - Atualizacao da documentacao
  04 (11/04/26) - Passa a usar o Graph API e importa os dados via CSV
#>

Clear-Host

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

# Variaveis iniciais
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\importarMembrosGrupos_$($inicio.ToString('yyyyMMdd_HHmmss')).txt"
$arquivoCsv = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\membrosGruposSeguranca.csv"
$delimitador = ";"

gravaLOG "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))" -tipo WRN -arquivo $logs
gravaLOG "Iniciando inclusao de novos membros em Grupo (M365) via Arquivo CSV" -tipo INF -arquivo $logs -mostraTempo:$true

VerificaModulo -NomeModulo "Microsoft.Graph.Authentication" -MensagemErro "Modulo msGraph Auth ausente no console." -arquivoLogs $logs
VerificaModulo -NomeModulo "Microsoft.Graph.Groups" -MensagemErro "Modulo msGraph Groups defasado ou nao instalado." -arquivoLogs $logs
VerificaModulo -NomeModulo "Microsoft.Graph.Users" -MensagemErro "Modulo msGraph Users nao encontrado." -arquivoLogs $logs

gravaLOG "Acionando tentativa de autenticacao msGraph interativa" -tipo INF -arquivo $logs
try {
  Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read.All" -NoWelcome
  gravaLOG "Ambiente msGraph Autenticado" -tipo OK -arquivo $logs
}
catch {
  gravaLOG "Falha critica no login Graph: $($_.Exception.Message)" -tipo ERR -arquivo $logs
  Exit 1
}

# Verificando pacote de input
if (-not (Test-Path $arquivoCsv)) {
  gravaLOG "Planilha CSV nao encontrada ($arquivoCsv)." -tipo ERR -arquivo $logs
  Exit 1
}

$dadosCsv = Import-Csv -Path $arquivoCsv -Delimiter $delimitador
$totalItens = $dadosCsv.Count
$contador = 0

gravaLOG "Preparando para comitar a adicao de $totalItens requisicoes..." -tipo OK -arquivo $logs

foreach ($linha in $dadosCsv) {
  $contador++
  $nome = $linha.nomeGrupo
  $email = $linha.eMailUsuario

  if (!$nome -or !$email) {
    gravaLOG "Coluna 'nomeGrupo' ou 'eMailUsuario' vazia. Pulando indice $contador." -tipo ERR -arquivo $logs
    continue
  }

  Write-Progress -Activity "Adicionando membros ao grupo M365" -Status "Incluindo: $email > $nome ($contador / $totalItens)" -PercentComplete (($contador / $totalItens) * 100)

  try {
    gravaLOG "Pesquisando Membro via UPN ($email) para alocar no Grupo ($nome)" -tipo STP -arquivo $logs
    # Descobrindo o UPN/User
    $usuarioID = Get-MgUser -UserId $email -ErrorAction Stop

    # Descobrindo o Grupo - Consultando o DisplayName exato usando Filter
    $grupoID = Get-MgGroup -ConsistencyLevel eventual -Filter "DisplayName eq '$nome'" -ErrorAction Stop

    # Verificação rígida caso retorne limpo
    if (!$grupoID) {
      gravaLOG "O grupo '$nome' nao foi localizado. Verifique a digitaçao/typo na Planilha!" -tipo ERR -arquivo $logs
      continue
    }

    $alvoAgrupado = $grupoID | Select-Object -First 1

    if ([string]::IsNullOrWhiteSpace($alvoAgrupado.Id)) {
      $tipoObjeto = if ($alvoAgrupado) { $alvoAgrupado.GetType().Name } else { "Nulo" }
      gravaLOG "O grupo '$nome' nao foi pesquisado corretamente ou seu ID veio em branco (Tipo: $tipoObjeto). O script MgGraph atual pode exigir '-Property Id' explícito!" -tipo ERR -arquivo $logs
      continue
    }

    $referenciaGrupoId = $alvoAgrupado.Id
    $nomeIdentificado = $alvoAgrupado.DisplayName

    gravaLOG "Cadastrado usuario $($usuarioID.UserPrincipalName) no grupo $nomeIdentificado" -tipo STP -arquivo $logs

    New-MgGroupMember `
      -GroupId $referenciaGrupoId `
      -DirectoryObjectId $usuarioID.Id `
      -ErrorAction Stop

    gravaLOG "Inclusao de $email no grupo $nomeIdentificado realizada com sucesso." -tipo OK -arquivo $logs

  }
  catch {
    gravaLOG "Erro ao incluir usuario [$email] no grupo [$nome]: $($_.Exception.Message)" -tipo ERR -arquivo $logs
  }

}

# Finalizando o script
$final = Get-Date
gravaLOG -texto "Operacao terminada. Duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())" -tipo WRN -arquivo $logs -mostraTempo:$true