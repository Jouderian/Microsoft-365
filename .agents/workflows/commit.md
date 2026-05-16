---
description: Procedimento para criar commits seguindo as convenções do projeto. Usar quando quiser fazer commit das alterações staged no repositório. Gera mensagem de commit em Conventional Commits, Português-BR, com escopo obrigatório, e apresenta para aprovação
---

# Padrão de Commits

Sempre garanta que seu commit possua rastreabilidade para uma especificação e descreva **o quê** foi feito, não *como*.

- **Idioma**: Português do Brasil (pt-BR).
- **Semântica (Opcional, mas Recomendada)**: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`.
- **Corpo do Commit**: Explique brevemente o ganho de negócio ou estabilidade daquele script. Nunca commita credenciais.

## Passos

### 1. Atualizar wiki (se aplicável)

Avaliar se a sessão produziu conhecimento relevante, conforme critérios de `.agents/rules/wiki-maintenance.md`:
- Decisões arquiteturais ou trade-offs
- Correções de bugs não-triviais
- Novos padrões, convenções ou refatorações
- Mudanças em specs, APIs, schema Drizzle ou contratos públicos

Se aplicável:
1. Ler `.agents/wiki/index.md` para identificar páginas existentes
2. Atualizar as páginas afetadas ou criar novas
3. Atualizar o `index.md` se novas páginas foram criadas
4. As mudanças no wiki serão incluídas no stage junto com o código

Se a sessão foi puramente cosmética (formatação, typos) ou não produziu conhecimento novo, pular este passo.

---

### 2. Analisar as alterações staged

// turbo
```bash
git diff --cached
```

**Escopo de contexto:** basear a análise **exclusivamente** no diff staged acima.
Não considerar outras alterações da sessão que já foram commitadas — cada commit
deve ser autocontido e descrever apenas o que está sendo commitado agora.

Analisar o conteúdo do diff para identificar:
- Qual(is) área(s) do projeto foi(ram) alterada(s)
- Qual o tipo da alteração (feat, fix, refactor, docs, chore, test, style, perf, spec)
- Se há breaking changes

---

### 3. Gerar a mensagem de commit

Gerar a mensagem seguindo **todas** as regras abaixo:

**Formato Conventional Commits:**
```
<tipo>(<escopo>): <descrição imperativa em pt-BR>

[corpo opcional — explicação do "por quê", não do "o quê"]

[footer opcional — BREAKING CHANGE:, Refs:, etc.]
```

**Regras obrigatórias:**

| Regra | Detalhe |
|-------|---------|
| Idioma | **Português-BR** (descrição, corpo e footer) |
| Escopo | **Obrigatório** — um dos escopos válidos (ver abaixo) |
| Descrição | Imperativa, minúscula, sem ponto final, máximo 72 caracteres |
| Corpo | Explicar o "por quê" quando não for óbvio. Separado por linha em branco |
| Breaking change | Usar `!` após o escopo (ex: `feat(backend)!:`) E adicionar `BREAKING CHANGE:` no footer |

**Tipos válidos:**

| Tipo | Quando usar |
|---|---|
| `feat` | Nova funcionalidade |
| `fix` | Correção de bug |
| `refactor` | Mudança de código que não adiciona feature nem corrige bug |
| `docs` | Alterações de documentação |
| `test` | Adição ou correção de testes |
| `chore` | Manutenção (dependências, configs, scripts) |
| `spec` | Alterações em artefatos SDD (specs, plans, tasks) |
| `style` | Formatação (sem mudança de lógica) |
| `perf` | Melhoria de desempenho |

---

### 4. Apresentar para aprovação

> **Modo direto:** pular este passo inteiramente — aceitar a mensagem gerada e ir para o passo 6.

**Modo padrão:**

Apresentar a mensagem gerada ao usuário no seguinte formato:

```
Branch de trabalho: <nome-da-branch>
Mensagem de commit sugerida:

  <tipo>(<escopo>): <descrição>

  <corpo opcional>

Deseja ajustar algo antes de confirmar?
```

Aguardar a aprovação ou ajuste do usuário. **NÃO executar o commit sem aprovação explícita.**

---

### 5. Executar o commit

Após aprovação, executar:

```bash
git commit -m "<mensagem aprovada>"
```

Se houver corpo ou footer, usar a forma multi-linha:

```bash
git commit -m "<primeira linha>" -m "<corpo>" -m "<footer>"
```

---

### 6. Confirmar sucesso do commit

// turbo
```bash
git log -1 --oneline
```

Informar o hash e a mensagem do commit criado.

---

## Exemplos

**Feature simples:**
```
Branch: feat/formulario-participante
Commit: feat(frontend): adicionar formulário de cadastro de participante
```

**Fix com corpo explicativo:**
```
fix(backend): corrigir validação de email duplicado no registro

O handler de cadastro não verificava unicidade do email antes de
chamar o serviço de criação. Agora uma consulta ao Drizzle é feita
antes da inserção, retornando 409 se já existir.
```

**Breaking change:**
```
refactor(backend)!: reestruturar rotas de API para versionamento

BREAKING CHANGE: todas as rotas movidas de /api/* para /api/v1/*.
Clientes existentes precisam atualizar a base URL.
```
