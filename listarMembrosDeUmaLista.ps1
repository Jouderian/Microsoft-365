#--------------------------------------------------------------------------------------------------------
# Descricao: Mostra os membros de um grupo/Lista do EntraID (via Microsoft Graph PowerShell)
# Versao 1 (06/03/25) Jouderian Nobre
# Versao 2 (07/05/25) Jouderian Nobre: Melhoria na exibicao dos dados
# Versao 3 (01/09/25) Jouderian Nobre: Ajuste nos campos exibidos
# Versao 4 (08/12/25) Felipe Aquino: Migracao de AzureAD -> Microsoft.Graph
#--------------------------------------------------------------------------------------------------------
Clear-Host

# Declarando variaveis
$inicio = Get-Date
$groupName = "semMFA.M365"

Write-Host "Inicio: $inicio"
Write-Host "Grupo: $groupName"
Write-Host "Conectando ao Microsoft Graph..." -ForegroundColor Cyan

# Conexao (interativa)
try {
  # Scopes necessários para ler grupos e usuários
  Connect-MgGraph -Scopes "Group.Read.All","User.Read.All" -NoWelcome
} catch {
  Write-Error "Falha ao conectar no Microsoft Graph: $($_.Exception.Message)"
  exit 1
}

Write-Host "Pesquisando relacao de credenciais no grupo: $groupName" -ForegroundColor Yellow

try {
  $group = Get-MgGroup -Filter "displayName eq '$groupName'"
} catch {
  Write-Error "Erro ao buscar grupo no Graph: $($_.Exception.Message)"
  exit 1
}

if (-not $group){
  Write-Host "Grupo não encontrado: $groupName"
  exit 1
} elseif ($group.Count -gt 1){
  Write-Warning "Foram encontrados vários grupos com o nome $groupName. Usando o primeiro da lista."
  exit 1
}

Write-Host "Grupo encontrado: $($group.DisplayName) - Id: $($group.Id)" -ForegroundColor Green

try {
  $members = Get-MgGroupMember -GroupId $group.Id -All
} catch {
  Write-Error "Erro ao obter membros do grupo: $($_.Exception.Message)"
  exit 1
}

Write-Host "displayName,userPrincipalName,Status" -ForegroundColor White

foreach ($member in $members){
  try {
    $user = Get-MgUser -UserId $member.Id -Property "displayName,userPrincipalName,accountEnabled"
  } catch {
    Write-Warning "Falha ao obter dados do usuário Id $($member.Id): $($_.Exception.Message)"
    continue
  }

  $situacao = if ($user.AccountEnabled) { "Ativa" } else { "Bloqueada" }

  Write-Host "$($user.DisplayName),$($user.UserPrincipalName),$situacao"
}

Write-Host "`n`nTotal de membros (usuarios): $($members.Count)"

$final = Get-Date
Write-Host "`nInicio: $inicio Final: $final > Tempo:" (NEW-TIMESPAN -Start $inicio -End $final).ToString()