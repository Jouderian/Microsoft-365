#--------------------------------------------------------------------------------------------------------
# Descricao: Executar o script Orca (https://github.com/cammurray/orca) que analisa as configuração recomendada do Microsoft Defender para M365
# Versao 01 (21/08/25) Jouderian Nobre
#--------------------------------------------------------------------------------------------------------
# Observacao: O arquivo e gravado na pasta: C:\Users\<usuario>\AppData\Local\Microsoft\ORCA 
#--------------------------------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Validacoes
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema."
VerificaModulo -NomeModulo "ORCA" -MensagemErro "O modulo Orca e necessario e nao esta instalado no sistema."

# Conectando ao Exchange Online
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -ShowBanner:$false

# Executa a coleta do Orca
Invoke-ORCA -Output HTML -OutputOptions @{HTML=@{DisplayReport=$true}}