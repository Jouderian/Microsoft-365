# listarCaixasComEncaminhamento.ps1

> **Sinopse**: Identifica caixas postais com regras de encaminhamento configuradas (ForwardingAddress ou DeliverToMailboxAndForward).

## Descrição
Este script se conecta ao Exchange Online, analisa as configurações das caixas postais e identifica aquelas que possuem encaminhamentos de e-mail ativos (seja para endereços internos ou externos), exportando o relatório para análise.

## Detalhes
- **Autor**: Jouderian Nobre
- **Versão Atual**: 02 (05/04/26) Jouderian Nobre: Atualizacao da documentacao
- **Saída**: Arquivo CSV com a relacao de caixas postais

## Módulos / Dependências
- ExchangeOnlineManagement
