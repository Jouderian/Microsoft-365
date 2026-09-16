---
description: Backlog persistente do projeto — tarefas pendentes e ideias de melhoria
---

# Backlog (Pendente)

> Itens marcados com **[P1]** bloqueiam o uso do repositório fora da máquina de origem ou têm
> consequência destrutiva em produção. **[P2]** são defeitos de corretude e robustez.
> **[P3]** são higiene, padronização e dívida de processo.
>
> _Origem: análise geral do repositório em 16/09/26._

---

## P1 — Portabilidade e Segurança Operacional

### Caminho absoluto da biblioteca em 28 scripts

- **[CORREÇÃO]** Substituir o dot-source com caminho absoluto por caminho relativo ao script.
  Hoje existem **três** caminhos diferentes para a mesma dependência:
  - `C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1` (27 scripts)
  - `$env:ONEDRIVE\Documentos\WindowsPowerShell\Scripts\PUBLICO\Microsoft-365\bibliotecaDeFuncoes.ps1` (`entraId/listarMembrosListas.ps1:51`)
  - A biblioteca de fato versionada na raiz do repositório

  Alvo: `. (Join-Path $PSScriptRoot '..\bibliotecaDeFuncoes.ps1')` em todos os scripts.
  - _Impacto:_ nenhum script roda após um `git clone` limpo.
  - _Avaliar:_ converter a biblioteca em módulo `.psm1` com `Export-ModuleMember` e usar
    `Import-Module`, o que também resolve o namespace global de funções.

### Consolidar os dois scripts de exclusão de grupos vazios

- **[REFATORAÇÃO]** `entraId/apagarListasSemMembros.ps1` e `entraId/listarMembrosListas.ps1`
  implementam a mesma operação destrutiva (linhas 73/95 e 107/167, respectivamente), mas apenas
  o segundo tem trava (`-Acao ApenasListar` como padrão). Aposentar o primeiro em favor do segundo.
  - _Impacto:_ hoje existe um caminho de exclusão irreversível sem confirmação nem simulação.

### Reduzir o raio de alcance da exclusão de Grupos de Segurança

- **[CORREÇÃO]** O filtro `Get-MgGroup -Filter "securityEnabled eq true"` alcança grupos que são
  **legitimamente vazios** e cuja exclusão quebra o tenant:
  - grupos de licenciamento baseado em grupo (`assignedLicenses`);
  - grupos alvo de políticas de Acesso Condicional;
  - grupos de atribuição de app role (`appRoleAssignments`);
  - grupos dinâmicos (`groupTypes -contains 'DynamicMembership'`) cuja regra pode estar
    temporariamente sem correspondência.

  Adicionar lista de exclusão por esses critérios antes de qualquer `Remove-MgGroup`.

### Adicionar `-WhatIf` aos scripts destrutivos

- **[MELHORIA]** Nenhum script usa `SupportsShouldProcess`, apesar de 6 executarem exclusões
  (`removerComputadores.ps1`, `apagarListasSemMembros.ps1`, `listarMembrosListas.ps1`,
  `removerDispositivos.ps1`, `removerArquivosTemporarios.ps1`, `removerDominio.ps1`).
  Apenas `removerDominio.ps1:18` tem um `[switch]$WhatIf` manual.
  Padronizar com `[CmdletBinding(SupportsShouldProcess)]` + `$PSCmdlet.ShouldProcess(...)`.

---

## P2 — Corretude e Robustez

### Geração de CSV sem escape

- **[CORREÇÃO]** `exchangeOnline/listarCaixasPostais.ps1:225+`, `activeDirectory/listarComputadores.ps1`
  e `activeDirectory/listarCredenciais.ps1` montam o CSV por concatenação de string. Um
  `DisplayName` contendo o delimitador desloca todas as colunas seguintes. O aspeamento é
  inconsistente: `Departamento`, `Cargo` e `Licencas` são quoted; `Nome`, `Cidade` e `Empresa` não.
  - _Alvo:_ `[PSCustomObject]` + `Export-Csv -NoTypeInformation -Encoding UTF8`.
  - _Ganho colateral:_ remove ~60 linhas de concatenação manual em `listarCaixasPostais.ps1`.
  - _Atenção:_ conciliar com o item de `StreamWriter` mais abaixo — as duas mudanças competem
    pelo mesmo trecho de código e devem ser decididas juntas.

