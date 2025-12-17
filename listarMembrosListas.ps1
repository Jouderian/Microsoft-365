#-------------------------------------------------------------------------------
# Descricao: Lista a relacao de membros das Listas e Grupos do M365, incluindo Grupos de Segurança
# Versao 1 (25/01/22) Jouderian Nobre
# :::
# Versao 8 (29/04/25) Jouderian Nobre: Otimizacao do script com uso de funcoes
# Versao 9 (28/05/25) Jouderian Nobre: Otimizando a logica de exclusao das listas vazias
# Versao 10 (17/12/25) Jouderian Nobre: Incluindo Grupos de Segurança via Microsoft Graph
#-------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$indice = 0
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listasVazias_$($inicio.ToString('yyMMdd_HHmmss')).txt"
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\membrosListasGrupos.csv"

# Conectando ao servico
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O módulo Exchange Online Management é necessário e não está instalado no sistema."
VerificaModulo -NomeModulo "Microsoft.Graph" -MensagemErro "O módulo Microsoft.Graph é necessário e não está instalado no sistema."
try {
  Connect-ExchangeOnline -ShowBanner:$false
} catch {
  Write-Host "Erro ao conectar ao Exchange Online: $($_.Exception.Message)" -ForegroundColor Red
  Exit
}
try {
  Connect-MgGraph -Scopes "Group.Read.All","User.Read.All" -ErrorAction Stop
} catch {
  Write-Host "Erro ao conectar ao Microsoft Graph: $($_.Exception.Message)" -ForegroundColor Red
  Exit
}

Write-Host "Inicio: $inicio"
Write-Host "Pesquisando Listas de Distribuicao e Grupos de Segurança..."
$Listas = Get-DistributionGroup -ResultSize Unlimited

Write-Host "Pesquisando Grupos de Segurança..."
$GruposSeguranca = Get-MgGroup -Filter "securityEnabled eq true" -All

$total = $Listas.Count + $GruposSeguranca.Count

Out-File -FilePath $arquivo -InputObject "idGrupo;nomeGrupo;eMailGrupo;adSync;tipoGrupo;idMembro;membro;tipo;eMailMembro" -Encoding UTF8

Foreach ($Lista in $Listas){

  $indice++
  Write-Progress -Activity "Exportando Listas/Grupos" -Status "Progresso: $indice/$total - $($Lista.DisplayName)" -PercentComplete (($indice / $total) * 100)

  $Membros = Get-DistributionGroupMember -Identity $Lista.ExternalDirectoryObjectId
  if ($Membros.Length -eq 0){

    if($Lista.IsDirSynced -eq $true){
      gravaLOG -arquivo $logs -texto "$($Lista),$($Lista.PrimarySmtpAddress),$($Lista.ExternalDirectoryObjectId),Sincronizada AD"
      continue
    }

    # Removendo listas vazias
    try {
      Remove-DistributionGroup -Identity $Lista.ExternalDirectoryObjectId -Confirm:$false
      gravaLOG -arquivo $logs -texto "$($Lista),$($Lista.PrimarySmtpAddress),$($Lista.ExternalDirectoryObjectId),Excluida"
    } catch {
      gravaLOG -arquivo $logs -texto "$($Lista),$($Lista.PrimarySmtpAddress),$($Lista.ExternalDirectoryObjectId),ERRO: $($_.Exception.Message)" -erro:$true
    }
    continue
  }
  
  Foreach ($Membro in $Membros){
    Out-File -FilePath $arquivo -InputObject "$($Lista.ExternalDirectoryObjectId);$($Lista.DisplayName);$($Lista.PrimarySMTPAddress);$($Lista.IsDirSynced);$($Lista.RecipientType);$($Membro.ExternalDirectoryObjectId);$($Membro.DisplayName);$($Membro.RecipientType);$($Membro.PrimarySMTPAddress)" -Encoding UTF8 -append
  }

}

Foreach ($Grupo in $GruposSeguranca){

  $indice++
  Write-Progress -Activity "Exportando Listas/Grupos" -Status "Progresso: $indice/$total - $($Grupo.DisplayName)" -PercentComplete (($indice / $total) * 100)

  $Membros = Get-MgGroupMember -GroupId $Grupo.Id -All
  if ($Membros.Count -eq 0){
    gravaLOG -arquivo $logs -texto "$($Grupo.DisplayName),$($Grupo.Mail),$($Grupo.Id),Grupo de Segurança vazio"
    continue
  }
  
  Foreach ($Membro in $Membros){
    # Obter detalhes do membro (assumindo usuário)
    try {
      $DetalhesMembro = Get-MgUser -UserId $Membro.Id -ErrorAction Stop
      $tipoMembro = "User"
      $emailMembro = $DetalhesMembro.Mail
    } catch {
      # Se não for usuário, pode ser grupo ou outro objeto
      $tipoMembro = "Other"
      $emailMembro = ""
    }
    Out-File -FilePath $arquivo -InputObject "$($Grupo.Id);$($Grupo.DisplayName);$($Grupo.Mail);$($Grupo.OnPremisesSyncEnabled);Security;$($Membro.Id);$($Membro.DisplayName);$tipoMembro;$emailMembro" -Encoding UTF8 -Append
  }
}
Write-Progress -Activity "Exportando Listas/Grupos" -PercentComplete 100

# Desconectar
Disconnect-ExchangeOnline -Confirm:$false
Disconnect-MgGraph -Confirm:$false

$final = Get-Date
Write-Host "`nInicio: $inicio"
Write-Host "Final: $final"
Write-Host "Tempo: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())"