# listaPastasCaixaPostal.ps1

> **Sinopse**: Lista as pastas de uma caixa postal e gera uma listagem

## Descrição
O script se conecta ao Exchange Online, solicita o endereço da caixa postal, coleta as estatísticas de todas as pastas (caixa principal, arquivo e recuperação) e gera uma listagem (arquivo .csv).

## Detalhes
- **Autor**: Fernando Olimpio
- **Versão Atual**: 03 (05/04/26) Jouderian Nobre - Atualizacao da documentacao
- **Saída**: Arquivo .csv com:
    - caminho
    - tamanho
    - quantidade de itens por pasta

## Módulos / Dependências
- ExchangeOnlineManagement
