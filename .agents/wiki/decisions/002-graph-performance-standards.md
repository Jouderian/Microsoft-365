---
description: Decisão de adotar pré-cargas consolidadas (Graph/Exchange) e dicionários O(1) como padrão de performance
---

# Registro de Decisões (ADR 002): Padrões de Alta Performance em APIs da Nuvem

- **Data:** Junho de 2026
- **Status:** Aceita

## Contexto

Em scripts operacionais que iteram sobre volumes de dados consideráveis (ex: ~4.000 caixas postais no Exchange Online e Entra ID), o modelo original contendo chamadas de rede individuais a cada elemento do loop principal (`Get-MgUserLicenseDetail`, `Get-MgUserManager`, `Get-EXOMailboxStatistics` por item) gerava um impacto de 12.000 a 16.000 conexões web adicionais. 

Isso criava dois gargalos críticos:
1. **Performance sofrível (N+1)**: A latência agregada de rede estendia a execução para mais de 1h30m.
2. **Throttling e Limites de API**: Sobrecarga de chamadas provocando rejeição por limites de concorrência nos endpoints de nuvem.
3. **Degradação de Memória**: O operador de array tradicional (`$buffer += $item`) sofria degradação exponencial devido à constante realocação de memória a cada ciclo do loop.

## Decisão

Fica estabelecido como **diretriz e restrição inegociável** para todos os scripts em PowerShell deste repositório que acessem dados cloud:

1. **Banimento de Chamadas N+1**: É expressamente proibida a execução de comandos individuais de rede (como `Get-Mg*` ou `Get-EXO*`) dentro de laços iterativos de volume (ex: `Foreach`).
2. **Pré-Carregamento Consolidado (Batching)**: Os dados necessários do Graph ou Exchange devem ser obtidos em uma única chamada de lote paginada antes do loop. Exemplo:
   ```powershell
   # Obtenção de todos os usuários contendo propriedades e expansão em uma única conexão
   $detalhes = Get-MgUser -All -Property "id,assignedLicenses" -ExpandProperty manager
   ```
3. **Mapeamento em Memória (Acesso O(1))**: Os dados pré-carregados devem ser estruturados em Tabelas Hash (Hashtables) locais usando o identificador exclusivo do item como chave. O loop acessará o dicionário em tempo constante:
   ```powershell
   $licencasPorUPN = @{}
   foreach ($d in $detalhes){
     $licencasPorUPN[$d.UserPrincipalName.ToLower()] = $d.AssignedLicenses
   }
   ```
4. **Gerenciamento Otimizado de Coleções**: O operador `$buffer +=` está banido para laços repetitivos acima de 100 iterações. Exige-se o uso de `[System.Collections.Generic.List[string]]` para manipulação de listas e buffers, aproveitando o método `.Add()` de custo amortizado O(1):
   ```powershell
   $buffer = [System.Collections.Generic.List[string]]::new()
   $buffer.Add($dados)
   ```
5. **Redução de Payload do Exchange**: Consultas ao Exchange Online Management v3 não devem carregar propriedades completas (`-PropertySets All`) se não forem necessárias. Deve-se restringir o retorno especificando estritamente os campos requeridos na propriedade `-Properties`.

## Opções Avaliadas

- **Manter chamadas e usar Runspaces/Paralelismo**: Rejeitado devido à complexidade de gerenciar concorrência de rede em hosts locais de TI e risco de agravar o throttling do Exchange Online.
- **Implementar Otimizações em Dicionários locais e Pré-Carga Consolidadas (Escolhida)**: Reduz conexões, garante previsibilidade e roda em qualquer ambiente PowerShell 5.1/7+.

## Consequências (Impacto)

- Redução instantânea de mais de 80% do tempo de processamento total (caindo para 15-20 minutos).
- Estabilidade e robustez frente às políticas de segurança de limites de API da Microsoft.
- Estrutura de código simplificada, modularizada e perfeitamente legível por agentes autônomos e desenvolvedores.
