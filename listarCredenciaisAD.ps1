#--------------------------------------------------------------------------------------------------------
# Descricao: Script para gerar um arquivo .csv com as principais informcoes dos usuarios do AD.
# Versao 1 (06/12/22) Savio
# Versao 2 (04/05/23) Jouderian Nobre: Melhoria no tratamento do ultimo acesso
# Versao 3 (08/05/23) Jouderian Nobre: Inclusão de mais informações da credencial
# Versao 4 (07/11/24) Jouderian Nobre: Inclusáo da biblioteca, tratamento dos campos e melhoria no acompanhamento da progressao da extracao
# Versao 5 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
#--------------------------------------------------------------------------------------------------------

. "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\Scripts\Publico\Microsoft-365\bibliotecaDeFuncoes.ps1"

Clear-Host

$indice = 0
$inicio = Get-Date
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaUsuariosAD.csv"

Write-Host "`n`n`n`n`n`n`nInicio:" $inicio
Write-Host Pesquisando relacao de credenciais no AD...
$credenciais = Get-ADUser -Filter * `
  -Properties `
    SamAccountName, `
    DisplayName, `
    EmailAddress, `
    Enabled, `
    Company, `
    Office, `
    Department, `
    Title, `
    Manager, `
    Created, `
    LastLogonDate, `
    LastLogonTimestamp, `
    AccountExpirationDate, `
    PasswordLastSet, `
    CanonicalName, `
    ObjectGUID

Out-File -FilePath $arquivo -InputObject "Credencial;Nome;eMail;Ativa;Empresa;Escritorio;Departamento;Cargo;Gerente;Criacao;ultimoAcesso;Expiracao;mudancaSenha;CanonicalName;ObjectGUID;Grupos" -Encoding UTF8
$totalCredenciais = $credenciais.Count

Foreach ($credencial in $credenciais){

  $indice++
  Write-Progress -Activity "Coletando dados das credenciais" -Status "Progresso: $indice de $totalCredenciais coletadas" -PercentComplete (($indice / $totalCredenciais) * 100)

#  $grupos = Get-ADPrincipalGroupMembership -Identity $credencial.SamAccountName

  $departamento = if($null -ne $credencial.Department){ removeQuebraDeLinha -texto $credencial.Department }
  $cargo = if($null -ne $credencial.Title){ removeQuebraDeLinha -texto $credencial.Title }

  $infoCredencial = "$($credencial.SamAccountName);"
  $infoCredencial += "$($credencial.DisplayName);"
  $infoCredencial += "$($credencial.EmailAddress);"
  $infoCredencial += "$($credencial.Enabled);"
  $infoCredencial += "$($credencial.Company);"
  $infoCredencial += "$($credencial.Office);"
  $infoCredencial += "$($departamento);"
  $infoCredencial += "$($cargo);"
  $infoCredencial += [System.String]::Concat("""","$($credencial.Manager)",""";")

  $momento = $credencial.Created
  $infoCredencial += "$($momento.ToString('dd/MM/yy HH:mm'));"

  $momento = $credencial.LastLogonDate
  $momento2 = [DateTime]::FromFileTimeUtc($credencial.LastLogonTimestamp)
  If($momento -gt $momento2){
    $infoCredencial += "$($momento.ToString('dd/MM/yy HH:mm'));"
  } else {
    $infoCredencial += "$($momento2.ToString('dd/MM/yy HH:mm'));"
  }

  $momento = $credencial.AccountExpirationDate
  if($null -eq $momento){
    $infoCredencial += ";"
  } Else {
    $infoCredencial += "$($momento.ToString('dd/MM/yy HH:mm'));"
  }

  $momento = $credencial.PasswordLastSet
  if($null -eq $momento){
    $infoCredencial += ";"
  } Else {
    $infoCredencial += "$($momento.ToString('dd/MM/yy HH:mm'));"
  }

  $infoCredencial += "$($credencial.CanonicalName);"
  $infoCredencial += "$($credencial.ObjectGUID);"

#  $texto = '"'
#  Foreach ($grupo in $grupos){
#    $texto += $grupo.name + "+"
#  }
#  $texto += '"'
#  $infoCredencial += "$($texto)"

  Out-File -FilePath $arquivo -InputObject $infoCredencial -Encoding UTF8 -append
}

Write-Progress -Activity "Coletando dados das credenciais" -PercentComplete 100

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()