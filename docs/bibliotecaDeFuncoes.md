# bibliotecaDeFuncoes.ps1

> **Sinopse**: Biblioteca de funções de uso geral para centralizar recursos nos demais scripts em PowerShell.

## Descrição
Script de utilidade em PowerShell que exporta diversas funções fundamentais utilizadas por praticamente todos os scripts do repositório, como a função de registro de logs (`gravaLOG`), validação de módulos (`VerificaModulo`), tratamento de strings (`removerAcentos`, `trataTexto`) e geração de senhas (`geraSenhaAleatoria`).

## Detalhes
- **Autor**: Jouderian Nobre
- **Versão Atual**: 14 (16/09/26) - Função `removeQuebraDeLinha` corrigida: passa a tratar CRLF, LF e CR isolado via expressão regular, no lugar das substituições inertes anteriores
- **Saída**: N/A

## Notas de Uso

### `geraSenhaAleatoria`
Gera senhas com `System.Security.Cryptography.RandomNumberGenerator` (não com `Get-Random`), usando amostragem por rejeição para evitar viés de módulo.

- O sorteio é **com reposição**: a senha sempre tem exatamente o `-tamanho` pedido, mesmo quando maior que o conjunto de caracteres.
- Com `-garanteComplexidade $true` (padrão), a senha recebe ao menos um caractere de cada classe presente em `-chars` (minúscula, maiúscula, dígito e símbolo), atendendo às políticas de senha do AD e do Entra ID.
- O conjunto padrão de `-chars` **não** inclui vírgula, ponto-e-vírgula nem aspas, para não corromper os arquivos CSV e de log gerados pelos scripts.
- `-tamanho` aceita valores entre **7 e 256** (padrão 16); fora dessa faixa a chamada falha na validação de parâmetro.

### `trataTexto`
- `-removeEspacoduplo` colapsa sequências de espaços e tabulações de **qualquer comprimento** em um único espaço, sem afetar quebras de linha (controladas por `-removeQuebraLinha`).
- `-removeVirgula` (padrão `$true`) controla a substituição de vírgulas por espaço. Em versões anteriores esse comportamento era aplicado sempre e de forma não documentada.

### `removeQuebraDeLinha`
Substitui por um único espaço as três convenções de fim de linha: CRLF (Windows), LF (Unix) e CR isolado. CRLF é tratado como uma unidade, portanto não gera espaço duplo.

- Até a versão 13 apenas o CRLF era removido: as duas substituições seguintes usavam aspas simples e trocavam o literal crase+`n` e crase+`r`, sem efeito sobre quebras reais. Texto vindo de origem Unix passava intacto.

### `sorteiaIndicesSeguros`
Função auxiliar que sorteia índices aleatórios criptograficamente seguros no intervalo `[0, limite)`. Usada por `geraSenhaAleatoria`, mas disponível para qualquer script que precise de aleatoriedade não previsível.

## Módulos / Dependências
- Nenhum módulo explícito
