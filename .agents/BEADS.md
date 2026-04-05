# BEADS: Backlog, Executable, Actions, Decisions, State

Este documento atende à metodologia **Spec-Driven / Agent-Flywheel**, e governa as prioridades, a execução, histórico e decisões de design arquitetural dos agentes trabalhando neste repositório.

---

## 1. Backlog (Pendente)
Tarefas sob demanda, ideias de novas automações e melhorias pendentes:
- [x] Catalogar detalhadamente o *Synopsis* de cada script `.ps1` existente no repositório.
- [x] Padronizar cabeçalhos `<# .SYNOPSIS #>` em todos os scripts da raiz e pasta `activeDirectory`.
- [x] Documentar todos os scripts no `readMe.md` (raiz e pasta `activeDirectory`).
- [x] Criar workflow `.agents/workflows/novoScript.md` com padrões de desenvolvimento.
- [ ] Adicionar um controle padrão de logs de transcrição ou erro em scripts de grande impacto.
- [ ] Otimizar os loops e comandos do conjunto `listarCaixasPostaisNOVO.ps1` e `validaGPOs.ps1` usando as melhores práticas limpas de PowerShell.

---

## 2. Executable (Ambiente e Execução)
*   **Modelos de Execução:** Os scripts dependem do módulo Microsoft 365, Teams (ExchangeOnlineManagement, MicrosoftTeams) e ActiveDirectory em Windows PowerShell 5.1/7+.
*   **Agentes:** Consultam primeiro as normas em `.agents/rules.md`.
*   **Workflow:** Para criar um novo script, siga `.agents/workflows/novoScript.md`.

---

## 3. Actions (Ações Recentes)
- **2026-04-05**: [Configuração] Repositório inicializado com o modelo Flywheel / BEADS (Sistema Antigravity).
- **2026-04-05**: [Documentação] Criação do `readMe.md` com resumo de todos os 40 scripts (raiz + `activeDirectory`).
- **2026-04-05**: [Padronização] Todos os cabeçalhos dos scripts padronizados para o formato `<# .SYNOPSIS #>`.
- **2026-04-05**: [Workflow] Criado `.agents/workflows/novoScript.md` com o padrão oficial de desenvolvimento.

---

## 4. Decisions (Decisões de Design/Arquitetura)
*   **Design Principal:** *Clean Code* nos scripts `.ps1`.
*   **Convenção de Código:** Variáveis e nomes internos devem usar Notação Camelo (`camelCase`).
*   **Manutenção de Arquivos:** Abordagem de evitar múltiplos roteiros versionados (`v1`, `v2`, `old`); modificações devem ocorrer no "arquivo matriz" ou criar *branches* adequadas.
*   **Cabeçalho Padrão:** Todo script deve usar o bloco `<# .SYNOPSIS ... #>` conforme definido em `.agents/workflows/novoScript.md`.
*   **Alias PowerShell:** Proibido uso de aliases como `%` e `?`; usar sempre o cmdlet completo (`ForEach-Object`, `Where-Object`).

---

## 5. State (Estado do Sistema)
**Verde (Estável):** Repositório totalmente documentado. Todos os scripts possuem cabeçalho padronizado, o `readMe.md` cobre a raiz e a pasta `activeDirectory`, e o workflow de criação de novos scripts está disponível em `.agents/workflows/novoScript.md`.
