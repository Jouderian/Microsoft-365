#--------------------------------------------------------------------------------------------------------
# Autor: Jouderian Nobre
# Descricao: Remove um dominio especifico das credenciais no AD
# Versao: 1 (30/05/25) Jouderian
#--------------------------------------------------------------------------------------------------------

Param(
  [Parameter(Mandatory = $false)]
  [string]$dominio = "seuZe.com.br",  # Dominio a ser removido
  [string]$novoUPN = "donaMaria.onMicrosoft.com",  # Novo dominio UPN
  [switch]$WhatIf  # Permite simular a execucao sem fazer alteracoes
)

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"
. "C:\ScriptsRotinas\bibliotecas\M365_Functions_elfa.ps1"

Clear-Host

# Declarando variaveis

$inicio = Get-Date
$mensagem = "Remocao dominio $($dominio) em $($inicio.ToString('dd/MM/yy HH:mm'))"
$logs = "C:\ScriptsRotinas\remocaoDominio\removerDominioEmails_$((Get-Date).ToString('MMMyy')).txt"
$contadores = @{
  Total = 0
  Alterados = 0
  Erros = 0
}

gravaLOG -arquivo $logs -texto "$($inicio.ToString('dd/MM/yy HH:mm:ss')) - Iniciando a remocao do dominio $($dominio) dos eMails..."

$usuarios = Get-ADUser -Filter "EmailAddress -like '*@$dominio'" -Properties SamAccountName, Name, DisplayName, DistinguishedName, UserPrincipalName, EmailAddress, proxyAddresses, POBox
$contadores.Total = $usuarios.Count
gravaLOG -arquivo $logs -texto "Encontrados $($contadores.Total) usuarios com eMail do dominio $dominio"

foreach ($usuario in $usuarios){
  $caixaPostal = ""
  $nome = "[Inativo] $($usuarioAD.Name)"

  try {
    $emailAtual = $usuario.UserPrincipalName
    $proxiesAtuais = $usuario.proxyAddresses
    $novoEmail = $emailAtual.Split('@')[0] + "@" + $novoUPN

    # Remove eMails com o dominio
    $novosProxies = $proxiesAtuais | Where-Object { $_ -notlike "*@$dominio" }
    if(-not $novosProxies){
	  $novosProxies = " "
    }

    if($usuarioAD.POBox -eq 'O365' -or $usuarioAD.POBox -eq 'NOGAL'){
	  $caixaPostal = "NOGAL"
    }

    if ($WhatIf){
	  Write-Host "Usuario $($usuario.DisplayName), UPN Atual: $($emailAtual), Novo UPN: $($novoEmail), Proxies atuais: $($proxiesAtuais -join ', '), Novos proxies: $($novosProxies -join ', ')"
	 continue
    }

    # Atualiza credencial
    Set-ADUser -Identity $usuario.DistinguishedName `
	  -displayname $nome `
	  -UserPrincipalName $novoEmail `
	  -EmailAddress $novoEmail `
	  -POBox $caixaPostal `
	  -Replace @{proxyAddresses = $novosProxies} `
    -Replace @{info=$mensagem} `
	  -Enabled $false `
	  -Country "BR"

    try {
      #Remover TODOS os grupos do AD, exceto o grupo padrao "Domain Users"
      Get-ADPrincipalGroupMembership -Identity $usuario.SamAccountName | Where-Object {($_.name -notmatch 'Domain Users')} | ForEach-Object {Remove-ADPrincipalGroupMembership -Identity $Usuario -MemberOf $_ -Confirm:$False}
    } catch {
      gravaLOG -arquivo $logs -texto "Removendo os grupos do $($usuario.SamAccountName) no AD: $($_.Exception.Message)" -erro:$true
      $contadores.Erros++
      continue
    }

    try {
      #Mudando a senha da credencial para uma senha aleatoria
      $novaSenha = geraSenhaAleatoria
      Set-ADAccountPassword -Identity $usuario.SamAccountName -NewPassword (ConvertTo-SecureString -AsPlainText $novaSenha -Force)
    } catch {
      gravaLOG -arquivo $logs -texto "Mudando a senha do $($usuario.SamAccountName) no AD: $($_.Exception.Message)" -erro:$true
      $contadores.Erros++
    }

    try {
      #Envia notificacao de cancelamento de 120 dias das reunioes.
      Remove-CalendarEvents -Identity $($usuario.EmailAddress) -Confirm:$false -CancelOrganizedMeetings -QueryWindowInDays 120
    } catch {
      gravaLOG -arquivo $logs -texto "Cancelando os eventos de $($Usuario.EmailAddress): $($_.Exception.Message)" -erro:$true
      $contadores.Erros++
    }

  } catch {
    gravaLOG -arquivo $logs -texto "Atualizando usuario $($usuario.Name): $($_.Exception.Message)" -erro:$true
    $contadores.Erros++
  }
}


$final = Get-Date
gravaLOG -arquivo $logs -texto "Processamento finalizado em $($final.ToString('dd/MM/yy HH:mm:ss'))"
gravaLOG -arquivo $logs -texto "Total: $($contadores.Total) | Alterados: $($contadores.Alterados) | Erros: $($contadores.Erros)"
gravaLOG -arquivo $logs -texto "Tempo de duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())"