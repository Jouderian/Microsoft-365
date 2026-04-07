# listarCaixasComEncaminhamento.ps1

> **Sinopse**: Extrai uma listagem com todas as caixas postais do Exchange (Microsoft 365).

## Descrição
O script se conecta ao ambiente do Microsoft 365, busca todas as caixas postais existentes e extrai uma série de informações sobre cada caixa postal, como nome, UPN, cidade, empresa, tipo, tamanho utilizado, entre outros. As informações são gravadas em um arquivo CSV para análise posterior.

## Detalhes
- **Autor**: Jouderian Nobre
- **Versão Atual**: 02 (05/04/26) Jouderian Nobre: Atualizacao da documentacao
- **Saída**: Arquivo CSV com a relacao de caixas postais

## Módulos / Dependências
- ExchangeOnlineManagement
