<#
.SYNOPSIS
  Forca um sincronismo entre o AD e o M365
.DESCRIPTION
  O script se conecta ao AD, força um sincronismo com o M365.
.AUTHOR
  Jouderian Nobre
.VERSION
  01 (15/03/23) - Criacao do script
  02 (17/03/25) - Ajuste para identicar o AD pelo computador em execusao
  03 (05/04/26) - Atualizacao da documentacao
#>

Import-Module ActiveDirectory

$dominio = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$controladorDominio = $dominio.DomainControllers.Name[0]

$sessao = New-PSSession -ComputerName $controladorDominio

Invoke-Command -Session $sessao -ScriptBlock {
  Start-ADSyncSyncCycle -PolicyType Delta
}

Remove-PSSession $sessao