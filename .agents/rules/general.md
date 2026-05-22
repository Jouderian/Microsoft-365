---
trigger: always_on
---

---
description: Regras gerais do projeto — idioma, formato de documentos, git, SDD, dependências e segurança
---

# Regras Gerais

> Regras aplicáveis a todo o código e todos os agentes do projeto.

---

## Idioma

- **Documentação** (specs, plans, tasks, ADRs, README, wiki): **Português do Brasil (pt-BR)**.
- **Código-fonte** (classes, métodos, propriedades, variáveis, constantes):  **Português do Brasil (pt-BR)**.
- **Comentários no código**: **Português do Brasil (pt-BR)**.
- **Nomes de arquivos**: **Português do Brasil (pt-BR)**, sempre em `camelCase` (ex: `registroUsuario.ps1`, `autoServico.ps1`).
- **Nomes de diretórios**: **Português do Brasil (pt-BR)**, em `camelCase` (ex: `configuraLista/`, `cicloDeVidaCredenciail/`).
- **Nomes de arquivos e diretorios de configurações** (./agents): **Inglês**, em `kebab-case` (ex: `.agents/specs/revogar-credenciail-ad/`).
- **Mensagens de commit**: **Português do Brasil (pt-BR)**.

## Formato de Documentos

- Todo arquivo Markdown dentro de `.agents/` **deve** começar com YAML frontmatter contendo pelo menos o campo `description`.
- O `description` deve ser um resumo curto e objetivo do conteúdo do arquivo (uma linha).
- Isso permite que agentes identifiquem rapidamente a relevância do arquivo sem ler todo o conteúdo.

```yaml
---
description: Resumo curto do conteúdo do arquivo
---
```

## Convenções de Git

- **Mensagens de commit** seguem [Conventional Commits](https://www.conventionalcommits.org/):
  `type(scope): descrição`
- **Escopo é obrigatório.** Não usar commits sem escopo.
- Tipos comuns: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `spec`.
- Use o tipo `spec` para alterações em artefatos SDD (ex: `spec(auth): define fluxo de login`).

## Qualidade de Código

- Para regras detalhadas de padrões de código (princípios de design, logging e nomenclatura), consulte `.agents/rules/code-standards.md`.

## Spec-Driven Development

- Para regras detalhadas do processo SDD (integração com planning mode, protocolo spec-change-first, detecção de drift), consulte `.agents/rules/sdd.md`.

## Dependências

- Sempre pergunte ao usuário antes de adicionar uma nova dependência.
- Prefira bibliotecas bem mantidas com comunidades ativas.
- Fixe versões exatas nos lockfiles.

## Segurança

- Nunca faça hardcode de segredos, tokens, chaves de API ou senhas.
- Use variáveis de ambiente ou ferramentas de gerenciamento de segredos.
- Sanitize toda entrada de usuário.

## Governança de Regras do Agente

Toda solicitação de **inclusão ou alteração de regras** do agente DEVE considerar o contexto de **SDD dentro do Google Antigravity**:

- **Local:** regras vivem exclusivamente em `.agents/rules/` como arquivos Markdown (`.md`). Não usar `.agrules`, `.cursorrules`, `GEMINI.md` na raiz ou qualquer outro formato proprietário.
- **Formato:** o Antigravity usa o campo `description` do frontmatter para decidir o carregamento contextual de regras — escreva descrições que indiquem claramente quando a regra se aplica.
- **Modularidade:** regras devem ser organizadas por escopo (ex: protocolo SDD, restrições de arquitetura, padrões de código, tooling). Não consolidar tudo em um único arquivo.
- **Verificabilidade SDD:** toda regra nova deve ser binária e verificável — se não for possível validar o cumprimento em uma revisão rápida de código, a regra é vaga demais.
- **Consistência com specs:** regras não devem duplicar informação já presente nas specs em `.agents/specs/`. Se a informação pertence à especificação do sistema, ela vai na spec; se é uma diretriz operacional para o agente, vai na regra.