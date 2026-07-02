---
description: Decisão sobre contornar a perda de métodos de objetos desserializados do Exchange Online e uso de pre-sizing de hashtables
---

# Registro de Decisões (ADR 003): Objetos Desserializados do Exchange Online e Otimizações de Lote

- **Data:** Julho de 2026
- **Status:** Aceita

## Contexto

Durante o processo de otimização do script de listagem de caixas postais (`listarCaixasPostais.ps1`) para ambientes com +3.000 caixas postais, identificou-se que a conversão direta de tamanhos de caixas utilizando o método nativo `.ToBytes()` do tipo `ByteQuantifiedSize` causava falhas silenciosas. O valor retornado era zerado (capturado por blocos `try/catch` de fallback).

Investigações apontaram que os objetos retornados pelo módulo **ExchangeOnlineManagement v3** são objetos **desserializados** (com o prefixo de tipo `Deserialized.Microsoft.Exchange.Data.ByteQuantifiedSize`) ao cruzarem a fronteira de sessão do PowerShell Remoting (REST-based). Objetos desserializados preservam propriedades estáticas expostas no XML/JSON de serialização, mas perdem todos os métodos de instância e de extensão originais do .NET, incluindo o `.ToBytes()`.

Além disso, o processamento de mais de 3.000 caixas destacou a degradação de performance gerada por *rehashing* consecutivo ao criar Hashtables (`@{}`) sem capacidade inicial definida, gerando realocações de array exponenciais sob grande volume de dados.

---

## Detalhamento Técnico e Exemplos

### 1. Perda de Métodos por Desserialização (ByteQuantifiedSize)
Em sessões de remoting do PowerShell (incluindo cmdlets REST do Exchange Online v3), as classes originais do servidor são empacotadas. Ao chegar na máquina local, o tipo é recriado como um objeto desserializado.

*   **Problema (Método perdido):** `$objeto.TotalItemSize.Value.ToBytes()` lança uma exceção silenciosa e o bloco `catch` atribui `0` ao tamanho.
*   **Solução (Parsing de string):** Chamar o método padrão `.ToString()` (que é do runtime e sempre funciona) e extrair os bytes numéricos da string gerada pelo Exchange: `"1.234 GB (1,324,829,180 bytes)"`.

#### Exemplo de Código (Antes vs Depois)
```powershell
# ANTES (Falha silenciosa com ToBytes devido à desserialização)
try {
  $tamanho = [math]::Round($detalheCaixa.TotalItemSize.Value.ToBytes() / 1GB, 2)
} catch {
  $tamanho = 0
}

# DEPOIS (Parsing resiliente de string que funciona com objetos desserializados)
try {
  $tamanhoStr = $detalheCaixa.TotalItemSize.Value.ToString() # Ex: "1.24 GB (1,331,432,120 bytes)"
  $bytesStr = $tamanhoStr.Split('(')[1].Split(' ')[0].Replace(',', '')
  $tamanho = [math]::Round(($bytesStr / 1GB), 2)
} catch {
  $tamanho = 0
}
```

---

### 2. Mecânica do Rehashing em Hashtables
Uma Hashtable vazia criada via `$tabela = @{}` reserva por padrão apenas **16 slots**. Conforme novos itens são inseridos e a tabela atinge seu limite de preenchimento (load factor de 75%), o .NET executa o **rehashing**:
1. Aloca um novo array de tamanho duplicado.
2. Recalcula o índice de hash para todos os elementos existentes.
3. Copia cada elemento para o novo espaço de memória (operação $O(N)$).

Para 3.000 entradas, essa duplicação e recalculamento ocorre cerca de **8 vezes** (`16 -> 32 -> 64 -> 128 -> 256 -> 512 -> 1024 -> 2048 -> 4096`), gerando picos de CPU e alocação redundante de memória.

#### Exemplo de Código (Antes vs Depois)
```powershell
# ANTES (Criação padrão com 16 slots - sofre rehashing constante com +3000 itens)
$detalheCredenciais = @{}
$licencasPorUPN = @{}

# DEPOIS (Pre-sizing baseado na quantidade total esperada)
$capacidade = [int]($total * 1.15) # Margem de 15% para usuários sem mailbox
$detalheCredenciais = [System.Collections.Hashtable]::new($capacidade)
$licencasPorUPN     = [System.Collections.Hashtable]::new($capacidade)
```

---

### 3. Cache de Processamentos Repetitivos
A conversão de propriedades ou traduções estáticas de dados (como códigos de SKU de licenças para nomes amigáveis em português) por meio de switches repetidos consome processamento linear desnecessário se executado a cada iteração do loop principal. O uso de uma tabela de cache em memória de escopo local resolve a redundância.

