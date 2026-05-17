---
description: Plano técnico de implementação para refatoração e evolução do script validaGPOs.ps1
---

# Plano de Implementação — Evolução do `validaGPOs.ps1`

Este documento detalha o plano técnico, arquitetura e passos de implementação para a evolução do script [`validaGPOs.ps1`](/activeDirectory/validaGPOs.ps1).

---

## 1. Arquitetura das Alterações Técnicas

### 1.1. Eliminação Completa de Referências de RSoP
Serão removidas:
- Variáveis de parâmetro: `$UseRsop`, `$ComputersCsv`, `$RsopUsersPerOu`, `$RsopTimeoutSec`, `$PingTimeoutMs`, `$PortTimeoutMs`, `$WinrmTimeoutSec`, `$WmiTimeoutSec`.
- Variáveis locais: `$rsopOutFolder`, `$UseRSOP`.
- Bloco de console de log sobre RSoP ativo/inativo.

### 1.2. Portabilidade e Helpers Internos
O script manterá independência de [`bibliotecaDeFuncoes.ps1`](/bibliotecaDeFuncoes.ps1). Criaremos as seguintes rotinas locais:

#### A. Helper `Grava-LogLocal`
Substitui as chamadas coloridas locais e escreve no console e no arquivo de log síncronamente.
```powershell
function Grava-LogLocal {
  param(
    [Parameter(Mandatory = $true)]
    [string]$texto,
    [ValidateSet('INF', 'OK', 'WRN', 'ERR', 'STP')][string]$tipo = 'INF'
  )

  $prefixo = @{
    INF = '[INFO ] ';
    OK  = '[OK   ] ';
    WRN = '[AVISO] ';
    ERR = '[ERRO ] ';
    STP = '[PASSO] '
  }[$tipo]

  $color = @{
    INF = 'Cyan';
    OK  = 'Green';
    WRN = 'Yellow';
    ERR = 'Red';
    STP = 'Magenta'
  }[$tipo]

  # Fallback caso a cor não seja definida
  if (-not $color){ $color = 'White' }

  # Adiciona timestamp
  $mensagem = "$prefixo$((Get-Date).ToString('dd/MM/yy HH:mm:ss')) $texto"

  Write-Host $mensagem -ForegroundColor $color
  if ($script:logExecutionPath){
    try {
      Add-Content -Path $script:logExecutionPath -Value $mensagem -Encoding UTF8
    } catch {
      Write-Host "Falha ao gravar no arquivo de log: $($_.Exception.Message)" -ForegroundColor Red
    }
  }
}
```

#### B. Helper `Verifica-ModuloLocal`
Substitui a dependência externa e a função `Require-Module` antiga:
```powershell
function Verifica-ModuloLocal {
  param([Parameter(Mandatory = $true)][string]$nomeModulo)

  $modulo = Get-Module -Name $nomeModulo -ListAvailable
  if (-not $modulo){
    Grava-LogLocal -texto "Módulo '$nomeModulo' não encontrado localmente." -tipo ERR
    $confirm = Read-Host "O módulo '$nomeModulo' (RSAT) é obrigatório. Deseja tentar instalá-lo da PSGallery agora? [S]im ou [N]ão"
    if ($confirm -match '^[sS]'){
      Grava-LogLocal -texto "Instalando o módulo '$nomeModulo' na sessão atual..." -tipo STP
      try {
        Install-Module -Name $nomeModulo -Repository PSGallery -AllowClobber -Scope CurrentUser -Force
        Grava-LogLocal -texto "Módulo '$nomeModulo' instalado com sucesso." -tipo OK
      } catch {
        Grava-LogLocal -texto "Falha ao instalar módulo: $($_.Exception.Message). Instale o RSAT e tente novamente." -tipo ERR
        Exit 1
      }
    } else {
      Grava-LogLocal -texto "Execução abortada devido à falta do módulo '$nomeModulo'." -tipo ERR
      Exit 1
    }
  }
  Import-Module $nomeModulo -ErrorAction Stop
}
```

### 1.3. Otimização de Performance no Active Directory
1. **Query Principal Leve:**
   Modificar a chamada inicial do `Get-ADUser` para filtrar apenas a propriedade `Enabled` (o `DistinguishedName` vem nativamente e é ultra leve).
   ```powershell
   $users = Get-ADUser -Filter * -SearchBase $searchBase -SearchScope Subtree -Properties Enabled
   ```
2. **Lazy Loading de Amostras de Usuários por OU:**
   Caso `$includeUsersSample` esteja ativo, em vez de processar todos na memória, o script buscará a amostra pontualmente apenas para a OU em processamento dentro do loop principal:
   ```powershell
   if ($includeUsersSample) {
     $sample = Get-ADUser -Filter * -SearchBase $ouDn -SearchScope OneLevel | Select-Object -First $usersSampleSize -ExpandProperty SamAccountName
     # Mapeia na tabela do HTML correspondente
   }
   ```

---

## 2. Mapa de Variáveis e Nomenclatura (camelCase)

Todas as variáveis internas serão convertidas sistematicamente de PascalCase para camelCase:

- `$SearchBase` ➔ `$searchBase`
- `$IncludeUsersSample` ➔ `$includeUsersSample`
- `$UsersSampleSize` ➔ `$usersSampleSize`
- `$OutputPath` ➔ `$outputPath`
- `$TargetDn` ➔ `$targetDn`
- `$LabelOuDn` ➔ `$labelOuDn`
- `$OuOrContainerDn` ➔ `$ouOrContainerDn`
- `$DomainDn` ➔ `$domainDn`
- `$UseRSOP` / `$rsopOutFolder` ➔ Removidos.

---

## 3. Roteiro Passo a Passo de Execução

1. **Alterar o Cabeçalho Help:** Substituir o bloco de comentários no início do script de acordo com a autoria de Felipe Aquino e data de criação de 05/04/26.
2. **Substituir Parâmetros:** Limpar o bloco de parâmetros `param(...)` de todas as variáveis de RSoP e pré-teste, mantendo apenas `$searchBase`, `$includeUsersSample` e `$usersSampleSize`.
3. **Adicionar Parâmetro de Log:** Adicionar o parâmetro de entrada `[string]$logPath` que terá o valor padrão `validaGPOs_execution.log` na mesma pasta do script.
4. **Inserir Helpers Locais:** Substituir as funções utilitárias antigas pelos novos helpers `Grava-LogLocal` e `Verifica-ModuloLocal`.
5. **Atualizar Variáveis Internas:** Refatorar sistematicamente todas as ocorrências de variáveis PascalCase para camelCase em todo o escopo do código.
6. **Otimizar Loops e Performance:** Reescrever a query do `Get-ADUser` e otimizar a amostragem de usuários de forma lazy.
7. **Consolidar Geração de HTML:** Garantir que o HTML seja montado utilizando as novas variáveis e helpers locais perfeitamente.
8. **Envolver em Try-Catch Global:** Colocar o código de execução principal sob um bloco try-catch global que registra qualquer erro fatal com `Grava-LogLocal -tipo ERR`.
9. **Documentar e Testar:** Atualizar o arquivo [`validaGPOs.md`](/docs/activeDirectory/validaGPOs.md) com a sinopse e detalhes corretos.
