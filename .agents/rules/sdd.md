---
trigger: always_on
---

---
description: Regras do processo SDD — integração com planning mode, protocolo spec-change-first e detecção de drift
---

## Integração SDD com o Planning Mode

O fluxo SDD se integra ao planning mode nativo do agente da seguinte forma:

### Fase de Research (Pesquisa)

- Ler as specs relevantes em `.agents/specs/` usando o campo `description` do frontmatter para filtrar.
- Consultar ADRs em `.agents/adrs/` — especialmente a seção "Alternativas Rejeitadas" — para **não propor soluções já descartadas**.
- Consultar `.agents/todo.md` para verificar se já existe trabalho planejado ou em andamento para o mesmo escopo.
- Specs e ADRs do projeto **têm prioridade sobre Knowledge Items** de conversas anteriores — são versionadas com o código; KIs podem estar desatualizados.

### Fase de Plan (implementation_plan.md)

- O `implementation_plan.md` DEVE referenciar as seções de spec que fundamentam cada decisão técnica (ex: "Conforme `spec.md § Critérios de Aceitação`").
- Se a alteração planejada contradiz uma spec existente, incluir a atualização da spec como item do plano **antes** da implementação de código.
- Se uma decisão arquitetural significativa for tomada durante o planejamento, registrar uma ADR em `.agents/adrs/` seguindo o workflow `/register-adr`.

> [!IMPORTANT]
> **Registro proativo de ADR:** Sempre que uma decisão de stack, tecnologia, padrão de design ou arquitetura for tomada ou alterada — mesmo fora do
> planning mode (ex: durante conversas de setup, análise de stack, ou mudança de ferramenta) — o agente DEVE registrar a ADR imediatamente, sem
> esperar solicitação do usuário. Usar o workflow `/register-adr` para garantir formato e completude.

### Fase de Execute (task.md)

- O `task.md` do agente é o checklist da sessão de trabalho atual. É diferente do `.agents/todo.md`, que é o backlog persistente do projeto.
- Se novos gaps, débitos técnicos ou bugs forem identificados durante a execução, registrá-los no backlog (`.agents/todo.md`).
- Tarefas concluídas são arquivadas periodicamente em `.agents/todo-done.md` para manter o backlog limpo.

---

## Protocolo Spec-Change-First

- **NUNCA altere o comportamento do código de forma que contradiga uma spec existente** sem antes atualizar a spec correspondente.
- Se descobrir que uma spec está desatualizada em relação ao código já implementado, corrija a spec imediatamente.
- Ao criar novos módulos ou componentes, a spec DEVE existir antes da implementação.
- Toda spec nova DEVE seguir a estrutura existente: Markdown com listas de marcadores, tabelas, blocos de código e linguagem imperativa direta.

---

## Detecção de Drift

Ao iniciar uma tarefa, se perceber divergência entre código e spec:

1. Registre a divergência explicitamente no `implementation_plan.md`.
2. Proponha se a correção deve ser na spec ou no código.
3. Não prossiga com a implementação principal até a divergência ser resolvida.