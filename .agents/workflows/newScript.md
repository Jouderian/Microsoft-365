---
description: Como criar um novo script PowerShell neste repositório
---

# Workflow: Criar Novo Script PowerShell

Siga os passos abaixo sempre que for criar um novo script `.ps1` neste repositório.

## Passo 1 — Verificar o Backlog

Antes de qualquer coisa, consulte o `.agents/todo.md` para:
- Verificar se o script já está listado (Pendente).
- Entender decisões de design já documentadas na wiki.
- Ao concluir a tarefa, remover a menção do pendente e registrar a nova ação em `.agents/todoDone.md`.

## Passo 2 — Nomear o arquivo

- Use **camelCase** para nomear o arquivo. Ex.: `exportarRelatorioAcessos.ps1`
- O nome deve descrever claramente a ação executada.
- **Nunca** crie versões do mesmo arquivo com sufixos como `v2`, `old`, `novo`, `NOVO`. Edite o arquivo original no mesmo lugar.

## Passo 3 — Criar o cabeçalho padrão

Todo script deve começar com o bloco de **Comment-Based Help** no seguinte formato:

```powershell
<#
  .SYNOPSIS
    [Uma linha descrevendo o que o script faz]
  .DESCRIPTION
    [Descrição mais detalhada do funcionamento, módulos utilizados e contexto de uso]
  .AUTHOR
    [Nome do Autor]
  .CREATED
    [dd/mm/aa] (apenas se diferente do autor atual)
  .VERSION
    02 (dd/mm/aa) - [Descrição do que mudou]
  .OUTPUT
    [Onde o resultado é gravado: arquivo CSV, console, log etc.]
#>
```

## Passo 4 — Importar a biblioteca de funções

Se o script precisar de conexão, logs ou validação de módulos, importe a biblioteca:

```powershell
. "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"
```

## Passo 5 — Padrão de conexão e log

Use sempre as funções da biblioteca:

```powershell
$inicio = Get-Date
$logs = "$($env:ONEDRIVE)\Documentos\WindowsPowerShell\nomeDoScript_$($inicio.ToString('MMMyy')).txt"

gravaLOG "$("=" * 62) $($inicio.ToString('dd/MM/yy HH:mm:ss'))" -tipo WRN -arquivo $logs

VerificaModulo -NomeModulo "ExchangeOnlineManagement" -MensagemErro "..." -arquivoLogs $logs

try {
  Connect-ExchangeOnline -ShowBanner:$false
  gravaLOG "Conectado ao Exchange Online" -tipo OK -arquivo $logs
} catch {
  gravaLOG "Erro ao conectar: $($_.Exception.Message)" -tipo ERR -arquivo $logs
  Exit
}
```

## Passo 6 — Padrão de estrutura do código

- Use **camelCase** para todas as variáveis
- Use `try { } catch { }` em chamadas a serviços externos
- Use `Write-Progress` em loops com mais de 50 itens
- **Não** armazene credenciais, tokens ou senhas em hardcode

## Passo 7 — Criar a Documentação e Atualizar o `readMe.md`

Todo script deve ter seu arquivo correspondente na pasta `docs/` ou `docs/activeDirectory/`.
1. Crie o arquivo `.md` usando o bloco de detalhes extraído do cabeçalho.
2. Atualize a tabela pertinente no arquivo `readMe.md` na raiz do repositório, mapeando o script para sua nova documentação. O formato do link deve ser: ``[`nomeDoScript.ps1`](docs/nomeDoScript.md)``.

## Passo 8 — Atualizar o Ciclo de Vida

Registre o trabalho concluído de forma atômica seguindo o `.agents/rules/general.md`. Mova a pendência documentada para o Histórico de Ações Concluídas.