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

Clear-Host

# Declarando variaveis

$inicio = Get-Date
$logs = "C:\ScriptsRotinas\remocaoDominio\removerDominioEmails_$((Get-Date).ToString('MMMyy')).txt"
$contadores = @{
  Total = 0
  Alterados = 0
  Erros = 0
}

gravaLOG -arquivo $logs -texto "$($inicio.ToString('dd/MM/yy HH:mm:ss')) - Iniciando a remocao do dominio $($dominio) dos eMails..."

# Busca usuarios na OU especificada
try {
  $usuarios = Get-ADUser -Filter "EmailAddress -like '*@$dominio'" -Properties DisplayName, DistinguishedName, UserPrincipalName, EmailAddress, proxyAddresses
  $contadores.Total = $usuarios.Count
    
  gravaLOG -arquivo $logs -texto "Encontrados $($contadores.Total) usuarios com eMail do dominio $dominio"

  foreach ($usuario in $usuarios){
    try {
      $emailAtual = $usuario.UserPrincipalName
      $proxiesAtuais = $usuario.proxyAddresses
      $novoEmail = $emailAtual.Split('@')[0] + "@" + $novoUPN

      # Remove emails com o dominio especificado
      $novosProxies = $proxiesAtuais | Where-Object { $_ -notlike "*@$dominio" }
      if(-not $novosProxies){
        $novosProxies = " "
      }

      if ($WhatIf){
        Write-Host "Usuario $($usuario.DisplayName), UPN Atual: $($emailAtual), Novo UPN: $($novoEmail), Proxies atuais: $($proxiesAtuais -join ', '), Novos proxies: $($novosProxies -join ', ')"
        continue
      }

      # Atualiza UPN
      Set-ADUser -Identity $usuario.DistinguishedName -UserPrincipalName $novoEmail

      # Atualiza proxyAddresses
      Set-ADUser -Identity $usuario.DistinguishedName `
        -UserPrincipalName $novoEmail `
        -EmailAddress $novoEmail `
        -Country "BR" `
        -Replace @{proxyAddresses = $novosProxies}

      gravaLOG -arquivo $logs -texto "Usuario $($usuario.Name) atualizado com sucesso"
      $contadores.Alterados++

    } catch {
      gravaLOG -arquivo $logs -texto "Atualizando usuario $($usuario.Name): $($_.Exception.Message)" -erro:$true
      $contadores.Erros++
    }
  }

} catch {
  gravaLOG -arquivo $logs -texto "Erro ao buscar usuarios: $($_.Exception.Message)" -erro:$true
  Exit
}

$final = Get-Date
gravaLOG -arquivo $logs -texto "Processamento finalizado em $($final.ToString('dd/MM/yy HH:mm:ss'))"
gravaLOG -arquivo $logs -texto "Total: $($contadores.Total) | Alterados: $($contadores.Alterados) | Erros: $($contadores.Erros)"
gravaLOG -arquivo $logs -texto "Tempo de duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())"