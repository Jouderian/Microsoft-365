# removerDispositivos.ps1

> **Sinopse**: Remove do EntraID os dispositivos sem uso a mais de 190 dias (licença maternidade)

## Descrição
O script se conecta ao ambiente do Microsoft 365, busca todos os dispositivos existentes e extrai uma série de informações sobre cada dispositivo, como nome, UPN, cidade, empresa, tipo, tamanho utilizado, entre outros. As informações são gravadas em um arquivo CSV para análise posterior.

## Detalhes
- **Autor**: Jouderian Nobre
- **Versão Atual**: 02 (05/04/26) - Atualizacao da documentacao
- **Saída**: N/A

## Módulos / Dependências
- Microsoft.Graph
