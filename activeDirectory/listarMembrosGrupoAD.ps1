#--------------------------------------------------------------------------------------------------------
# Descricao: Relacao de computadores do AD
# Versao 1 (06/02/23) Jouderian Nobre
# Versao 2 (18/03/24) Jouderian Nobre: Melhoria para extracao dos dados
# Versao 3 (29/12/24) Jouderian Nobre: Passa a ler a variavel do Windows para local do arquivo
# Versao 4 (20/03/25) Jouderian Nobre: Incluindo a ultima alteração da maquina no AD
# Versao 5 (29/06/25) Jouderian Nobre: Otimizacao do script e melhoria nos logs
#--------------------------------------------------------------------------------------------------------

. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"

Clear-Host

# Declarando variaveis
$indice = 0
$inicio = Get-Date
$periodo = $inicio.AddDays(-90)
$arquivo = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\computadoresAD.csv"

Write-Host "`n`n`n`n`n"
Write-Host "$($inicio.ToString('dd/MM/yy HH:mm:ss')) | Consultado computadores no AD..."

# Conexoes
Import-Module ActiveDirectory

# Busca computadores no AD
$computadoresAD = Get-ADComputer `
  -Filter * `
  -Properties `
    Name, `
    LastLogonDate, `
    Modified, `
    OperatingSystem, `
    OperatingSystemVersion, `
    IPv4Address, `
    IPv6Address, `
    DNSHostName, `
    DistinguishedName

$total = $computadoresAD.Count

Write-Host "$(Get-Date -Format 'dd-MM-yy HH:mm:ss') | Gravando Arquivo..."
Out-File -FilePath $arquivo -InputObject "Nome;ultimoAcesso;ultimaModificacao;sistemaOperacional;versaoSO;IPv4;IPv6;DNSHostName;OU;arquivado;situacao" -Encoding UTF8

foreach ($computador in $computadoresAD){
  $indice++

  $ultimaComunicacao = $computador.LastLogonDate
  if ($computador.Modified -gt $ultimaComunicacao){
    $ultimaComunicacao = $computador.Modified
  }

  $infoComputador  = "$($computador.Name);" #Nome do Computador
  $infoComputador += "$($computador.LastLogonDate.ToString('dd/MM/yy HH:mm'));" #Ultimo Acesso
  $infoComputador += "$($computador.Modified.ToString('dd/MM/yy HH:mm'));" #Ultima Modificacao
  $infoComputador += "$($computador.OperatingSystem);" #Sistema Operacional
  $infoComputador += "$($computador.OperatingSystemVersion);" #Versao do SO
  $infoComputador += "$($computador.IPv4Address);" #IPv4
  $infoComputador += "$($computador.IPv6Address);" #IPv6
  $infoComputador += "$($computador.DNSHostName);" #DNS Host Name
  $infoComputador += "$($computador.DistinguishedName);" #OU
  $infoComputador += "$(if($computador.DistinguishedName.IndexOf(',OU=Archived') -ne -1){'SIM'} else {'Nao'});" #Arquivado
  $infoComputador += "$(if($ultimaComunicacao -cle $periodo){'Expirado'} else {'Normal'});" #Situacao

  # Adiciona a situacao ao buffer
  $buffer += $infoComputador

  # Atualiza a cada 10 computadores
  if (
    ($indice % 10 -eq 0) -or
    ($indice -eq $total)
  ){ 
    Write-Progress -Activity "Listando computadores" -Status "Progresso: $indice de $total catalogado" -PercentComplete ($indice / $total * 100)
    Add-Content -Path $arquivo -Value $buffer -Encoding UTF8
    $buffer = @()
  }
}

Write-Progress -Activity "Listando computadores" -PercentComplete 100

# Finalizando o script
$final = Get-Date
Write-Host "$($final.ToString('dd/MM/yy HH:mm:ss')) | Final => Duracao: $(($inicio - $final).TotalMinutes)"