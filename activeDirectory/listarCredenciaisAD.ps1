﻿#--------------------------------------------------------------------------------------------------------
# Descricao: Script para gerar um arquivo .csv com as principais informcoes dos usuarios do AD.
# Versao 1 (06/12/22) Savio
# Versao 2 (04/05/23) Jouderian Nobre: Melhoria no tratamento do ultimo acesso
# Versao 3 (08/05/23) Jouderian Nobre: Inclusão de mais informações da credencial
# Versao 4 (07/11/24) Jouderian Nobre: Inclusáo da biblioteca, tratamento dos campos e melhoria no acompanhamento da progressao da extracao
# Versao 5 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
# Versao 6 (17/03/25) Jouderian Nobre: Incluir o campo POBox para identificar sincronismo com o M365
# Versao 7 (09/05/25) Jouderian Nobre: Incluir o campo descricao
# Versao 8 (05/06/25) Jouderian Nobre: Otimizando o script
#--------------------------------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$indice = 0
$buffer = @()
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
    POBox, `
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
    Description, `
    CanonicalName, `
    ObjectGUID

Out-File -FilePath $arquivo -InputObject "Credencial;Nome;eMail;Ativa;M365;Empresa;Escritorio;Departamento;Cargo;Gerente;Criacao;ultimoAcesso;Expiracao;mudancaSenha;Descricao;CanonicalName;ObjectGUID;Grupos" -Encoding UTF8
$totalCredenciais = $credenciais.Count

Foreach ($credencial in $credenciais){

  $indice++

#  $grupos = Get-ADPrincipalGroupMembership -Identity $credencial.SamAccountName

  $departamento = if($null -ne $credencial.Department){ removeQuebraDeLinha -texto $credencial.Department }
  $cargo = if($null -ne $credencial.Title){ removeQuebraDeLinha -texto $credencial.Title }

  $infoCredencial = "$($credencial.SamAccountName);" # Credencial
  $infoCredencial += "$($credencial.DisplayName);" # Nome
  $infoCredencial += "$($credencial.EmailAddress);" # eMail
  $infoCredencial += "$($credencial.Enabled);" # Ativa
  $infoCredencial += "$($credencial.POBox);" # M365
  $infoCredencial += "$($credencial.Company);" # Empresa
  $infoCredencial += "$($credencial.Office);" # Escritorio
  $infoCredencial += "$($departamento);" # Departamento
  $infoCredencial += "$($cargo);" # Cargo
  $infoCredencial += [System.String]::Concat("""","$($credencial.Manager)",""";") # Gerente

  $momento = $credencial.Created
  $infoCredencial += "$($momento.ToString('dd/MM/yy HH:mm'));" # Criacao

  $momento = $credencial.LastLogonDate
  $momento2 = [DateTime]::FromFileTimeUtc($credencial.LastLogonTimestamp)
  If($momento -gt $momento2){ # ultimoAcesso
    $infoCredencial += "$($momento.ToString('dd/MM/yy HH:mm'));"
  } else {
    $infoCredencial += "$($momento2.ToString('dd/MM/yy HH:mm'));"
  }

  $momento = $credencial.AccountExpirationDate
  if($null -eq $momento){ # Expiracao
    $infoCredencial += ";"
  } Else {
    $infoCredencial += "$($momento.ToString('dd/MM/yy HH:mm'));"
  }

  $momento = $credencial.PasswordLastSet
  if($null -eq $momento){ # mudancaSenha
    $infoCredencial += ";"
  } Else {
    $infoCredencial += "$($momento.ToString('dd/MM/yy HH:mm'));"
  }

  $infoCredencial += [System.String]::Concat("""","$($credencial.Description)",""";") # Descricao
  $infoCredencial += "$($credencial.CanonicalName);" # CanonicalName
  $infoCredencial += "$($credencial.ObjectGUID);" # ObjectGUID

#  $texto = '"'
#  Foreach ($grupo in $grupos){
#    $texto += $grupo.name + "+"
#  }
#  $texto += '"'
#  $infoCredencial += "$($texto)"

  $buffer += $infoCredencial

  # Atualiza a cada 50 caixas processadas
  if (($indice % 50 -eq 0) -or ($indice -eq $totalCredenciais)){ 
    Write-Progress -Activity "Coletando dados das credenciais" -Status "Progresso: $indice de $totalCredenciais coletadas" -PercentComplete (($indice / $totalCredenciais) * 100)
    Add-Content -Path $arquivo -Value $buffer -Encoding UTF8
    $buffer = @()
  }
}

Write-Progress -Activity "Coletando dados das credenciais" -PercentComplete 100

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()