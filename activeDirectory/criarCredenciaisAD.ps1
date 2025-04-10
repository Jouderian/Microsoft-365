#--------------------------------------------------------------------------------------------------------
# Descricao: Criar usuarios no AD com base em um aquivo CSV
# Versao 01 (12/05/21) Jouderian Nobre
# Versao 02 (27/01/25) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
#--------------------------------------------------------------------------------------------------------

Clear-Host

#---------------------------------------------------------- Declarando variaveis
$Location = "OU=Empresa,OU=Unidades,DC=DOMINIO,DC=srv"
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\criaUsuarios.csv"
$inicio = Get-Date

Write-Host "`n`n`n`n`n`n`nInicio:" $inicio
Write-Host Criando credenciais no AD...
$Users = Import-Csv -Delimiter:";" -Path $arquivo
#$Users | Format-Table

$Users | ForEach-Object {
  Write-Host $_.nomecompleto "=>" $_.contaAD
 
  $senha = ConvertTo-SecureString -AsPlainText $_.Senha -force
  $nomeExibicao = $_.Nome + " " + $_.sobreNome
  New-ADUser $nomeExibicao `
    -SamAccountName $_.contaAD `
    -UserPrincipalName $_.nomePrincipal `
    -DisplayName $_.nomecompleto `
    -GivenName $_.Nome `
    -Surname $_.sobreNome `
    -EmailAddress $_.eMail `
    -Company $_.Filial `
    -Title $_.Cargo `
    -Department $_.Departamento `
    -Office $_.Filial `
    -City $_.Cidade `
    -State $_.UF `
    -Country "BR" `
    -AccountPassword $senha `
    -Path:$Location `
    -Enabled:$true
}

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()