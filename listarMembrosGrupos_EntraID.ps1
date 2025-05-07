#--------------------------------------------------------------------------------------------------------
# Descricao: Mostra os membros de um grupo do EntraID
# Versao 1 (06/03/25) Jouderian Nobre
# Versao 2 (07/05/25) Jouderian Nobre: Melhoria na exibicao dos dados
#--------------------------------------------------------------------------------------------------------

Clear-Host

#--------------------------------------------------------------------- VARIAVEIS
$inicio = Get-Date
$groupName = "semMFA.M365"

Connect-AzureAD

Write-Host "Inicio:" $inicio
Write-Host "Pesquisando relacao de credenciais no grupo:" $groupName
$group = Get-AzureADGroup -SearchString $groupName

if ($group){
    # Obtenha os membros do grupo
    $members = Get-AzureADGroupMember -ObjectId $group.ObjectId

    foreach ($member in $members){
        $user = Get-AzureADUser -ObjectId $member.ObjectId
        $situacao = if ($user.AccountEnabled) { "Ativa" } else { "Bloqueada" }
        Write-Output "$($user.DisplayName),$($user.UserPrincipalName),$($user.UserType),$($situacao)"
    }

    Write-Output "`n`nTotal de membros: $($members.Count)"
} else {
    Write-Output "Grupo não encontrado: $groupName"
}

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()