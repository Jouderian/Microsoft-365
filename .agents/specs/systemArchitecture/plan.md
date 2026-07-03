---
description: Plano mestre de arquitetura para automações M365 e Active Directory
---

# Master Plan: Fonte de verdade técnica para Execução e Estado do Sistema.

## Visão Geral e Intento
Este projeto abriga uma gama de scripts em PowerShell que cuidam da governança de um ambiente de AD ou M365

## Objetivos Arquiteturais (Onde queremos chegar)
As intenções a longo prazo deste repositório usando a metodologia Agent Flywheel são:
1. **Segurança e Idempotência:** Garantir que todos os scripts possam falhar graciosamente, registrando o erro centralizadamente sem expor dados e que rodá-los várias vezes no mesmo estado traga o mesmo resultado (idempotência).
2. **Centralização por Referência Core:** Direcionar o peso do código repetitivos e conversão complexa para a bibliotecas core (`bibliotecaDeFuncoes.ps1` e equivalentes) e deixar os scripts de caso de uso apenas como executores orquestrados que chamam funções limpas com dependência única.

## Documentação do Fluxo Identificado

### 1. Executable (Ambiente e Execução)
1. **Modelos de Execução:** Os scripts dependem nativamente do Windows PowerShell 5.1/7+.
2. **Módulos Oficiais Utilizados:** 
   - `ExchangeOnlineManagement` (Gestão de caixas e mail flow)
   - `Microsoft.Graph.Authentication`, `Microsoft.Graph.Groups`, `Microsoft.Graph.Users` (Identidade cloud)
   - `ActiveDirectory` (Identidade on-premise)
   - `MicrosoftTeams` (Limpezas de cache/config)
3. **Padrão de Autenticação:** Autenticação Interativa (Delegated) como padrão para execução via administrador local.
4. **Padrão de Logging:** Utilização da função `gravaLOG` (via `bibliotecaDeFuncoes.ps1`) com saída centralizada e retenção em formato textual.
5. **Agentes:** Consultam primeiro as normas em `.agents/rules/general.md` e `.agents/rules/codeStandards.md`.
6. **Workflow:** Para criar um novo script, siga `.agents/workflows/newScript.md`.

### 2. Estrutura de Diretórios
- `/`: Biblioteca core de funções compartilhada (`bibliotecaDeFuncoes.ps1`), dados e arquivos do projeto.
- `/activeDirectory`: Scripts de AD DS on-premise local.
- `/exchangeOnline`: Scripts que gerenciam mailboxes, listas e fluxos no Exchange Online.
- `/entraId`: Scripts voltados para identidades, licenças, grupos do Entra ID e auditoria de tenant (via Graph).
- `/intune`: Scripts focados em gerenciamento e registros de dispositivos MDM (Intune).
- `/suporteUsuario`: Scripts client-side de manutenção e resolução de problemas no lado do usuário.
- `/docs`: Documentação dos scripts, replicando a mesma estrutura de diretórios do código.
- `/.agents`: Core de metadados, regras, workflows e especificações de agentes.

### Próximos Passos (Veja .agents/todo.md e tasks.md)
O rastreio do que deve ser tocado está catalogado em `.agents/todo.md` e guiado pela priorização matemática documentada ou delegada pelos agentes. Adicionalmente, as tarefas mais profundas de arquitetura constam em `tasks.md`.