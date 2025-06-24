#--------------------------------------------------------------------------------------------------------
# Autor: Fernando Olimpio
# Descricao: Lista as pastas de um email e gera uma listagem das pastas
# Versao: 1 (01/05/25) Olimpio
# Versao: 2 (03/06/25) Jouderian Nobre: Adequacao para usar biblioteca de funcoes
#--------------------------------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$folderQueries = @()
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaPastasCaixaPostal.txt"

# Validacoes
$caixaPostal = Read-Host "Entre com o endereco de eMail"
$tipo = Read-Host "Analise na caixa [P]rincipal ou [A]rquivada"
if ($tipo -match "[PpAa]"){
  $tipo = $tipo.ToUpper()
} else {
  Write-Host "Opcao invalida. Use P ou A"
  Exit
}

# Conectando ao Exchange Online
VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "O modulo Exchange Online Management e necessario e nao esta instalado no sistema."
try {
  Import-Module ExchangeOnlineManagement
  Connect-ExchangeOnline -ShowBanner:$false
} catch {
  gravaLOG -arquivo $logs -texto "$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) - Erro ao conectar ao Exchange Online: $($_.Exception.Message)" -erro:$true
  Exit
}

# Colectando as estatisticas das pastas
if($tipo -eq "P"){
  $folderStatistics = Get-MailboxFolderStatistics $caixaPostal
} elseif ($tipo -eq "A"){
  $folderStatistics = Get-MailboxFolderStatistics $caixaPostal -Archive
}

foreach ($folderStatistic in $folderStatistics){
  $folderId = $folderStatistic.FolderId;
  $folderPath = $folderStatistic.FolderPath;
  $foldersize = $folderStatistic.Foldersize;
  $folderitems = $folderStatistic.ItemsInFolder;

  $encoding= [System.Text.Encoding]::GetEncoding("us-ascii")
  $nibbler= $encoding.GetBytes("0123456789ABCDEF");
  $folderIdBytes = [Convert]::FromBase64String($folderId);
  $indexIdBytes = New-Object byte[] 48;
  $indexIdIdx=0;
  $folderIdBytes | Select-Object -skip 23 -First 24 | %{$indexIdBytes[$indexIdIdx++]=$nibbler[$_ -shr 4];$indexIdBytes[$indexIdIdx++]=$nibbler[$_ -band 0xF]}
  $folderQuery = "folderid:$($encoding.GetString($indexIdBytes))";

  $folderStat = New-Object PSObject
  Add-Member -InputObject $folderStat -MemberType NoteProperty -Name FolderPath -Value $folderPath
  Add-Member -InputObject $folderStat -MemberType NoteProperty -Name FolderQuery -Value $folderQuery
  Add-Member -InputObject $folderStat -MemberType NoteProperty -Name Foldersize -Value $Foldersize
  Add-Member -InputObject $folderStat -MemberType NoteProperty -Name ItemsInFolder -Value $folderitems

  $folderQueries += $folderStat
}
Write-Host "-----Select Folders-----"
$folderQueries | Out-GridView -OutputMode Multiple -Title 'Select folder/s:' 