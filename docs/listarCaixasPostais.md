# listarCaixasPostais.ps1

> **Sinopse**: Extrai uma listagem com as principais caracteristica de todas as caixas postais do Exchange (Microsoft 365).

## Descrição
O script se conecta ao ambiente do Microsoft 365, busca todas as caixas postais existentes e extrai uma série de informações sobre cada caixa postal, como nome, UPN, cidade, empresa, tipo, tamanho utilizado, entre outros. As informações são gravadas em um arquivo CSV para análise posterior.

## Detalhes
- **Autor**: Fernando Olimpio
- **Versão Atual**: 24 (05/04/26) Jouderian Nobre - Atualizacao da documentacao
- **Saída**: Arquivo .csv com:
  - nome
  - UPN
  - cidade
  - empresa
  - departamento
  - cargo
  - tipo
  - tamanho utilizado
  - licenças atribuídas
  - entre outros

## Módulos / Dependências
- ExchangeOnlineManagement
- Microsoft.Graph
