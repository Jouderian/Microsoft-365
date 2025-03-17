#-------------------------------------------------------------------------------
# Autor: Jouderian Nobre
# Descricao: Forca um sincronismo entre o AD e o M365
# Versao 1 (15/03/23) Jouderian: 
# Versao 2 (17/03/25) Jouderian: Ajuste para identicar o AD pelo computador em execusao
#-------------------------------------------------------------------------------

Import-Module ActiveDirectory

$dominio = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$controladorDominio = $dominio.DomainControllers.Name[0]

$sessao = New-PSSession -ComputerName $controladorDominio

Invoke-Command -Session $sessao -ScriptBlock {
  Start-ADSyncSyncCycle -PolicyType Delta
}

Remove-PSSession $sessao