---
description: Lista de tarefas para a implementação da expansão do autoarquivamento.
---

# Tarefas: Expansão do Autoarquivamento

- [x] Preparação
    - [x] Revisar código atual e garantir que as bibliotecas estão acessíveis.
- [x] Implementação do Script (`ativarAutoArquivamento.ps1`)
    - [x] Atualizar cabeçalho de versão (v05).
    - [x] Modificar o filtro do `Get-Mailbox` para incluir `SharedMailbox`.
    - [x] Ajustar a lógica de verificação de status (usar `ArchiveGuid`).
    - [x] Refinar as mensagens de log para clareza.
- [x] Documentação
    - [x] Atualizar `docs/ativarAutoArquivamento.md` com as novas capacidades.
- [x] Conclusão
    - [x] Atualizar `todo.md` e `todoDone.md`.