#### Exemplo de Código (Antes vs Depois)
```powershell
# ANTES (Executa a função/switch para cada licença de cada um dos 3000+ usuários)
$nomeLicenca = ObterDescricaoLicenca -SkuPartNumber $skuPart

# DEPOIS (Consulta o cache local antes; executa a função apenas 1x para cada tipo de licença do tenant)
if (-not $cacheLicenca.ContainsKey($skuPart)) {
  $cacheLicenca[$skuPart] = ObterDescricaoLicenca -SkuPartNumber $skuPart
}
$nomeLicenca = $cacheLicenca[$skuPart]
```

---

### 4. Perda de Propriedades Implícitas em Chamadas REST (Exchange Online v3)
Ao executar consultas à API REST do Exchange Online v3 utilizando cmdlets de estatísticas (como `Get-EXOMailboxStatistics`), a especificação explícita de propriedades adicionais usando o parâmetro `-Properties <propriedade>` restringe o payload JSON retornado a fim de maximizar a performance de transporte de rede.

*   **Comportamento Oculto:** Ao passar `-Properties TotalItemSize`, propriedades que eram comumente inclusas de forma implícita (como `MailboxGuid`) passam a vir nulas (`$null`). 
*   **Problema:** Tentar indexar coleções mapeadas usando `$stat.MailboxGuid.ToString()` resulta em chaves nulas e, por consequência, o lookup no loop principal falha e as colunas de dados final (tamanho de caixa) são gravadas em branco.
*   **Solução:** Sempre mapear as tabelas hash de estatísticas utilizando o identificador único (`Guid`) pertencente ao objeto iterador local da própria coleção de origem (`$_.Guid.ToString()`), que é garantidamente preenchido.

#### Exemplo de Código (Antes vs Depois)
```powershell
# ANTES (Gera chaves nulas devido ao MailboxGuid retornar vazio sob REST + -Properties)
$caixas | ForEach-Object {
  $stat = Get-EXOMailboxStatistics -Identity $_.Guid -Properties TotalItemSize
  if ($null -ne $stat.MailboxGuid) {
    $estatisticasPorGuid[$stat.MailboxGuid.ToString()] = $stat
  }
}

# DEPOIS (Independe do retorno de MailboxGuid e garante a consistência das chaves)
$caixas | ForEach-Object {
  $stat = Get-EXOMailboxStatistics -Identity $_.Guid -Properties TotalItemSize
  if ($null -ne $stat) {
    $estatisticasPorGuid[$_.Guid.ToString()] = $stat
  }
}
```

---

## Decisão

Fica definido como padrão técnico para este repositório:
1. **Banimento de Métodos de Instância do Exchange Online**: Proibido invocar métodos como `.ToBytes()` em objetos do tipo `ByteQuantifiedSize` originados do Exchange. Deve-se tratar o dado como string e efetuar o parsing manual baseado em split/regex.
2. **Pré-dimensionamento de Hashtables (Pre-sizing)**: Em qualquer laço/pipeline que armazene mais de 100 elementos em tabelas hash, as variáveis devem ser instanciadas via `[System.Collections.Hashtable]::new($capacidade)` informando a capacidade pré-calculada do lote.
3. **Pré-carga Isolada de Estatísticas de Arquivamento**: Estatísticas de caixas de arquivamento ativo (`-Archive`) devem ser obtidas na fase de preparação do script em uma hashtable indexada por GUID/UPN de uma só vez, eliminando chamadas de rede no loop de geração do CSV.
4. **Indexação por Chave Externa Conhecida**: Hashtables de mapeamento de cmdlets de rede (como `Get-EXOMailboxStatistics`) devem usar como chaves os identificadores do laço de controle local (ex: `$_.Guid.ToString()`), em vez de extrair propriedades identificadoras do objeto de retorno do comando, para evitar erros causados por propriedades omitidas em payloads otimizados (REST).
5. **Cache de Tradução de Licenças**: Usar dicionários locais de cache para funções auxiliares custosas ou de lookup estático dentro de laços grandes.

---

## Consequências

*   **Correção de Bugs Silenciosos**: Evita que colunas de tamanho em GB (como `usado(GB)` e `Arquivamento(GB)`) fiquem zeradas ou vazias devido à falta de métodos nos objetos desserializados ou por chaves não mapeadas nas hashtables.
*   **Performance Escalável**: Reduz o tempo de iteração e formatação de texto em disco e memória sob grandes volumes (+3.000 caixas).
*   **Portabilidade**: Assegura compatibilidade tanto no PowerShell 5.1 (Windows PowerShell) quanto no PowerShell 7+.

---

## Fontes
- `listarCaixasPostais.ps1` (v27)
- Biblioteca de funções local: `bibliotecaDeFuncoes.ps1`
- Comportamento de Desserialização do PowerShell Remoting (WinRM/REST do Exchange)
- Comportamento de Payload Otimizado (REST) com parâmetro `-Properties` em cmdlets EXO v3.
- Documentação do tipo `.NET Hashtable` e estrutura de Rehashing.