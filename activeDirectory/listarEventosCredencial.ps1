# Descricao: Localiza eventos de segurança de credenciais no AD (bloqueio, desbloqueio, alteração de senha e mudanças de informações)
# Eventos suportados:
# - 4723: Tentativa de alteração de senha (usuário)
# - 4724: Tentativa de redefinir senha (administrador)
# - 4725: Bloqueio de conta de usuário
# - 4738: Alteração de conta de usuário (mudanças em atributos como email, telefone, etc.)
# - 4767: Desbloqueio de conta de usuário
# Observacoes:
# - Requer permissao para ler Security Log dos Domain Controllers (execute como Domain Admin ou equivalente).
# - Requer modulo ActiveDirectory para descobrir DCs (opcional).
# - Pode demorar se houver muitos DCs / periodo longo.
# Versao: 2 (2026-03-30) GitHub Copilot - Adicionado eventos de alteração de informações

Clear-Host

# Solicita parametros
$usuario = Read-Host "Informe o samAccountName ou UPN do usuario a procurar (ex: j.nobre ou j.nobre@dominio.com)"
$periodoDias = Read-Host "Pesquisar quantos dias para tras? (padrao 30)"

if (-not [int]::TryParse($periodoDias,[ref]$null)){
  $periodoDias = 30
} else {
  $periodoDias = [int]$periodoDias
}

$start = (Get-Date).AddDays(-$periodoDias)
$end = Get-Date

# Obtém lista de Domain Controllers (se possivel)
Import-Module ActiveDirectory -ErrorAction SilentlyContinue
if (Get-Module -Name ActiveDirectory){
  try {
    $dcs = Get-ADDomainController -Filter * | Select-Object -ExpandProperty HostName
  } catch {
    $dcs = @()
  }
} else {
  $dcs = @()
}

if (-not $dcs -or $dcs.Count -eq 0){
  $single = Read-Host "Nao foi possivel listar DCs automaticamente. Informe hostname do DC a consultar (ou ENTER para localhost)"
  if ([string]::IsNullOrWhiteSpace($single)){
    $dcs = @('localhost')
  } else {
    $dcs = @($single)
  }
}

Write-Host "  Pesquisando eventos: alteração senha (4723), redefinição senha (4724), bloqueio (4725), alteracao info (4738), desbloqueio (4767) entre $($start) e $($end) nos DCs: $($dcs -join ', ')" -ForegroundColor Cyan

$result = @()

foreach ($dc in $dcs){
  Write-Host "    Consultando $dc..." -ForegroundColor Yellow
  try {
    $evs = Get-WinEvent `
      -ComputerName $dc `
      -FilterHashtable @{
        LogName='Security';
        Id=@(4723,4724,4725,4738,4767);
        StartTime=$start;
        EndTime=$end
      } `
      -ErrorAction Stop
  } catch {
    Write-Warning "      Erro ao consultar $($dc): $($_.Exception.Message)"
    continue
  }

  foreach ($ev in $evs){
    try {
      [xml]$x = $ev.ToXml()
      $dataNodes = $x.Event.EventData.Data

      # Extrai nome do usuário alvo (varia conforme o evento)
      $target = ($dataNodes | Where-Object { $_.Name -eq 'TargetUserName' }).'#text'
      if (-not $target) { $target = ($dataNodes | Where-Object { $_.Name -eq 'TargetUser' }).'#text' }
      if (-not $target) { $target = ($dataNodes | Where-Object { $_.Name -eq 'SamAccountName' }).'#text' }

      # compara ignorando maiusculas/minusculas. aceita samAccountName ou UPN parcial
      if (
        $null -ne $target -and
        (
          $target.ToLower() -eq $usuario.ToLower() -or
          $usuario.ToLower().EndsWith('@') -and
          $target.ToLower().Contains($usuario.ToLower()) -or
          $target.ToLower().Contains($usuario.ToLower())
        )
      ){
        $actor = ($dataNodes | Where-Object { $_.Name -eq 'SubjectUserName' }).'#text'
        $actorDomain = ($dataNodes | Where-Object { $_.Name -eq 'SubjectDomainName' }).'#text'
        $actorSid = ($dataNodes | Where-Object { $_.Name -eq 'SubjectUserSid' }).'#text'
        $logonId = ($dataNodes | Where-Object { $_.Name -eq 'SubjectLogonId' }).'#text'

        # Extrai detalhes específicos conforme o tipo de evento
        $eventDetails = ""
        switch ($ev.Id) {
          4723 { $eventDetails = "Alteração de senha (pelo usuário)" }
          4724 { $eventDetails = "Redefinição de senha (por administrador)" }
          4725 { $eventDetails = "Bloqueio de conta" }
          4738 { 
            # Para eventos de alteração de conta, tenta extrair quais atributos foram mudados
            $changedAttr = ($dataNodes | Where-Object { $_.Name -eq 'ChangedAttributes' }).'#text'
            if ($changedAttr) {
              $eventDetails = "Alteração de atributos: $changedAttr"
            } else {
              $eventDetails = "Alteração de informações da conta"
            }
          }
          4767 { $eventDetails = "Desbloqueio de conta" }
          default { $eventDetails = "Evento de segurança da credencial" }
        }

        $result += [PSCustomObject]@{
          DC             = $dc
          TimeCreated    = $ev.TimeCreated
          EventId        = $ev.Id
          EventType      = $eventDetails
          TargetUserName = $target
          ActorUserName  = $actor
          ActorDomain    = $actorDomain
          ActorSid       = $actorSid
          ActorLogonId   = $logonId
          EventRecordId  = $ev.RecordId
          MessagePreview = ($ev.Message -split "`n")[0..([math]::Min(3,($ev.Message -split "`n").Count-1))] -join ' | '
        }
      }
    } catch {
      Write-Warning "      Falha ao analisar evento RecordId $($ev.RecordId) em $($dc): $($_.Exception.Message)"
    }
  }
}

if ($result.Count -eq 0){
  Write-Host "  Nenhum evento encontrado para '$usuario' no periodo especificado." -ForegroundColor Yellow
} else {
  $result = $result | Sort-Object TimeCreated -Descending
  $result | Format-Table @{Name='Time';Expression={$_.TimeCreated.ToString('dd/MM/yy HH:mm:ss')}}, EventId, EventType, DC, TargetUserName, ActorUserName, ActorDomain -AutoSize

  $export = Read-Host "Deseja exportar o resultado para CSV? (S/N)"
  if ($export -match '^[Ss]'){
    $out = Read-Host "Informe caminho do arquivo (ex: C:\Temp\desbloqueios.csv)"
    $result | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
    Write-Host "Exportado para $($out)"
  }
}

# Observacao final
Write-Host "Concluido."