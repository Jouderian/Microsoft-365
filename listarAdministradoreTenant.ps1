#-------------------------------------------------------------------------------
# Descricao: Listar os usuarios com direitos administrativos no M365
# Requisitos: Nenhum
# Versao: 1 - 30/11/22 (Jouderian Nobre): Criacao da rotina
# Versao: 2 - 20/04/23 (Jouderian Nobre): Ajustes

#Valida existencia do modulo esta instalado
$Modules = Get-Module -Name AzureAD -ListAvailable
if($Modules.count -eq 0){
  Write-Host Instale o modulo do AzureAD usando o comando abaixo:`n  Install-Module AzureAD -ForegroundColor yellow
  Exit
}
Connect-AzureAD -AccountId jouderian.nobre.infra@grupoElfa.onMicrosoft.com

$arquivo = "C:\Users\jouderian.nobre\OneDrive\Documentos\WindowsPowerShell\listaDeMembrosAdministrativos.csv"
$inicio = Get-Date

Write-Host Inicio: $inicio
Write-Host Pesquisando Grupos Administrativos...
$gruposAdministrativos = Get-AzureADDirectoryRole

Out-File -FilePath $arquivo -InputObject "grupoId,grupoAdministrativo,usuarioID,tipo,usuario,UPN,ativa" -Encoding UTF8

Foreach ($grupo in $gruposAdministrativos){

  Write-Host $grupo.DisplayName

  $membros = Get-AzureADDirectoryRoleMember -ObjectId $grupo.ObjectId

  Foreach ($usuario in $membros){
    $infoMembro = "$($grupo.ObjectId),"
    $infoMembro += "$($grupo.DisplayName),"
    $infoMembro += "$($usuario.ObjectId),"
    $infoMembro += "$($usuario.UserType),"
    $infoMembro += "$($usuario.DisplayName),"
    $infoMembro += "$($usuario.UserPrincipalName),"
    $infoMembro += "$($usuario.AccountEnabled)"

    Out-File -FilePath $arquivo -InputObject $infoMembro -Encoding UTF8 -append
  }
}

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()