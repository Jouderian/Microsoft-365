#--------------------------------------------------------------------------------------------------------
# Descricao: Bloquear os Usuários suspeitos
# Versao 1 (19/07/22) Jouderian Nobre
# Versao 2 (18/07/23) Jouderian Nobre: Alem do bloqueio passamos a identificar a credencial e move-la para uma OU
# Versao 3 (29/12/24) Jouderian Nobre: Corrige o recebimento do parametro Arquivo
# Versao 4 (12/05/25) Jouderian Nobre: Criado paramentros para mover a credencial para OU informada e limpar os grupos
#--------------------------------------------------------------------------------------------------------

param (
  [Parameter(Mandatory=$true)][string]$arquivo,
  [Parameter(Mandatory=$false)][string]$ouDestino, <# Move credencial para a OU informada: "OU=Suspeitos,DC=servidor,DC=srv" #>
  [Parameter(Mandatory=$false)][boolean]$removeGrupos = $true, <# Remove os grupos da credencial #>
  [Parameter(Mandatory=$false)][string]$mensagem <# Mensagem para registrar na descricao da credencial #>
)

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

#--------------------------------------------------------------------- VARIAVEIS
$inicio = Get-Date
$logs = "C:\ScriptsRotinas\credenciaisInativas\logs\inativacao_$($inicio.ToString('MMMyy')).txt"
$contadores = @{
  Total = 0
  Revogados = 0
  Erros = 0
}

gravaLOG -arquivo $logs -texto "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))"
gravaLOG -arquivo $logs -texto "[PARAMETROS] ouDestino: $($ouDestino) - removeGrupos: $($removeGrupos) - mensagem: $($mensagem)"

if (-not (Test-Path $arquivo)){
  gravaLOG -arquivo $logs -texto "Arquivo NAO encontrado: $arquivo" -erro:$true
  Exit
}

if (
  (-not ($ouDestino -match "^OU=.*")) -and
  (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDestino'"))
){
  gravaLOG -arquivo $logs -texto "O parâmetro ouDestino NAO existe no AD: $ouDestino" -erro:$true
  Exit
}

$Usuarios = Import-Csv -Delimiter:";" -Path $arquivo

Foreach ($Usuario in $Usuarios){

  $contadores.Total++

  try {
    Set-ADUser -Identity $Usuario.contaAD `
      -description "Suspeita de inatividade: $($inicio.ToString('MMM/yy'))." `
      -Enabled $false
  } catch {
    gravaLOG -arquivo $logs -texto "Atualizando $($Usuario.contaAD) no AD: $($_.Exception.Message)" -erro:$true
    $contadores.Erros++
    continue
  }

  if($ouDestino){
    try {
      #Remover TODOS os grupos do AD, exceto o grupo padrao "Domain Users"
      Get-ADUser -Identity $Usuario.contaAD | Move-ADObject -TargetPath ouDestino
    } catch {
      gravaLOG -arquivo $logs -texto "Movendo o $($Usuario.contaAD) de OU no AD: $($_.Exception.Message)" -erro:$true
      $contadores.Erros++
      continue
    }
  }

  if($true -eq $removeGrupos){
    try {
      #Remover TODOS os grupos do AD, exceto o grupo padrao "Domain Users"
      Get-ADPrincipalGroupMembership -Identity $Usuario.contaAD | Where-Object {($_.name -notmatch 'Domain Users')} | ForEach-Object {Remove-ADPrincipalGroupMembership -Identity $Usuario.contaAD -MemberOf $_ -Confirm:$False}
    } catch {
      gravaLOG -arquivo $logs -texto "Removendo os grupos do $($Usuario.contaAD) no AD: $($_.Exception.Message)" -erro:$true
      $contadores.Erros++
      continue
    }
  }

  try {
    #Mudando a senha da credencial para uma senha aleatoria
    $novaSenha = geraSenhaAleatoria
    Set-ADAccountPassword -Identity $Usuario.contaAD -NewPassword (ConvertTo-SecureString -AsPlainText $novaSenha -Force)
  } catch {
    gravaLOG -arquivo $logs -texto "Mudando a senha do $($Usuario.contaAD) no AD: $($_.Exception.Message)" -erro:$true
    $contadores.Erros++
  }

  $contadores.Revogados++
  gravaLOG -arquivo $logs -texto "$($contadores.Total)/$($Usuarios.Count) - $($Usuario.contaAD)"

}
gravaLOG -arquivo $logs -texto "[RESUMO] Revogados: $($contadores.Revogados) - Erros: $($contadores.Erros) > Duracao: $(((Get-Date) - $inicio).TotalMinutes) minutos"
