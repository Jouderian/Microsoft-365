---
trigger: always_on
description: Protocolo de manutenção do backlog — mover pendência sanada de todo.md para todoDone.md no mesmo commit da correção
---

# Manutenção do Backlog

> `.agents/todo.md` contém **apenas** pendências. `.agents/todoDone.md` é o histórico append-only de itens concluídos. Um item nunca existe nos dois arquivos.

---

## Gatilho

Sempre que uma pendência de `.agents/todo.md` for sanada, mover o item **no mesmo commit da correção**. Considera-se sanada quando:

- **[CORREÇÃO]**, **[MELHORIA]**, **[REFATORAÇÃO]**, **[NOVO]**: a alteração de código ou documentação que o item pede está aplicada e verificada.
- **[DECISÃO]**: a decisão foi tomada pelo usuário **e** a consequência dela está aplicada. Decisão tomada sem aplicação permanece pendente, com a escolha registrada no próprio item.

Item parcialmente sanado **não** é movido: reescreva o item para refletir apenas o que resta e registre o que já foi feito.

## Procedimento

1. **Remover** o bloco inteiro do item de `.agents/todo.md` — cabeçalho `###` e corpo. Se o item era o último da seção, remover a seção também.
2. **Acrescentar** uma linha ao fim de `.agents/todoDone.md`, no formato existente:
   ```
   - **[x]** AAAA-MM-DD: [Categoria] Descrição do que foi feito, no passado.
   ```
   - A data é a da conclusão, nunca relativa ("hoje", "ontem").
   - Categorias válidas: `Configuração`, `Documentação`, `Padronização`, `Workflow`, `Feature`, `Refactoring`, `Governança`, `Correção`.
   - Uma linha por item, citando os arquivos afetados entre crases quando ajudar a rastrear.
3. **Nunca** marcar `**[x]**` dentro de `todo.md` como forma de conclusão: o marcador só existe em `todoDone.md`.
4. **Nunca** remover, reordenar ou reescrever linhas já existentes em `todoDone.md` — o arquivo é append-only.
5. **Reavaliar itens acoplados:** se o item concluído era pré-requisito ou conflitava com outro (`_Atenção:_`, `_Depende de:_`, `_Relacionado:_`), atualizar o item remanescente na mesma passagem.

## Verificação

Antes de qualquer commit que altere código ou documentação, rodar:

```bash
grep -n "\*\*\[x\]\*\*" .agents/todo.md
```

Saída vazia é a condição de conformidade. Qualquer linha retornada é um item concluído que ficou no arquivo errado.
