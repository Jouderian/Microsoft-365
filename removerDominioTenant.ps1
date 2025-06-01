#--------------------------------------------------------------------------------------------------------
# Autor: Jouderian Nobre
# Descricao: Remover um dominio de tenant
# Versao: 1 (30/05/25) Jouderian: Criacao do script
#--------------------------------------------------------------------------------------------------------
# NOTA: Este script deve ser executado com permissões de administrador e requer o módulo ExchangeOnlineManagement instalado.
# Ainda em desencolvimento, portanto, pode conter erros ou não funcionar como esperado.
#--------------------------------------------------------------------------------------------------------

Param(
  [Parameter(Mandatory = $false)]
  [string]$dominio = "drsGroup.com.br"  # Dominio a ser removido
)

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\removerDominioTenant_$((Get-Date).ToString('MMMyy')).txt" 

gravaLOG -arquivo $logs -texto "$($inicio.ToString('dd/MM/yy HH:mm:ss')) - Iniciando a remocao do dominio $($dominio) do tenant..."

# Conectando ao Exchange Online
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema."
try {
  Import-Module ExchangeOnlineManagement
#  Connect-ExchangeOnline -ShowBanner:$false
} catch {
  gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Erro ao conectar ao Exchange Online: $($_.Exception.Message)" -erro:$true
  Exit
}

# Verifica se o dominio existe
$dominioExistente = Get-AcceptedDomain | Where-Object { $_.DomainName -eq $dominio }
if ($dominioExistente){
  gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - O dominio $($dominio) nao existe no tenant." -erro:$true
  Exit
}

# Verifica se o dominio esta sendo usado por algum usuario
$usuariosUsandoDominio = Get-EXOMailbox -ResultSize Unlimited | Where-Object { $_.UserPrincipalName -like "*@$dominio" }
if ($usuariosUsandoDominio){
  $usuariosUsandoDominio | ForEach-Object {
    try {
      $novoUPN = $_.UserPrincipalName -replace "@$dominio$", "@$(Get-AcceptedDomain | Where-Object { $_.Default -eq $true }).DomainName"
      Set-User -Identity $_.UserPrincipalName -UserPrincipalName $novoUPN
      gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - UPN do usuario $($_.DisplayName) alterado para $novoUPN."
    } catch {
      gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Erro ao alterar UPN do usuario $($_.DisplayName): $($_.Exception.Message)" -erro:$true
    }
  }
  Exit
}

# Verifica se o dominio esta sendo usado por algum grupo
$gruposUsandoDominio = Get-EXORecipient -RecipientTypeDetails GroupMailbox -ResultSize Unlimited | Where-Object { $_.PrimarySmtpAddress -like "*@$dominio" }
if ($gruposUsandoDominio){
  $gruposUsandoDominio | ForEach-Object {
    try {
      $novoEmail = $_.PrimarySmtpAddress -replace "@$dominio$", "@$(Get-AcceptedDomain | Where-Object { $_.Default -eq $true }).DomainName"
      Set-DistributionGroup -Identity $_.Identity -PrimarySmtpAddress $novoEmail
      gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Email do grupo $($_.DisplayName) alterado para $novoEmail."
    } catch {
      gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Erro ao alterar email do grupo $($_.DisplayName): $($_.Exception.Message)" -erro:$true
    }
  }
  Exit
}

# Verifica se o dominio esta sendo usado por algum contato
$contatosUsandoDominio = Get-EXORecipient -RecipientTypeDetails MailContact -ResultSize Unlimited | Where-Object { $_.PrimarySmtpAddress -like "*@$dominio" }
if ($contatosUsandoDominio){
  $contatosUsandoDominio | ForEach-Object {
    try {
      $novoEmail = $_.PrimarySmtpAddress -replace "@$dominio$", "@$(Get-AcceptedDomain | Where-Object { $_.Default -eq $true }).DomainName"
      Set-MailContact -Identity $_.Identity -PrimarySmtpAddress $novoEmail
      gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Email do contato $($_.DisplayName) alterado para $novoEmail."
    } catch {
      gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Erro ao alterar email do contato $($_.DisplayName): $($_.Exception.Message)" -erro:$true
    }
  }
  Exit
}

# Verifica se o dominio esta sendo usado por algum recurso
$recursosUsandoDominio = Get-EXORecipient -RecipientTypeDetails RoomMailbox, EquipmentMailbox -ResultSize Unlimited | Where-Object { $_.PrimarySmtpAddress -like "*@$dominio" }
if ($recursosUsandoDominio){
  $recursosUsandoDominio | ForEach-Object {
    try {
      $novoEmail = $_.PrimarySmtpAddress -replace "@$dominio$", "@$(Get-AcceptedDomain | Where-Object { $_.Default -eq $true }).DomainName"
      Set-Mailbox -Identity $_.Identity -PrimarySmtpAddress $novoEmail
      gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Email do recurso $($_.DisplayName) alterado para $novoEmail."
    } catch {
      gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Erro ao alterar email do recurso $($_.DisplayName): $($_.Exception.Message)" -erro:$true
    }
  }
  Exit
}

# Removendo o dominio
try {
  Remove-EXODomain -Identity $dominio -Confirm:$false
  gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - O dominio $($dominio) foi removido com sucesso do tenant."
} catch {
  gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Erro ao remover o dominio $($dominio): $($_.Exception.Message)" -erro:$true
}