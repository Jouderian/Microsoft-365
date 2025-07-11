#--------------------------------------------------------------------------------------------------------
# Descricao: Ajustar o País, Apelido e Código do País de todas as credenciais ativas no AD
# Versao 1 (09/07/25) Jouderian Nobre
#--------------------------------------------------------------------------------------------------------

Clear-Host

# Declarando variaveis
$alterados = 0
$nomePais = "Brasil"
$codigoPais = "BR"
$codigoNumerico = 76

# Busca todos as credenciais ativas
$usuariosAtivos = Get-ADUser -Filter {Enabled -eq $true} -Properties co, c, countryCode

foreach ($usuario in $usuariosAtivos){
  if (
    $usuario.co -eq $nomePais -and
    $usuario.c -eq $codigoPais -and
    $usuario.countryCode -eq $codigoNumerico
  ){
    continue
  }

  $alterados ++
  Set-ADUser -Identity $usuario.DistinguishedName -Replace @{
    co = $nomePais
    c = $codigoPais
    countryCode = $codigoNumerico
  }
  Write-Host "$($usuario.SamAccountName): País: $($usuario.co) => $nomePais, Apelido: $($usuario.c) => $codigoPais, cod.País: $($usuario.countryCode) => $codigoNumerico"
}
Write-Host "Total de Alterações: $alterados"