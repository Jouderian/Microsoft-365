# listarCaixasCompartilhadas.ps1

> **Sinopse**: Lista caixas compartilhadas e caixas com delegações de acesso no Exchange Online

## Descrição
O script se conecta ao Exchange Online, busca todas as caixas postais e filtra apenas os registros do tipo SharedMailbox ou UserMailbox que possuam membros com permissão explícita de acesso. Inclui caixas compartilhadas sem membros para fins de auditoria.

## Detalhes
- **Autor**: Jouderian Nobre
- **Versão Atual**: 06 (05/04/26) - Atualizacao da documentacao
- **Saída**: Arquivo CSV com a relacao de caixas compartilhadas e seus membros.

## Módulos / Dependências
- ExchangeOnlineManagement
