#--------------------------------------------------------------------------------------------------------
# Descricao: Extrair uma listagem com todas as caixas postais do Microsoft 365
# Versao 01 (03/11/22) Jouderian Nobre
# ...
# Versao 14 (08/01/25) Jouderian Nobre: Inclusao da ocupacao da caixa de arquivamento
# Versao 15 (10/01/25) Jouderian Nobre: Inclusao de novas licencas na relacao
# Versao 16 (17/01/25) Jouderian Nobre: Remocao da coluna itens da caixa postal
# Versao 17 (20/02/25) Jouderian Nobre: Inclusao da licenca PowerApps Premium
# Versao 18 (24/03/25) Jouderian Nobre: Adequacao para usar o MgGraph e seus comandos
# Versao 19 (14/04/25) Jouderian Nobre: Otimizacao do script com uso de funcoes
#--------------------------------------------------------------------------------------------------------

Clear-Host

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

#--------------------------------------------------------------------- VARIAVEIS
$indice = 0
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaDeCaixasPostais.csv"

#-------------------------------------------------------------------- VALIDACOES
VerificaModulo -NomeModulo "Microsoft.Graph" -MensagemErro "O modulo Microsoft Graph e necessario e nao esta instalado no sistema."
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema."

try {
  Import-Module -Name Microsoft.Graph.Users
  Connect-MgGraph -Scopes "User.Read.All", "MailboxSettings.Read", "Directory.Read.All" -NoWelcome
} catch {
  Write-Host "Erro ao conectar ao Microsoft Graph: $_" -ForegroundColor Red
  Exit
}

try {
  Connect-ExchangeOnline
} catch {
  Write-Host "Erro ao conectar ao Exchange Online: $_" -ForegroundColor Red
  Exit
}

