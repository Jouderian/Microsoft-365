<#
.SYNOPSIS
  Executa o script Orca (https://github.com/cammurray/orca) que analisa as configuração recomendada do Microsoft Defender para M365
.DESCRIPTION
  O script se conecta ao ambiente do Microsoft 365, executa o script Orca e gera um relatório em HTML com as configurações recomendadas.
.AUTHOR
  Jouderian Nobre
.VERSION
  01 (21/08/25) - Criacao do script
.OUTPUT
  O arquivo e gravado na pasta: C:\Users\<usuario>\AppData\Local\Microsoft\ORCA 
#> 

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Validacoes
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema."
VerificaModulo -NomeModulo "ORCA" -MensagemErro "O modulo Orca e necessario e nao esta instalado no sistema."

# Conectando ao Exchange Online
try {
  Import-Module ExchangeOnlineManagement
  Connect-ExchangeOnline -ShowBanner:$false
}
catch {
  gravaLOG -texto "Erro ao conectar ao Exchange Online: $($_.Exception.Message)" -tipo Erro -arquivo $logs -mostraTempo:$true
  Exit
}

# Executa a coleta do Orca
Invoke-ORCA -Output HTML -OutputOptions @{HTML = @{DisplayReport = $true } }