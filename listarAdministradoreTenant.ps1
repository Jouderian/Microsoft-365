#-------------------------------------------------------------------------------
# Descricao: Listar os usuarios com direitos administrativos no M365
# Requisitos: Nenhum
# Versao 1 (30/11/22) - Jouderian Nobre: Criacao da rotina
# Versao 2 (20/04/23) - Jouderian Nobre: Ajustes
# Versao 3 (29/12/24) - Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
# Versao 4 (14/05/26) - Jouderian Nobre: Otimizando o script e uso de funcoes
#--------------------------------------------------------------------------------------------------------

Clear-Host

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

#--------------------------------------------------------- Conectando ao servico
VerificaModulo -NomeModulo "AzureAD" -MensagemErro "O módulo AzureAD é necessário e não está instalado no sistema."
try {
  Connect-AzureAD
} catch {
  Write-Host "Erro ao conectar no AzureAD: $($_.Exception.Message)" -ForegroundColor Red
  Exit
}

#---------------------------------------------------------- Declarando variaveis
$inicio = Get-Date
$resultados = @()
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaDeMembrosAdministrativos.csv"

Write-Host Inicio: $inicio
Write-Host Pesquisando Grupos Administrativos...
$gruposAdministrativos = Get-AzureADDirectoryRole

Foreach ($grupo in $gruposAdministrativos){

  $membros = Get-AzureADDirectoryRoleMember -ObjectId $grupo.ObjectId

  Foreach ($usuario in $membros){
    $resultados += [PSCustomObject]@{
      grupoId = $grupo.ObjectId
      grupoAdministrativo= $grupo.DisplayName
      usuarioID = $usuario.ObjectId
#      tipo = $usuario.UserType
      usuario = $usuario.DisplayName
      UPN = $usuario.UserPrincipalName
      ativa = $usuario.AccountEnabled
    }
  }
}
$resultados | Export-Csv -Path $arquivo -NoTypeInformation -Encoding UTF8

Write-Host "`nTotal de grupos administrativos: $($gruposAdministrativos.Count)"
Write-Host "Total de membros administrativos: $($resultados.Count)"

Disconnect-AzureAD

$final = Get-Date
Write-Host `nFinal: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()