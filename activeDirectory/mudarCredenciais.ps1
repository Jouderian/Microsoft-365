#-------------------------------------------------------------------------------
# Descricao: Muda o nome da credencial, dominio e email
# Versao 1 (30/01/25) Jouderian Nobre
# Versao 2 (24/01/26) Jouderian Nobre: Melhorias no log e script
#-------------------------------------------------------------------------------
# Observacoes:
#   - O arquivo CSV deve conter as colunas: samAccountNameAtual;UPNatual;samAccountNameNovo;UPNnovo
#   - NovoDominio é opcional (deixa-lo vazio para nao mudar)
#   - Se NovoDominio for diferente do atual, o UPN sera ajustado automaticamente
#-------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$indice = 0
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\mudarCredenciais_$($inicio.ToString('MMMyy')).txt"
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\credenciais.csv"

gravaLOG -arquivo $logs -texto "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))"
gravaLOG -arquivo $logs -texto "Lendo arquivos $arquivo"

$credenciais = Import-Csv -Delimiter:";" -Path $arquivo
$total = $credenciais.Count

gravaLOG -arquivo $logs -texto "iniciando a mudanca de $total credenciais"
foreach ($credencial in $credenciais){
  $indice++
  Write-Progress -Activity "Mudando credenciais" -Status "$($credencial.samAccountNameAtual): $indice/$total" -PercentComplete ($indice / $total * 100)

  $usuario = get-aduser -Filter {SamAccountName -eq $credencial.samAccountNameAtual}
  if ($null -eq $usuario){
    gravaLOG -arquivo $logs -texto "Credencial $($credencial.samAccountNameAtual) nao encontrado no AD" -erro:$true
    continue
  }

  # Obtenha os valores do CSV
  $samAccountNameAtual = $credencial.samAccountNameAtual
  $UPNatual = $credencial.UPNatual
  $samAccountNameNovo = $credencial.samAccountNameNovo
  $UPNnovo = $credencial.UPNnovo
  
  try {
    # Define parametros para Set-ADUser
    $parametros = @{
      Identity = $SamAccountNameAtual
      SamAccountName = $samAccountNameNovo
      UserPrincipalName = $UPNnovo
    }

    # Atualize o SamAccountName e o UPN
    Set-ADUser @parametros

    # Adicione o antigo UPN como endereco de email alternativo (smtp)
    $listaEnderecos = @("smtp:$UPNatual")

    $enderecosPrincipais = $usuario.proxyAddresses | Where-Object {$_ -cmatch '^SMTP:'}
    if ($enderecosPrincipais){
      $listaEnderecos += @($enderecosPrincipais | ForEach-Object { $_.Replace('SMTP:', 'smtp:') })
    }
      
    $listaEnderecos = @("SMTP:$UPNnovo") + $listaEnderecos
    gravaLOG -arquivo $logs -texto "Atualizando endereco de email para: $UPNnovo"

    # Atualize os enderecos de proxy
    Set-ADUser `
      -Identity $samAccountNameNovo `
      -Add @{proxyAddresses=$listaEnderecos}

    gravaLOG -arquivo $logs -texto "Credencial $samAccountNameAtual alterada com sucesso para $samAccountNameNovo"

  } catch {
    gravaLOG -arquivo $logs -texto "Erro ao atualizar credencial $samAccountNameAtual : $($_.Exception.Message)" -erro:$true
  }

}
Write-Progress -Activity "Mudando credenciais" -PercentComplete 100

$final = Get-Date
gravaLOG -arquivo $logs -texto "$($final.ToString('dd/MM/yy HH:mm:ss')) - Tempo de duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())"