### Encoding: 28 scripts com acentuação e sem BOM

- **[CORREÇÃO]** 28 arquivos `.ps1` contêm caracteres acentuados e **não** têm BOM UTF-8,
  enquanto outros 21 arquivos (`.ps1` e `.md`) têm. Sob Windows PowerShell 5.1 com code page
  ANSI padrão (cp1252), os arquivos sem BOM são lidos incorretamente e toda mensagem acentuada
  vira mojibake.
  - _Situação atual:_ funciona na máquina de origem apenas porque o code page ANSI dela está
    em UTF-8 (65001, modo beta do Windows 11). Quebra em qualquer máquina com o padrão.
  - _Observação:_ o cabeçalho da biblioteca (versão 12) já declara "encoding UTF-8 com BOM",
    promessa que 28 arquivos não cumprem.
  - _Alvo:_ padronizar todos em UTF-8 com BOM e adicionar `.gitattributes` para fixar a regra.

### `Exit` sem código de retorno em 22 pontos

- **[CORREÇÃO]** `Exit` sem argumento retorna **0 (sucesso)**, inclusive em caminhos de erro
  (ex.: `exchangeOnline/listarCaixasPostais.ps1:52`, falha ao conectar). Como vários scripts
  rodam a partir de `C:\ScriptsRotinas\` como rotinas agendadas, o Agendador de Tarefas registra
  sucesso em execuções que falharam.
  - _Alvo:_ `Exit 1` em todo caminho de falha; padronizar os códigos de saída.

### Ausência de tratamento de throttling (HTTP 429)

- **[MELHORIA]** Nenhuma chamada ao Graph ou ao Exchange Online trata 429. Em
  `listarCaixasPostais.ps1:119` são 3.000+ chamadas sequenciais de `Get-EXOMailboxStatistics`;
  um 429 no meio apenas gera log de erro e a caixa fica sem dado, sem nova tentativa.
  - _Alvo:_ função `invocaComRetentativa` na biblioteca, com backoff exponencial e respeito ao
    header `Retry-After`, aplicável a todo o repositório.

### `verificaModulo` bloqueia execução desatendida

- **[CORREÇÃO]** `bibliotecaDeFuncoes.ps1` usa `Read-Host` para perguntar se deve instalar o
  módulo ausente — o que trava indefinidamente em execução agendada, justamente o cenário das
  rotinas. Após instalar, faz `Exit` com código 0.
  - _Alvo:_ parâmetro `-interativo` com padrão `$false`; em modo não interativo, registrar erro
    e sair com código diferente de zero.

### Guarda de nulo inconsistente em `listarCaixasPostais.ps1`

- **[CORREÇÃO]** Linha 253 chama `$detalheCredencial.createdDateTime.ToString(...)` sem verificar
  nulo, enquanto as três linhas seguintes (`lastPasswordChangeDateTime`, `onPremisesLastSyncDateTime`)
  verificam. Uma caixa sem objeto Graph correspondente lança exceção.

### `$buffer += ` dentro de laço (O(n²))

- **[MELHORIA]** `entraId/listarMembrosListas.ps1` acumula linhas com `$buffer += "..."` sobre um
  array, realocando a coleção inteira a cada iteração. `listarCaixasPostais.ps1` já usa
  `System.Collections.Generic.List[string]` corretamente — replicar o padrão.

### Ausência de `#Requires`

- **[MELHORIA]** Nenhum script declara `#Requires` — nem versão de PowerShell, nem módulo, nem
  `-RunAsAdministrator`. É a forma nativa e barata de falhar cedo com mensagem clara, em vez de
  falhar no meio da execução.

### `SkuDataComplete.csv` documentado mas não utilizado

- **[DECISÃO]** O `README.md:118` descreve o arquivo como "utilizada internamente para obter as
  descrições de licenciamento", mas **nenhum script o referencia**. Enquanto isso,
  `obterDescricaoLicenca` é um `switch` hardcoded com 22 entradas, que exige editar a biblioteca a
  cada nova licença.
  - _Opção A (preferida):_ carregar o CSV em `obterDescricaoLicenca` e eliminar o `switch`.
  - _Opção B:_ remover o arquivo e corrigir o `README.md`.

