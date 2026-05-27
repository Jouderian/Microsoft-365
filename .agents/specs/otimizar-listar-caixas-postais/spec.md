---
description: Especificação para otimização de performance do script listarCaixasPostais.ps1 em ambientes com ~4.000 caixas postais
---

# Spec: Otimização de Performance — listarCaixasPostais.ps1

## Contexto e Motivação

O script `listarCaixasPostais.ps1` está executando de forma muito lenta em ambientes com quase 4.000 caixas postais. A causa raiz é a realização de múltiplas chamadas individuais de API (por caixa) dentro do loop principal, totalizando entre 12.000 e 16.000 requisições de rede.

## Atores

- **Executor:** Administrador de TI / M365
- **Destino:** CSV gerado para relatórios de governança

## Gargalos Identificados

| # | Linha | Problema | Impacto estimado (4k caixas) |
|---|-------|----------|------------------------------|
| 1 | 88    | `Get-MgUserLicenseDetail` por caixa dentro do loop | ~4.000 chamadas Graph |
| 2 | 89    | `Get-EXOMailboxStatistics` por caixa dentro do loop | ~4.000 chamadas Exchange |
| 3 | 108   | `Get-MgUserManager` por caixa dentro do loop | ~4.000 chamadas Graph |
| 4 | 70    | `Get-EXOMailbox -PropertySets All` busca sets desnecessários | Payload excessivo |
| 5 | 169   | `$buffer += $infoCaixa` (array concatenation) | Realocação de memória a cada item |

## Regras de Negócio e Critérios de Aceitação

1. O CSV de saída deve ter **exatamente as mesmas colunas** e a mesma semântica que o atual.
2. Nenhuma coluna pode ser removida ou renomeada.
3. O script deve continuar sendo **idempotente** (pode ser executado N vezes).
4. Os logs devem continuar funcionando da mesma forma.
5. A otimização deve ser medida: o tempo de execução deve cair significativamente.
6. O script deve manter compatibilidade com **PowerShell 5.1 e 7+**.
7. Nenhuma nova dependência de módulo pode ser adicionada.

## Restrições

- Não usar paralelismo via runspaces ou `ForEach-Object -Parallel` sem aprovação explícita.
- Não alterar o formato do CSV de saída.
- Não remover nenhum campo do relatório.
