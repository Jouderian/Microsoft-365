# Registro de Decisões (ADR 001): Padrões de Clean Code no PowerShell

## Contexto
Durante a auditoria primária em Abril de 2026 para padronizar mais de 40 scripts heterogêneos no repositório, foi notado um desarranjo na padronização de variáveis, versionamentos múltiplos de arquivos (uso excessivo de prefixos e sufixos como `v1`, `v2`, `TESTE`) e sintaxes poluídas com aliases curtos nativos do PowerShell, como `%` e `?`, dificultando a leitura escalável por agentes automatizados ou desenvolvedores júnior.

## Decisão
Foi escolhido banir a pluralização ou copia de segurança (backup) via nome de arquivos em produção para o uso rigoroso de versionamento via git interligado a uma base única de `master file`.
Todos os nomes de arquivos, metadados internos de agentes e escopos de variáveis (`$`) devem ser migrados ou estabelecidos desde a fundação usando **camelCase**. 
Por fim, foi banido o uso de macros encurtadas do host (alias). Toda implementação e uso de pipeline deve ser declarativa.

## Consequências
- A base do repositório deve prezar pelo `Comment-Based Help` oficial.
- Extensiva refatoração exigida ao tocar em relíquias antigas do código.
- Maior velocidade na compreenção nativa por robôs/agentes revisores de fluxo.