$inicio = Get-Date
Write-Host "`n`n`n`n`n`n`nInicio:" $inicio
Write-Host Pesquisando Relacao de Caixas Postais no ExchangeOnline...
$caixas = Get-MgUser `
  -ALL `
  -ConsistencyLevel eventual `
  -Property "Id,DisplayName,UserPrincipalName,City,State,CompanyName,OfficeLocation,Department,JobTitle,PostalCode,StreetAddress,OnPremisesSyncEnabled,AccountEnabled,PasswordPolicies,CreatedDateTime,LastPasswordChangeDateTime,OnPremisesLastSyncDateTime"

$caixas = $caixas | Where-Object {
  $_.UserPrincipalName -notlike "*#EXT#*"
}

$totalCaixas = $caixas.Count

Write-Output "Nome,UPN,Cidade,UF,Empresa,Escritorio,Departamento,Cargo,Gerente,CC,nomeCC,Tipo,AD,Desabilitada,SenhaForte,SenhaNaoExpira,Compartilhada,Encaminhada,Litigio,usado(GB),Arquivamento,Arquivamento(GB),Criacao,MudancaSenha,ultimoSyncAD,ultimoAcesso,conta,objectId,Licencas,outrasLicencas" > $arquivo

Foreach ($caixa in $caixas){

  $indice++

  if ($indice % 10 -eq 0){ # Atualiza o progresso a cada 10 caixas processadas
    Write-Progress -Activity "Exportando caixas postais" -Status "Progresso: $indice de $totalCaixas extraidas" -PercentComplete (($indice / $totalCaixas) * 100)
  }

  $detalheCaixa = Get-MailboxStatistics -Identity $caixa.Id
  $licencas = Get-MgUserLicenseDetail -UserId $caixa.Id
  $tamanho = [math]::Round((($detalheCaixa.TotalItemSize.Value.ToString()).Split('(')[1].Split(' ')[0].Replace(',','')/1GB),2)

  if($detalheCaixa.IsArchiveMailbox -eq 'Active'){
    $detalheArquivo = Get-MailboxStatistics -Identity $caixa.ExternalDirectoryObjectId -Archive
    $tamanhoArquivamento = [math]::Round((($detalheArquivo.TotalItemSize.Value.ToString()).Split('(')[1].Split(' ')[0].Replace(',','')/1GB),2)
  } else {
    $tamanhoArquivamento = 0
  }
  
  try {
    $gerente = Get-MgUserManager -UserId $caixa.Id
    $gerente = $gerente.AdditionalProperties.displayName    
  } catch {
    $gerente = ""
  }

  $infoCaixa = "$($caixa.DisplayName)," # Nome
  $infoCaixa += "$($caixa.UserPrincipalName)," # UPN
  $infoCaixa += "$($caixa.City)," # Cidade
  $infoCaixa += "$($caixa.State)," # UF
  $infoCaixa += "$($caixa.CompanyName)," # Empresa
  $infoCaixa += "$($caixa.OfficeLocation)," # Escritorio
  $infoCaixa += [System.String]::Concat("""","$($caixa.Department)",""",") # Departamento
  $infoCaixa += [System.String]::Concat("""","$($caixa.JobTitle)",""",") # Cargo
  $infoCaixa += "$($gerente)," #Gerente
  $infoCaixa += "$($caixa.postalCode)," # CC
  $infoCaixa += "$($caixa.streetAddress)," # nomeCC
  $infoCaixa += "$($detalheCaixa.MailboxTypeDetail.Value)," # Tipo
  $infoCaixa += "$($caixa.OnPremisesSyncEnabled)," # AD
  $infoCaixa += "$($caixa.AccountEnabled)," # Desabilitada
  $infoCaixa += "$($caixa.PasswordPolicies -contains "DisableStrongPassword")," # SenhaForte
  $infoCaixa += "$($caixa.PasswordPolicies -contains "DisablePasswordExpiration")," # SenhaNaoExpira
  $infoCaixa += "," # Compartilhada
  $infoCaixa += "," # Encaminhada
  $infoCaixa += "," # Litigio
  $infoCaixa += "$($tamanho)," # usado(GB)
  $infoCaixa += "$($detalheCaixa.IsArchiveMailbox)," # Arquivamento
  $infoCaixa += "$($tamanhoArquivamento)," # Arquivamento(GB)
  $infoCaixa += "$($caixa.CreatedDateTime.ToString('dd/MM/yy HH:mm'))," # Criacao
  $infoCaixa += "$($caixa.LastPasswordChangeDateTime.ToString('dd/MM/yy HH:mm'))," # MudancaSenha

  $momento = $caixa.OnPremisesLastSyncDateTime # ultimoSyncAD
  if($null -eq $momento){
    $infoCaixa += ","
  } Else {
    $infoCaixa += "$($momento.ToString('dd/MM/yy HH:mm')),"
  }

  $momento = $detalheCaixa.LastUserActionTime # ultimoAcesso
  if($null -eq $momento){
    $infoCaixa += ","
  } Else {
    $infoCaixa += "$($momento.ToString('dd/MM/yy HH:mm')),"
  }

  $infoCaixa += "," # conta
  $infoCaixa += "$($caixa.Id)," # objectId

  $licencaPaga = ""
  $outrasLicencas = ""

  Foreach ($licenca in $licencas){
    $nomeLicenca = ObterDescricaoLicenca -SkuPartNumber $licenca.SkuPartNumber
    if($null -eq $nomeLicenca){
      $outrasLicencas += [System.String]::Concat("+", $licenca.SkuPartNumber)
    } else {
      $licencaPaga += [System.String]::Concat("+", $nomeLicenca)
    }
  }
  $infoCaixa += [System.String]::Concat("""","$($licencaPaga)",""",") # Licencas
  $infoCaixa += [System.String]::Concat("""","$($outrasLicencas)","""") # outrasLicencas

  Write-Output $infoCaixa >> $arquivo
}

Write-Progress -Activity "Exportando caixas postais" -PercentComplete 100

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()

Disconnect-ExchangeOnline -Confirm:$false
Disconnect-MgGraph