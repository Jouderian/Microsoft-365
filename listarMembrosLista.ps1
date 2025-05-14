#-------------------------------------------------------------------------------
# Descricao: Lista a relacao de membros das Listas e Grupos do M365
# Versao 1 (25/01/22) Jouderian Nobre
# :::
# Versao 4 (09/11/24) Jouderian Nobre: Inclusao do ID do grupo/lista e dos membros
# Versao 5 (09/12/24) Jouderian Nobre: Relaciona as listas sem membros (vazias)
# Versao 6 (11/12/24) Jouderian Nobre: Passa a exclui as listas vazias
# Versao 7 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
# Versao 8 (29/04/25) Jouderian Nobre: Otimizacao do script com uso de funcoes
#--------------------------------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

#--------------------------------------------------------- Conectando ao servico
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O módulo Exchange Online Management é necessário e não está instalado no sistema."
try {
  Connect-ExchangeOnline
} catch {
  Write-Host "Erro ao conectar ao Exchange Online: $($_.Exception.Message)" -ForegroundColor Red
  Exit
}

#---------------------------------------------------------- Declarando variaveis
$indice = 0
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listasVazias_$($inicio.ToString('yyMMdd_HHmmss')).txt"
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\membrosListasGrupos.csv"

Write-Host Inicio: $inicio
Write-Host Pesquisando Listas de Distribuicao...
$Listas = Get-DistributionGroup -ResultSize Unlimited
$totalListas = $Listas.Count

Out-File -FilePath $arquivo -InputObject "idGrupo;nomeGrupo;eMailGrupo;adSync;tipoGrupo;idMembro;membro;tipo;eMailMembro" -Encoding UTF8

Foreach ($Lista in $Listas){
  $indice++

  if ($indice % 10 -eq 0){ # Atualiza o progresso a cada 10 listas processadas
    Write-Progress -Activity "Exportando Listas/Grupos" -Status "Progresso: $indice/$totalListas - $($Lista.DisplayName)" -PercentComplete (($indice / $totalListas) * 100)
  }

  $Membros = Get-DistributionGroupMember -Identity $Lista.ExternalDirectoryObjectId
  if ($Membros.Length -eq 0){
    if($Lista.IsDirSynced -eq $false){
      try {
        Remove-DistributionGroup -Identity $Lista.ExternalDirectoryObjectId -Confirm:$false
        gravaLOG -arquivo $logs -texto "$($Lista),$($Lista.PrimarySmtpAddress),$($Lista.ExternalDirectoryObjectId),Excluida"
      } catch {
        gravaLOG -arquivo $logs -texto "$($Lista),$($Lista.PrimarySmtpAddress),$($Lista.ExternalDirectoryObjectId), ERRO: $($_.Exception.Message)" -erro:$true
      }
    } else {
      gravaLOG -arquivo $logs -texto "$($Lista),$($Lista.PrimarySmtpAddress),$($Lista.ExternalDirectoryObjectId),Sincronizada AD"
    }
  } else {
    Foreach ($Membro in $Membros){
      Out-File -FilePath $arquivo -InputObject "$($Lista.ExternalDirectoryObjectId);$($Lista.DisplayName);$($Lista.PrimarySMTPAddress);$($Lista.IsDirSynced);$($Lista.RecipientType);$($Membro.ExternalDirectoryObjectId);$($Membro.DisplayName);$($Membro.RecipientType);$($Membro.PrimarySMTPAddress)" -Encoding UTF8 -append
    }
  }
}
Write-Progress -Activity "Exportando Listas/Grupos" -PercentComplete 100

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()