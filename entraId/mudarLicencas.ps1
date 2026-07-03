<#
  .SYNOPSIS
    Faz manutencao nas licencas dos usuarios de uma lista
  .DESCRIPTION
    O script se conecta ao ambiente do Microsoft 365, importa as informações gravadas no arquivo CSV e adiciona os membros ao grupo.
  .AUTHOR
    Andre Cardoso
  .CREATED
    02/06/21
  .VERSION
    2 (31/01/24) Jouderian Nobre: Remover as licencas de uma lista
    3 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
    4 (10/01/25) Jouderian Nobre: Ajustes para remover e incluir licenças
    5 (26/12/25) Jouderian Nobre: Permitir múltiplas licenças e operações independentes
    6 (21/01/26) Jouderian Nobre: Inclusao de validação de modulos e logs
    7 (05/04/26) Jouderian Nobre: Atualizacao da documentacao
#>

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
  @{SkuId = "12a0b0ef-3d7c-4456-8f61-aa3817576c8d" }, <# O365 E1 Plus #>
  @{SkuId = "c2273bd0-dff7-4215-9ef5-2c7bcfb06425" } <# AppsEnterprise #>
  #@{SkuId = "50f60901-3181-4b75-8a2c-4c8e4c1d5a72"} <# M365 F1 #>
  #@{SkuId = "f245ecc8-75af-4f8e-b61f-27d8114de5f3"} <# Business Standard #>
  #@{SkuId = "3b555118-da6a-4418-894f-7df1e2096870"} <# Business Basic #>
  #@{SkuId = "80b2d799-d2ba-4d2a-8842-fb0d0f3a4b82"} <# Online Kiosk #>
  #@{SkuId = "19ec0d23-8335-4cbd-94ac-6050e30712fa"} <# Online Plan2 #>
  #@{SkuId = "18181a46-0d4e-45cd-891e-60aabd171b4e"} <# O365 E1 #>
)

gravaLOG "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))" -tipo WRN -arquivo $logs
gravaLOG "Iniciando a troca do licenciamento de caixas postais do Microsoft 365" -tipo INF -arquivo $logs

# Validacoes
VerificaModulo -NomeModulo "Microsoft.Graph" -MensagemErro "O modulo Microsoft Graph e necessario e nao esta instalado no sistema." -arquivoLogs $logs

try {
  Import-Module -Name Microsoft.Graph.Users
  Connect-MgGraph -Scopes User.ReadWrite.All, Organization.Read.All -NoWelcome
}
catch {
  gravaLOG "Erro ao conectar ao Microsoft Graph: $($_.Exception.Message)" -tipo ERR -arquivo $logs
  Exit
}

gravaLOG "Importando caixas para ajuste" -tipo INF -arquivo $logs -mostraTempo:$true
$Users = Import-Csv -Delimiter:";" -Path $arquivo
if ($Users.Count -eq 0) {
  gravaLOG "Arquivo $arquivo encontra-se vazio" -tipo ERR -arquivo $logs -mostraTempo:$true
  Exit
}

gravaLOG "Ajustando as licencas das $($Users.Count) caixas importadas" -tipo INF -arquivo $logs -mostraTempo:$true
$Users | ForEach-Object {
  try {
    $params = @{
      UserId = $_.eMail
    }
    if ($licencasIncluir.Count -gt 0) {
      $params.AddLicenses = $licencasIncluir
    }
    if ($licencasRemover.Count -gt 0) {
      $params.RemoveLicenses = $licencasRemover
    }
    if ($params.Count -gt 1) {
      Set-MgUserLicense @params
      $qtdCaixas++
    }
    else {
      gravaLOG "Nenhuma operacao de licenca especificada para $($_.eMail)" -tipo INF -arquivo $logs -mostraTempo:$true
    }
  }
  catch {
    gravaLOG "Problema com a troca da licenca na caixa $($_.eMail): $($_.Exception.Message)" -tipo ERR -arquivo $logs -mostraTempo:$true
  }
}
gravaLOG "Foi ajsutado o licenciamento de $($qtdCaixas) caixas postais" -tipo INF -arquivo $logs -mostraTempo:$true

Disconnect-MgGraph
gravaLOG "Ambientes desconectados." -tipo INF -arquivo $logs -mostraTempo:$true

$final = Get-Date
gravaLOG "Tempo de duracao: $((NEW-TIMESPAN -Start $inicio -End $final).ToString())" -tipo WRN -arquivo $logs -mostraTempo:$true