# Microsoft-365

Automações PowerShell para administração de Microsoft 365, Entra ID e Active Directory.

## Regras do Agente

As regras do projeto vivem em `.agents/rules/` (convenção do Google Antigravity). Este arquivo as importa para que o Claude Code também as carregue.

- @.agents/rules/general.md — idioma, formato de documentos, git, dependências, segurança e governança de regras
- @.agents/rules/code-standards.md — princípios de design, logging, nomenclatura e padrões PowerShell
- @.agents/rules/sdd.md — processo Spec-Driven Development (planning mode, spec-change-first, drift)
- @.agents/rules/wiki-maintenance.md — manutenção da wiki e da documentação em `docs/`
- @.agents/rules/backlog-maintenance.md — mover pendencia sanada de todo.md para todoDone.md
- @.agents/rules/response-style.md — estilo das respostas no chat

Ao adicionar uma regra nova em `.agents/rules/`, inclua o import correspondente nesta lista.
