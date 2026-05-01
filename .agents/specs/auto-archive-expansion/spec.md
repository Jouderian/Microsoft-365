---
description: Especificação para expansão do escopo de autoarquivamento para incluir caixas compartilhadas.
---

# Especificação: Expansão do Escopo de Autoarquivamento

## Objetivo
Ajustar o script `ativarAutoArquivamento.ps1` para que ele identifique e ative o arquivamento em todas as caixas postais compatíveis (Usuário e Compartilhada), garantindo que a verificação de status seja precisa.

## Atores
- Administradores de TI que executam o script para manutenção preventiva de storage no Microsoft 365.

## Requisitos
1. **Abrangência**: O script deve buscar tanto `UserMailbox` quanto `SharedMailbox`.
2. **Filtragem**: Ignorar caixas postais onde a conta do usuário está desabilitada (bloqueada).
3. **Precisão na Detecção**: Substituir a verificação de `ArchiveStatus` por `ArchiveGuid` para determinar se o arquivamento está realmente habilitado.
4. **Auto-Expansão**: Manter a ativação do `AutoExpandingArchive` para as caixas onde o arquivamento foi habilitado ou já existe.
4. **Logs**: Manter o padrão de logging existente, registrando o progresso e o tipo de caixa processada.
5. **Documentação**: Atualizar o arquivo de ajuda e o histórico de versões.

## Critérios de Aceitação
- O filtro de busca do `Get-Mailbox` deve retornar caixas de usuário e compartilhadas.
- O script não deve tentar ativar o arquivamento em caixas que já o possuem (verificado via `ArchiveGuid`).
- O resumo final deve mostrar o total de caixas processadas, ativadas e com erro.
