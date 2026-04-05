# BEADS: Backlog, Executable, Actions, Decisions, State

Este documento atende à metodologia **Spec-Driven / Agent-Flywheel**, e governa as prioridades, a execução, histórico e decisões de design arquitetural dos agentes trabalhando neste repositório.

---

## 1. Backlog (Pendente)
Tarefas sob demanda, ideias de novas automações e melhorias pendentes:
- [ ] Catalogar detalhadamente o *Synopsis* de cada script `.ps1` existente no repositório.
- [ ] Adicionar um controle padrão de logs de transcrição ou erro em scripts de grande impacto.
- [ ] Otimizar os loops e comandos do conjunto `listarCaixasPostaisNOVO.ps1` e `validaGPOs.ps1` usando as melhores práticas limpas de PowerShell.

---

## 2. Executable (Ambiente e Execução)
*   **Repositório Base:** `c:\Users\jouderian.nobre\OneDrive - Elfa Medicamentos Ltda\Documentos\WindowsPowerShell\Scripts\PUBLICO\Microsoft-365`
*   **Modelos de Execução:** Os scripts dependem do módulo Microsoft 365, Teams (ExchangeOnlineManagement, MicrosoftTeams) e ActiveDirectory em Windows PowerShell 5.1/7+.
*   **Agentes:** Consultam primeiro as normas em `.agents/rules.md`.

---

## 3. Actions (Ações Recentes)
- **YYYY-MM-DD**: [Configuração] Repositório inicializado com o modelo Flywheel / BEADS (Sistema Antigravity).

---

## 4. Decisions (Decisões de Design/Arquitetura)
*   **Design Principal:** *Clean Code* nos scripts `.ps1`.
*   **Convenção de Código:** Variáveis e nomes internos devem usar Notação Camelo (`camelCase`).
*   **Manutenção de Arquivos:** Abordagem de evitar múltiplos roteiros versionados (`v1`, `v2`, `old`); modificações devem ocorrer no "arquivo matriz" ou criar *branches* adequadas.

---

## 5. State (Estado do Sistema)
**Verde (Estável):** O projeto está implementando a governança com agentes. Os scripts atuais permanecem acessíveis e intocados em paralelo à inclusão da documentação administrativa do BEADS.
