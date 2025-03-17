#--------------------------------------------------------------------------------------------------------
# Descricao: Mostra os membros de um grupo do EntraID
# Versao 1 (06/03/25) Jouderian
#--------------------------------------------------------------------------------------------------------

Clear-Host

$inicio = Get-Date
$groupName = "semMFA.M365"

#Connect-AzureAD

Write-Host "Inicio:" $inicio
Write-Host "Pesquisando relacao de credenciais no grupo:" $groupName
$group = Get-AzureADGroup -SearchString $groupName

if ($group){
    # Obtenha os membros do grupo
    $members = Get-AzureADGroupMember -ObjectId $group.ObjectId

    # Exiba os membros
    $members | Select-Object DisplayName, UserPrincipalName
    Write-Output "`n`nTotal de membros: $($members.Count)"
} else {
    Write-Output "Grupo não encontrado: $groupName"
}

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()