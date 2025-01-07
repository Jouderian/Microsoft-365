#--------------------------------------------------------------------------------------------------------
# Descricao: Expira ou libera credenciais baseado em uma planilha com o agendamento
# Versao 1 (16/09/22) Jouderian Nobre
# Versao 2 (17/09/22) Jouderian Nobre
# Versao 3 (21/09/22) Jouderian Nobre
# Versao 4 (06/10/22) Jouderian Nobre
# Versao 5 (13/10/22) Jouderian Nobre
# Versao 6 (21/05/23) Jouderian Nobre
# Versao 7 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
#--------------------------------------------------------------------------------------------------------

$Modules = Get-Module -Name ImportExcel -ListAvailable
if($Modules.count -eq 0){
  Write-Host Instale o modulo do ImportExcel usando o comando abaixo:`n  Install-Module ImportExcel -ForegroundColor yellow
  Exit
}

Import-Module ImportExcel

$hoje = Get-Date -Uformat "%Y%m%d"
$arquivoUsuarios = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\Scripts\bloqueioDeUsuarios.xlsx"
$arquivoLog = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\Scripts\bloqueios_$($hoje).csv"

$usuarios = Import-Excel -Path $arquivoUsuarios -WorksheetName "Ferias"
Foreach ($usuario in $usuarios){
  if (($usuario.Comeco -eq $hoje) -or ($usuario.Fim -eq $hoje)){
    if (($usuario.Comeco -le $hoje) -and ($usuario.Fim -gt $hoje)){
      $Observacao = [System.String]::Concat( `
        "Ausente de ", `
        $usuario.Comeco.Substring(6,2), "/", `
        $usuario.Comeco.Substring(4,2), " ate ", `
        $usuario.Fim.Substring(6,2), "/", `
        $usuario.Fim.Substring(4,2) `
      )

      Write-Host $usuario.eMail "=>" $Observacao

      Set-ADAccountExpiration -Identity $usuario.AD -DateTime $usuario.Inicio
      Set-ADUser `
        -Identity $usuario.AD `
        -description $Observacao `
        -Replace @{info="Atualizado em $(Get-date -format 'dd/MM/yy HH:mm')"}

      Out-File -FilePath $arquivoLog -InputObject "$($usuario.Empresa),$($usuario.Nome),$($usuario.eMail),$($Observacao)" -Encoding UTF8 -append
    } else {
      Write-Host $usuario.eMail "=> Liberado"

      Clear-ADAccountExpiration -Identity $usuario.AD
      Set-ADUser `
        -Identity $usuario.AD `
        -Description " "
      Out-File -FilePath $arquivoLog -InputObject "$($usuario.Empresa),$($usuario.Nome),$($usuario.eMail),Liberado" -Encoding UTF8 -append
    }
  }
}

$usuarios = Import-Excel -Path $arquivoUsuarios -WorksheetName "Desligados"
Foreach ($usuario in $usuarios){
  if ($usuario.Momento -le $hoje){
    $userAD = {}
    $userAD = get-ADUser -Identity $usuario.AD -properties office,displayName,title,department,mail

    if($usuarioAD.Enabled){
      $Observacao = [System.String]::Concat( `
        "Desligado em ", `
        $usuario.Momento.Substring(6,2), "/", `
        $usuario.Momento.Substring(4,2), "/", `
        $usuario.Momento.Substring(2,2) `
      )

      $nomeInativo = [System.String]::Concat("[Inativo] ", $userAD.DisplayName)

      Write-Host $usuario.nome ":" $userAD.mail " =>" $Observacao
      Set-ADUser -Identity $usuario.AD `
        -Enabled $false `
        -DisplayName $nomeInativo `
        -Description $Observacao
      Out-File -FilePath $arquivoLog -InputObject "$($userAD.office),$($userAD.DisplayName),$($userAD.mail),$($Observacao)" -Encoding UTF8 -append
    }
  }
}

#Export-Excel -Path $arquivoLog -FreezeTopRow -AutoSize