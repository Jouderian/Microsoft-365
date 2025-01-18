#-------------------------------------------------------------------------------
# Descricao: Faz manutencao nas licencas dos usuarios de uma lista
# Versao 1 02/06/21 Andre Cardoso
# Versao 2 (31/01/24) Jouderian Nobre: Remover as licenas de uma lista
# Versao 3 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
# Versao 4 (10/01/25) Jouderian Nobre: Ajustes para remover e incluir licenças
#-------------------------------------------------------------------------------
# A fazer:
#   - Estudar: https://learn.microsoft.com/pt-br/powershell/module/microsoft.graph.users.actions/set-mguserlicense?view=graph-powershell-1.0
#-------------------------------------------------------------------------------

Clear-Host

# Conectando ao ambiente
Connect-MgGraph -NoWelcome -Scopes User.ReadWrite.All, Organization.Read.All # Se Precisar instar o modulo do Microsoft.Graph use o comando: Install-Module Microsoft.Graph

# Variaveis
$qtdCaixas = 0
$inicio = Get-Date
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaDeCaixasPostais.csv"

# Para obter os SkuId, use: Get-MgSubscribedSku -All
$licencasRemover = "18181a46-0d4e-45cd-891e-60aabd171b4e" <# O365  E1 #>
#"6fd2c87f-b296-42f0-b197-1e91e994b900" <# O365 E3 #>
#"4b585984-651b-448a-9e53-3b10f069cf7f" <# O365 F3 #>
#"cdd28e44-67e3-425e-be4c-737fab2899d3" <# AppsBusiness #>

$licencasIncluir = @(
  @{SkuId = "3b555118-da6a-4418-894f-7df1e2096870"} <# Business Basic #>
)
#  @{SkuId = "80b2d799-d2ba-4d2a-8842-fb0d0f3a4b82"}, <# Online Kiosk #>
#  @{SkuId = "19ec0d23-8335-4cbd-94ac-6050e30712fa"}  <# Online Plan2 #>
#  @{SkuId = "18181a46-0d4e-45cd-891e-60aabd171b4e"}, <# O365  E1 #>
#  @{SkuId = "12a0b0ef-3d7c-4456-8f61-aa3817576c8d"}  <# O365 E1 Plus #>
#  @{SkuId = "c2273bd0-dff7-4215-9ef5-2c7bcfb06425"}, <# AppsEnterprise #>
#  @{SkuId = "50f60901-3181-4b75-8a2c-4c8e4c1d5a72"}  <# M365 F1 #>

Write-Host Inicio: $inicio
Write-Host Importando caixas para ajuste
$Users = Import-Csv -Delimiter:";" -Path $arquivo

Write-Host "Ajustando as licencas das caixas abaixo"
$Users | ForEach-Object {
  try {
    Set-MgUserLicense `
      -UserId $_.UPN `
      -AddLicenses $licencasIncluir `
      -RemoveLicenses $licencasRemover
    $qtdCaixas++
  } catch {
    Write-Host "Problema com a troca da licença na caixa $($Users._UPN): $($_)"
  }
}
Write-Host "`nTotal de caixas alteradas: $($qtdCaixas)/$($Users.Count)"

$final = Get-Date
Write-Host "`nInicio:" $inicio
Write-Host "Final:" $final
Write-Host "Tempo:" (NEW-TIMESPAN -Start $inicio -End $final).ToString()