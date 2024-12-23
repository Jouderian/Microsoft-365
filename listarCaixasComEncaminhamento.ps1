#--------------------------------------------------------------------------------------------------------
# Descricao: Extrair uma listagem com todas as caixas postais do Microsoft 365 com encaminhamento ativo
# Versao 01 (16/07/24) - Jouderian Nobre
#--------------------------------------------------------------------------------------------------------

Clear-Host

$Modules = Get-Module -Name ExchangeOnlineManagement -ListAvailable
if($Modules.count -eq 0){
  Write-Host Instale o modulo do ExchangeOnlineManagement usando o comando abaixo:`n  Install-Module ExchangeOnlineManagement -ForegroundColor yellow
  Exit
}
Connect-ExchangeOnline

$inicio = Get-Date

Write-Host Inicio: $inicio
Write-Host Pesquisando Relacao de Caixas Postais no ExchangeOnline...

$caixas = Get-Mailbox -ResultSize Unlimited -Filter 'DeliverToMailboxAndForward -eq $true' -ExpandProperty ForwardingSmtpAddress

$totalCaixas = $caixas.Count
$indice = 0

Write-Host "Tipo,Nome,UPN,Destino"
"Nome,UPN,Cidade,UF,Empresa,Escritorio,Departamento,Cargo,Gerente,CC,nomeCC,Tipo,AD,Desabilitado,SenhaForte,SenhaNaoExpira,Compartilhado,Encaminhada,Litigio,Itens,usado(GB),Arquivamento,Criacao,MudancaSenha,ultimoSyncAD,ultimoAcesso,nomeConta,objectId,Licencas,outrasLicencas"

foreach ($caixa in $caixas){

  $indice++
  Write-Progress -Activity "Analisando caixas postais" -Status "Progresso: $($indice) de $($totalCaixas)" -PercentComplete ($indice / $totalCaixas * 100)

  Write-Host "$($caixa.RecipientTypeDetails),$($caixa.Name),$($caixa.UserPrincipalName),$($caixa.ForwardingSmtpAddress)"
}

Write-Progress -Activity "Analisando caixas postais" -PercentComplete 100

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()