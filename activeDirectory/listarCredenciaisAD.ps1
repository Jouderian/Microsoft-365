#-------------------------------------------------------------------------------
# Descricao: Script para atualizar os dados das credenciais com base na QLP do RH
# Versao 1 (25/07/23) Jouderian Nobre
# :::
# Versao 4 (16/03/24) Jouderian Nobre: Melhoria no ajuste de mudanca de mes e inclusao de barra de progresso
# Versao 5 (20/08/24) Jouderian Nobre: Melhoria no tratamento dos caracteres dos campos de texto
# Versao 6 (05/10/24) Jouderian Nobre: Ajuste para tratar gestores com mais de 20 caracteres
# Versao 7 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
# Versao 8 (07/05/25) Jouderian Nobre: Ajuste para melhorar o tratamento de erros e rodar so servidor
#--------------------------------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

$indice = 0
$inicio = Get-Date
$versao = "2025.04"
$arquivoUsuarios = "C:\ScriptsRotinas\atualizaCredenciaisAD\QLP_$($versao).xlsx"
$arquivoLog = "C:\ScriptsRotinas\atualizaCredenciaisAD\Logs\syncQLP_$($inicio.ToString('yyMMdd_HHmmss')).csv"
$mensagem = "Atualizado pela QLP $($versao) em $($inicio.ToString('dd/MM/yy HH:mm'))"

$Modules = Get-Module -Name ImportExcel -ListAvailable
if($Modules.count -eq 0){
  Write-Host Instale o modulo do ImportExcel usando o comando abaixo:`n  Install-Module ImportExcel -ForegroundColor yellow
  Exit
}
Import-Module ImportExcel

Write-Host "`n`n`n`n`n`n`nInicio:" $inicio
$usuarios = Import-Excel -Path $arquivoUsuarios -WorksheetName "Relacao"

Out-File -FilePath $arquivoLog -InputObject "contaAD,nome,cidade,empresa,filial,departamento,cargo,gestor,codCC,nomeCC,situacao" -Encoding UTF8
$totalUsuarios = $usuarios.Count

Foreach ($usuario in $usuarios){

  $indice++
  $situacao = ""

  Write-Progress -Activity "Atualizando credenciais" -Status "Progresso: $indice de $totalUsuarios atualizados" -PercentComplete (($indice / $totalUsuarios) * 100)

#--------------------------------------------------------------- Tratando campos
  $nome = trataTexto -texto $usuario.nomeFuncionario -notacao "C"
  $empresa = trataTexto -texto $usuario.Empresa -notacao "C"
  $escritorio = trataTexto -texto $usuario.Escritorio -notacao "C"
  $departamento = trataTexto -texto $usuario.Departamento -notacao "C"
  $departamento = $departamento.replace('Sac', 'SAC')
  $cargo = trataTexto -texto $usuario.Cargo -notacao "C"
  $cargo = $cargo.replace(' Vi', ' VI')
  $cidade = trataTexto -texto $usuario.cidade -notacao "C"
  $centroDeCusto = trataTexto -texto $usuario.centroDeCusto -notacao "C"
  $gestor = $usuario.contaADgestor
  $gestor = $gestor.Substring(0, [Math]::Min(20, $gestor.Length))

#-------------------------------------------------------- Atualizando credencial
  try {
    $usuarioAD = Get-ADUser -Identity $Usuario.contaAD -Property enabled,description
  } catch {
    $situacao = $_.Exception.Message
    Out-File -FilePath $arquivoLog -InputObject "$($usuario.contaAD),$($nome),$($cidade),$($empresa),$($escritorio),$($Departamento),$($Cargo),$($gestor),$($usuario.codCC),$($centroDeCusto),$($situacao)" -Encoding UTF8 -append
    Continue
  }

  If ($usuarioAD.Enabled){
    try {
      Set-ADUser -Identity $usuario.contaAD `
      -DisplayName $nome `
      -City $cidade `
      -Company $empresa `
      -Office $escritorio `
      -Department $departamento `
      -Title $cargo `
      -Manager $gestor `
      -streetAddress $centroDeCusto `
      -postalCode $usuario.codCC `
      -Replace @{info=$mensagem} `
      -Country "BR"
      $situacao = "Atualizado"
    } catch {
      $situacao = $_.Exception.Message
      Out-File -FilePath $arquivoLog -InputObject "$($usuario.contaAD),$($nome),$($cidade),$($empresa),$($escritorio),$($Departamento),$($Cargo),$($gestor),$($usuario.codCC),$($centroDeCusto),$($situacao)" -Encoding UTF8 -append
      Continue
    }
  } else {
    $situacao = $usuarioAD.description
  }
  Out-File -FilePath $arquivoLog -InputObject "$($usuario.contaAD),$($nome),$($cidade),$($empresa),$($escritorio),$($Departamento),$($Cargo),$($gestor),$($usuario.codCC),$($centroDeCusto),$($situacao)" -Encoding UTF8 -append
}

Write-Progress -Activity "Atualizando credenciais" -PercentComplete 100

$final = Get-Date
Write-Host `nInicio: $inicio
Write-Host Final: $final
Write-Host Tempo: (NEW-TIMESPAN -Start $inicio -End $final).ToString()