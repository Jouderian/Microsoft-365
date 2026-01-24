#-------------------------------------------------------------------------------
# Descricao: Faz manutencao nas licencas dos usuarios de uma lista
# Versao 1 02/06/21 Andre Cardoso
# Versao 2 (31/01/24) Jouderian Nobre: Remover as licenas de uma lista
# Versao 3 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
# Versao 4 (10/01/25) Jouderian Nobre: Ajustes para remover e incluir licenças
# Versao 5 (26/12/25) Jouderian Nobre: Permitir múltiplas licenças e operações independentes
# Versao 6 (21/01/26) Jouderian Nobre: Inclusao de validação de modulos e logs
#-------------------------------------------------------------------------------
# A fazer:
#   - Estudar: https://learn.microsoft.com/pt-br/powershell/module/microsoft.graph.users.actions/set-mguserlicense?view=graph-powershell-1.0
#-------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$qtdCaixas = 0
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\mudarLicencas_$($inicio.ToString('MMMyy')).txt"
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\eMails.txt"

# Para obter os SkuId, use: Get-MgSubscribedSku -All | Select SkuId, SkuPartNumber, ConsumedUnits
$licencasRemover = @(
  "f245ecc8-75af-4f8e-b61f-27d8114de5f3" <# Business Standard #>
  #"12a0b0ef-3d7c-4456-8f61-aa3817576c8d" <# O365 E1 Plus #>
  #"c2273bd0-dff7-4215-9ef5-2c7bcfb06425" <# AppsEnterprise #>
  #"18181a46-0d4e-45cd-891e-60aabd171b4e" <# O365 E1 #>
  #"80b2d799-d2ba-4d2a-8842-fb0d0f3a4b82" <# Online Kiosk #>
  #"6fd2c87f-b296-42f0-b197-1e91e994b900" <# O365 E3 #>
  #"4b585984-651b-448a-9e53-3b10f069cf7f" <# O365 F3 #>
)
  
$licencasIncluir = @(
  @{SkuId = "12a0b0ef-3d7c-4456-8f61-aa3817576c8d"}, <# O365 E1 Plus #>
  @{SkuId = "c2273bd0-dff7-4215-9ef5-2c7bcfb06425"} <# AppsEnterprise #>
  #@{SkuId = "50f60901-3181-4b75-8a2c-4c8e4c1d5a72"} <# M365 F1 #>
  #@{SkuId = "f245ecc8-75af-4f8e-b61f-27d8114de5f3"} <# Business Standard #>
  #@{SkuId = "3b555118-da6a-4418-894f-7df1e2096870"} <# Business Basic #>
  #@{SkuId = "80b2d799-d2ba-4d2a-8842-fb0d0f3a4b82"} <# Online Kiosk #>
  #@{SkuId = "19ec0d23-8335-4cbd-94ac-6050e30712fa"} <# Online Plan2 #>
  #@{SkuId = "18181a46-0d4e-45cd-891e-60aabd171b4e"} <# O365 E1 #>
)

gravaLOG -arquivo $logs -texto "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))"
gravaLOG -arquivo $logs -texto "Iniciando a troca do licenciamento de caixas postais do Microsoft 365"

# Validacoes
VerificaModulo -arquivoLogs $logs -NomeModulo "Microsoft.Graph" -MensagemErro "O modulo Microsoft Graph e necessario e nao esta instalado no sistema."

try {
  Import-Module -Name Microsoft.Graph.Users
  Connect-MgGraph -Scopes User.ReadWrite.All, Organization.Read.All -NoWelcome
} catch {
  gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Erro ao conectar ao Microsoft Graph: $($_.Exception.Message)" -erro:$true
  Exit
}

gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Importando caixas para ajuste"
$Users = Import-Csv -Delimiter:";" -Path $arquivo
if ($Users.Count -eq 0){
  gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Arquivo $arquivo encontra-se vazio" -erro:$true
  Exit
}

gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Ajustando as licencas das $($Users.Count) caixas importadas"
$Users | ForEach-Object {
  try {
    $params = @{
      UserId = $_.eMail
    }
    if ($licencasIncluir.Count -gt 0){
      $params.AddLicenses = $licencasIncluir
    }
    if ($licencasRemover.Count -gt 0){
      $params.RemoveLicenses = $licencasRemover
    }
    if ($params.Count -gt 1){
      Set-MgUserLicense @params
      $qtdCaixas++
    } else {
      Write-Host "Nenhuma operacao de licenca especificada para $($_.eMail)"
    }
  } catch {
    gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Problema com a troca da licenca na caixa $($_.eMail): $($_.Exception.Message)" -erro:$true
  }
}
gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Foi ajsutado o licenciamento de $($qtdCaixas) caixas postais"

Disconnect-MgGraph
gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Ambientes desconectados."

$final = Get-Date
gravaLOG -arquivo $logs -texto "$($final.ToString('dd/MM/yy HH:mm:ss')) - Tempo de duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())"