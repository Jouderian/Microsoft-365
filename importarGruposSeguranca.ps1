<#
  .SYNOPSIS
    Script para criar grupos de seguranca lendo um arquivo CSV via Microsoft Graph
  .DESCRIPTION
    Este script importa dados tabulares de um arquivo CSV, contendo as colunas Nome, Descricao 
    e eMailProprietário para automatizar o roteamento de Grupos de Segurança puros no Azure AD 
    (sem email habilitado) definindo seus respectivos Owners por referencia.
  .AUTHOR
    Jouderian Nobre
  .VERSION
    01 (10/04/26) - Criacao inicial guiada por SDD
  .OUTPUT
    Logs em arquivo .txt na pasta WindowsPowerShell do OneDrive e Console.
#>

Clear-Host
. ".\bibliotecaDeFuncoes.ps1"

# Variaveis iniciais
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\importarGruposSeguranca_$($inicio.ToString('yyyyMMdd')).txt"
$arquivoCsv = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\gruposSeguranca.csv"
$delimitador = ";"

gravaLOG "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))" -tipo WRN -arquivo $logs
gravaLOG "Iniciando processo de importacao do Microsoft Graph" -tipo INF -arquivo $logs -mostraTempo $true

VerificaModulo -NomeModulo "Microsoft.Graph.Authentication" -MensagemErro "Modulo msGraph Auth ausente no console." -arquivoLogs $logs
VerificaModulo -NomeModulo "Microsoft.Graph.Groups" -MensagemErro "Modulo msGraph Groups defasado ou nao instalado." -arquivoLogs $logs
VerificaModulo -NomeModulo "Microsoft.Graph.Users" -MensagemErro "Modulo msGraph Users nao encontrado." -arquivoLogs $logs

gravaLOG "Acionando tentativa de autenticacao msGraph interativa" -tipo INF -arquivo $logs
try {
  Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read.All" -NoWelcome
  gravaLOG "Ambiente msGraph logado." -tipo OK -arquivo $logs
}
catch {
  gravaLOG "Autenticacao recusada: $($_.Exception.Message)" -tipo ERR -arquivo $logs
  Exit 1
}

if (-not (Test-Path $arquivoCsv)) {
  gravaLOG "Erro: Arquivo CSV origem nao localizado [$arquivoCsv]. Operacao abortada." -tipo ERR -arquivo $logs
  Exit 1
}

$dadosCsv = Import-Csv -Path $arquivoCsv -Delimiter $delimitador
$totalItens = $dadosCsv.Count
$contador = 0

gravaLOG "Base de dados carregada, rastreados $totalItens Grupos novos na fila." -tipo OK -arquivo $logs

foreach ($linha in $dadosCsv) {
  $contador++
  $nome = $linha.Nome
  $descricao = $linha.Descricao
  $emailOwner = $linha.eMailProprietario

  if (!$nome -or !$emailOwner) {
    gravaLOG "Coluna 'Nome' ou 'eMailProprietario' vazia. Pulando indice $contador." -tipo ERR -arquivo $logs
    continue
  }

  # O MailNickname não permite espaços nem acentos
  $apelidoTratado = trataTexto $nome
  $apelidoTratado = removerAcentos $apelidoTratado

  Write-Progress -Activity "Provisionamento Security Groups M365" -Status "Despachando: $nome ($contador / $totalItens)" -PercentComplete (($contador / $totalItens) * 100)

  try {
    gravaLOG "Inspecionando dados de Active Directory do User: $emailOwner" -tipo STP -arquivo $logs
    $proprietario = Get-MgUser -UserId $emailOwner -ErrorAction Stop

    gravaLOG "Criando a identidade do Grupo => Nome $nome | Alias $apelidoTratado" -tipo STP -arquivo $logs
    $novoGrupo = New-MgGroup `
      -DisplayName $nome `
      -Description $descricao `
      -MailEnabled:$false `
      -SecurityEnabled:$true `
      -MailNickname $apelidoTratado `
      -ErrorAction Stop

    gravaLOG "Grupo criado no M365 perfeitamente com ID $($novoGrupo.Id)" -tipo OK -arquivo $logs

    gravaLOG "Atribuindo proprietario ao grupo: $($proprietario.DisplayName)" -tipo STP -arquivo $logs
    New-MgGroupOwner `
      -GroupId $novoGrupo.Id `
      -DirectoryObjectId $proprietario.Id `
      -ErrorAction Stop

    gravaLOG "Proprietario $proprietario.DisplayName atribuido ao grupo: $nome." -tipo OK -arquivo $logs

  }
  catch {
    gravaLOG "(!) Excecao grave no lote [$nome]: $($_.Exception.Message)" -tipo ERR -arquivo $logs
  }
}

# Finalizando o script
$final = Get-Date
gravaLOG -texto "Duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())" -tipo WRN -arquivo $logs -mostraTempo:$true