### Caminhos de saída fixos

- **[MELHORIA]** Os caminhos de log e CSV estão fixos em
  `$env:ONEDRIVE\Documentos\WindowsPowerShell\` (e `C:\ScriptsRotinas\...` em alguns scripts do AD).
  Expor como parâmetro `-caminhoSaida`, mantendo o valor atual como padrão.

---

## P3 — Higiene e Padronização

### Nomes de variáveis em inglês

- **[CORREÇÃO]** A regra de idioma exige pt-BR no código-fonte, mas há uso disseminado de
  `$buffer` (19x), `$name`, `$color`, `$stat`, `$path`, `$out`, `$user`, `$group`, `$result`.
  - _Sugestão:_ tratar por script, junto de outra alteração no mesmo arquivo, para não gerar
    um commit de renomeação em massa.

### Ausência de lint e CI

- **[NOVO]** O PSScriptAnalyzer não está instalado e não há nenhuma verificação automatizada.
  - _Alvo:_ workflow no GitHub Actions rodando `Invoke-ScriptAnalyzer` em todos os `.ps1`, mais
    validação de sintaxe via `[System.Management.Automation.Language.Parser]::ParseFile`.
  - _Avaliar:_ hook de pre-commit para o mesmo conjunto de regras.

### Mistura de `Write-Host` e `gravaLOG`

- **[CORREÇÃO]** `entraId/apagarListasSemMembros.ps1` (linhas 29, 36, 40, 46) usa `Write-Host`
  para mensagens que deveriam ir ao arquivo de log via `gravaLOG`. Mensagens de erro de conexão
  não ficam registradas.

### `Write-Progress` sem `-Completed`

- **[CORREÇÃO]** `entraId/apagarListasSemMembros.ps1:108` encerra com `-PercentComplete 100`
  em vez de `-Completed`, deixando a barra de progresso na tela.

### Compartilhar as configurações do editor

- **[DECISÃO]** O `.gitignore` ignora `.vscode/` por completo, então o `settings.json` que
  padroniza a formatação PowerShell do projeto (tabSize 2, preset OTBS) não é compartilhado.
  - _Sugestão:_ versionar `.vscode/settings.json` e `.vscode/extensions.json`, mantendo o
    restante da pasta ignorado.

### Regra de `.gitignore` frágil para o CSV de referência

- **[MELHORIA]** O `.gitignore` ignora `*.csv`, e `SkuDataComplete.csv` só está versionado por
  ter sido adicionado à força. Trocar por uma exceção explícita (`!SkuDataComplete.csv`) enquanto
  o arquivo existir. Depende da decisão do item de `SkuDataComplete.csv` acima.

---

## Melhorias Futuras — listarCaixasPostais.ps1

- **[MELHORIA]** Substituir `Add-Content` + buffer de 500 linhas por `System.IO.StreamWriter` na gravação do CSV. O StreamWriter mantém o arquivo aberto durante todo o loop, elimina a alocação periódica de `List[string]` e reduz chamadas ao sistema de arquivos de N/500 para uma única abertura. Compatível com PS5.
  - _Origem: implementation_plan.md — decisão adiada em 02/07/26 (menor impacto relativo; aguarda validação das otimizações da v27)_
  - _Atenção:_ conflita com o item "Geração de CSV sem escape" (P2). Decidir os dois em conjunto —
    `Export-Csv` resolve a corretude, mas abre mão do controle de buffer.

- **[MELHORIA]** Avaliar paralelismo com `ForEach-Object -Parallel` (PowerShell 7+) para a etapa de `Get-EXOMailboxStatistics`, que permanece sendo chamada individualmente por caixa (~3.000+ chamadas). Esta é a maior oportunidade de ganho de performance restante. Requer PS7+ e análise de limites de throttling do Exchange Online.
  - _Origem: implementation_plan.md — decisão adiada em 02/07/26 (restrição de compatibilidade PS5)_
  - _Relacionado:_ item de throttling (P2) — o tratamento de 429 é pré-requisito para paralelizar.

## Novo Script — listarUsuariosEntraId.ps1

- **[NOVO]** Criar a especificação (SDD) para um script que listará os usuários do Entra ID.
  - _Situação:_ Aguardando início (fase de levantamento de requisitos e criação do `spec.md`).
