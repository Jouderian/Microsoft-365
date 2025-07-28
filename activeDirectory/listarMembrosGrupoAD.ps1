#--------------------------------------------------------------------------------------------------------
# Descricao: Listar os membros de um grupo do Active Directory
# Versao 1 (28/07/25) Jouderian Nobre
#--------------------------------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis

# Solicita o nome do grupo ao usuário
$grupo = Read-Host "Informe o nome do grupo do AD"

try {
  $membros = Get-ADGroupMember -Identity $grupo -Recursive | Where-Object { $_.objectClass -eq 'user' }
  if ($membros.Count -eq 0){
    Write-Host "Nenhum usuário encontrado no grupo $grupo." -ForegroundColor Yellow
    return
  }
} catch {
  Write-Host "Erro ao buscar membros do grupo: $($_.Exception.Message)" -ForegroundColor Red
  return
}

# Busca informações detalhadas dos usuários
$resultado = foreach ($membro in $membros){
  $user = Get-ADUser `
    -Identity $membro.SamAccountName `
    -Properties DisplayName, UserPrincipalName, Title, Department
  [PSCustomObject]@{
    Nome         = $user.DisplayName
    UPN          = $user.UserPrincipalName
    Cargo        = $user.Title
    Departamento = $user.Department
  }
}

# Exibe resultado formatado
$resultado | Format-Table -AutoSize

# Opcional: exportar para CSV
$exporta = Read-Host "Quer exportar os resultados para CSV? (S/n)"
if ($exporta -eq 'S'){
  $caminho = Read-Host "Informe o caminho para salvar o arquivo CSV (ex: C:\temp\membros_$grupo.csv)"
  $resultado | Export-Csv -Path $caminho -NoTypeInformation -Encoding UTF8
  Write-Host "Resultados exportados para $caminho" -ForegroundColor Green
}