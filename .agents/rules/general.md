---
trigger: always_on
---

---
trigger: always_on
---

# Regras Gerais

> Regras aplicáveis a todo o código e todos os agentes do projeto.

---

## Regras Inegociáveis

1.  **Idioma:** Entregar sempre as respostas e documentações em português do Brasil.
2.  **Autorização prévia:** Solicite autorização expressa ao usuário antes de realizar alterações no código (`.ps1`) ou nos arquivos sensíveis de configuração.
3.  **Segurança e Credenciais:** Absolutamente proibido o armazenamento de chaves de acesso, tokens ou senhas em *hardcode*. Variáveis de ambiente ou parâmetros interativos devem ser preferidos.
4.  **Gerenciamento de Versão (GIT/File System):** Evite comandos destrutivos. `git reset --hard`, `git clean -fd`, `rm -rf` são **PROIBIDOS**.
5.  **Preservação de Histórico de Arquivos:** Não crie múltiplos arquivos semelhantes ou renomeados (como `.old`, `.new`, `v2`, etc.). Edite o arquivo alvo original quando solicitado (após autorização).
6.  **Consciência Multiagente:** Respeite as edições de outros agentes. Nunca sobrescreva ou reverta alterações sem consultar o plano arquitetural.
7.  **Sincronia do Ciclo SDD:** Após a conclusão de qualquer nova feature, mova as tarefas pendentes do `todo.md` para o `todoDone.md`. Toda alteração deve convergir com a fonte de verdade em `systemArchitecture/plan.md`.
8.  **Documentação de Scripts:** Sempre que realizarmos mudança em um script que gera mudança no funcionamento dele, atualize toda a documentação do script no projeto.

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
- **Escopos válidos:** `frontend`, `backend`, `db`, `infra`, `docs`, `root`.
  Novos escopos podem ser adicionados conforme o projeto evoluir.
- **Autorização para Push:** É **obrigatório** solicitar a autorização expressa do usuário antes de realizar qualquer envio para o repositório remoto (`git push`).
- **Pré-requisito do Commit/Push:** Antes de solicitar a autorização para atualizar o repositório, você deve apresentar claramente ao usuário:
  1. A lista exata dos arquivos que foram modificados e estão sendo incluídos na atualização.
  2. A exata mensagem de *commit* que será utilizada.