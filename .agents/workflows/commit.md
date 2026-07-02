---
description: Procedimento para criar commits conforme as convenções do projeto. Use ao commitar alterações staged. Gera mensagem de commit em Conventional Commits, Português-BR, com escopo obrigatório, e exibe para aprovação.
---

# Padrão de Commits

Sempre garanta que seu commit possua rastreabilidade para uma especificação e descreva **o quê** foi feito, não *como*.

- **Idioma**: Português do Brasil (pt-BR).
- **Semântica (Opcional, mas Recomendada)**: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`.
- **Corpo do Commit**: Explique brevemente o ganho de negócio ou estabilidade daquele script. Nunca commita credenciais.

## Passos

### 1. Atualizar documentação e wiki (se aplicável)

Antes de gerar o commit, avalie a necessidade de atualizar ou criar documentação relacionada às mudanças efetuadas:

1. **Documentação Integrada ao Código**: Se alterou ou criou scripts PowerShell (`.ps1`), certifique-se de que o cabeçalho de ajuda base do script (`<# .SYNOPSIS ... #>`) e os blocos de comentários de funções foram atualizados ou criados de acordo.
2. **Documentação do Repositório**: Avalie se a alteração afeta a arquitetura global ou o uso das ferramentas e requer atualizações no `README.md` ou na pasta `/docs`.
3. **Base de Conhecimento (Wiki)**: Avalie se a sessão produziu conhecimento técnico novo e relevante conforme `.agents/rules/wiki-maintenance.md`:
   - Decisões arquiteturais ou trade-offs (que demandam ADRs)
   - Gotchas e correções de bugs não-triviais de APIs ou sistemas externos
   - Novos padrões, convenções ou refatorações estruturais
   - Mudanças em specs ou contratos públicos

Se for aplicável atualizar a Wiki:
1. Consulte `.agents/wiki/index.md` para identificar páginas relevantes existentes.
2. Atualize as páginas afetadas ou registre uma nova ADR/artigo.
3. Se novas páginas foram criadas, registre-as no `index.md`.
4. Adicione as mudanças de documentação e wiki no stage (`git add`) para que façam parte do mesmo commit do código.

Se a sessão foi puramente cosmética (formatação, ajustes simples) ou não gerou necessidade de documentação nova, pular este passo.

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

### 7. Sincronizar com o remoto

Após confirmar o sucesso do commit, perguntar ao usuário se ele deseja enviar a atualização para o repositório remoto:

```
Deseja enviar (push) estas alterações para o repositório remoto agora?
```

Se o usuário aprovar, executar:

```bash
git push
```

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