---
description: Plano técnico para implementação da expansão do autoarquivamento.
---

# Plano de Implementação: Expansão do Autoarquivamento

## Mudanças Técnicas

### 1. Filtro de Busca
Alterar o comando `Get-Mailbox` para incluir múltiplos tipos de destinatários e filtrar apenas contas ativas.
- **Antes**: `-Filter "RecipientTypeDetails -eq 'UserMailbox'"`
- **Depois**: `-Filter "(RecipientTypeDetails -eq 'UserMailbox' -or RecipientTypeDetails -eq 'SharedMailbox') -and AccountDisabled -eq '$false'"`

### 2. Lógica de Verificação
Usar `ArchiveGuid` para verificar a existência do arquivo.
- Se `ArchiveGuid` for igual a `00000000-0000-0000-0000-000000000000` (Guid vazio), o arquivo não está ativo.
- Verificar `AutoExpandingArchiveEnabled` como booleano.

### 3. Cabeçalho e Metadados
- Incrementar a versão para `05`.
- Atualizar a data de modificação.
- Refinar a descrição da versão no cabeçalho.

## Arquivos Afetados
- [MODIFY] `ativarAutoArquivamento.ps1`
- [MODIFY] `docs/ativarAutoArquivamento.md`

## Riscos e Mitigações
- **Throttling**: O Exchange Online pode limitar requisições em ambientes muito grandes.
- **Licenciamento**: Algumas caixas compartilhadas podem precisar de licença se excederem 50GB.
