---
description: Procedimento para atualizar o repositório remoto, incluindo regeneração automática dos documentos finais (.docx e .pdf) quando o Markdown fonte tiver sido modificado.
---

# Workflow: Atualizar Repositório Remoto

Este workflow define o procedimento obrigatório para sincronizar o repositório local com o remoto (GitHub). Antes do push, o agente **deve** verificar se o arquivo `regulamentoCompeticoesCearenses.md` foi alterado e, em caso afirmativo, regenerar os documentos finais.

## 1. Apresentar Alterações ao Usuário

Antes de solicitar autorização para o push, **apresente claramente** ao usuário:

1. A **lista exata** dos arquivos modificados que serão incluídos no commit.
2. A **mensagem de commit** proposta (seguindo Conventional Commits com escopo obrigatório).

```powershell
# // turbo
git status --short
```

## 2. Solicitar Autorização e Executar

Após a aprovação explícita do usuário:

```powershell
git add -A
git commit -m "<mensagem aprovada>"
git push origin main
```

> [!CAUTION]
> **Nunca** execute `git push` sem a autorização expressa do usuário. Esta é uma regra inegociável definida em `.agents/rules/general.md`.

## Checklist Rápido

- [ ] Apresentar arquivos modificados e mensagem de commit ao usuário
- [ ] Obter autorização expressa do usuário
- [ ] Executar `git add`, `git commit` e `git push`