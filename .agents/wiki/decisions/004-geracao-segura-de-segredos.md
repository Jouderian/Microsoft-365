---
description: Decisão de usar gerador criptográfico com amostragem por rejeição, em vez de Get-Random, para toda geração de segredos no repositório
---

# Registro de Decisões (ADR 004): Geração Segura de Segredos

- **Data:** Setembro de 2026
- **Status:** Aceita

## Contexto

A função `geraSenhaAleatoria` da `bibliotecaDeFuncoes.ps1` é a única fonte de senhas do repositório e alimenta a criação e o reset de contas no Active Directory e no Entra ID. A implementação original apresentava três defeitos acumulados:

1. **Gerador não criptográfico.** Usava `Get-Random`, que é baseado em `System.Random` — um gerador pseudoaleatório previsível a partir da semente. Não é adequado para material de credencial.
2. **Parâmetro `chars` ignorado.** O corpo da função sorteava sobre os intervalos de código `(65..90) + (97..122) + (48..57) + (33..47)` fixos, descartando silenciosamente o conjunto informado pelo chamador. O parâmetro documentado não tinha efeito algum.
3. **Sorteio sem reposição.** `Get-Random -Count $tamanho` sorteia elementos distintos de uma coleção. Além de reduzir o espaço de busca, isso limita o tamanho máximo da senha ao tamanho do conjunto de caracteres.

Não havia, tampouco, garantia de complexidade: uma senha podia sair sem dígito ou sem maiúscula e ser rejeitada pela política de senha do domínio, fazendo o script de provisionamento falhar de forma intermitente.

---

## Detalhamento Técnico

### Viés de módulo

O caminho ingênuo para converter bytes aleatórios em um índice é `valor % limite`. Como `UInt32.MaxValue + 1` raramente é múltiplo do tamanho do conjunto, os primeiros índices recebem uma faixa de valores a mais que os últimos, e passam a ser escolhidos com mais frequência. O efeito é pequeno para conjuntos pequenos, mas é um viés real e evitável.

A correção é **amostragem por rejeição**: descartar os sorteios que caem na faixa incompleta final.

```powershell
# Maior múltiplo de $limite que cabe em um UInt32
$teto = [uint32]([math]::Floor([uint32]::MaxValue / $limite) * $limite)

do {
  $gerador.GetBytes($bytes)
  $valor = [System.BitConverter]::ToUInt32($bytes, 0)
} while ($valor -ge $teto)

$indice = [int]($valor % $limite)
```

### Garantia de complexidade

A senha reserva uma posição por classe de caractere **presente no conjunto informado** (minúscula, maiúscula, dígito, símbolo), completa o restante sorteando livremente e então embaralha com Fisher-Yates. O embaralhamento é necessário: sem ele, as classes garantidas ficariam sempre nas primeiras posições, um padrão previsível.

Classes ausentes do conjunto não são exigidas — `-chars 'abc'` continua produzindo senha válida de letras minúsculas.

---

## Decisão

- Toda geração de segredo no repositório usa `System.Security.Cryptography.RandomNumberGenerator`. O uso de `Get-Random` para material de credencial fica proibido.
- A conversão de bytes em índice usa amostragem por rejeição, encapsulada na função auxiliar `sorteiaIndicesSeguros`, disponível para qualquer script que precise de aleatoriedade não previsível.
- O sorteio é **com reposição**, de modo que o tamanho pedido seja sempre respeitado independentemente do tamanho do conjunto.
- O comprimento mínimo de senha aceito é **7 caracteres**, imposto por `ValidateRange` na assinatura da função para que a violação falhe na chamada, e não no meio do provisionamento.
- O conjunto padrão de caracteres exclui vírgula, ponto-e-vírgula e aspas, que corromperiam os arquivos CSV e de log gerados pelos scripts do repositório.
- A senha é retornada como texto puro. A conversão para `SecureString` e o descarte da variável são responsabilidade do chamador, que é quem conhece o destino do valor.

## Opções Avaliadas

- **Manter `Get-Random` e apenas corrigir o respeito ao parâmetro `chars`.** Rejeitada: resolve o defeito funcional, mas mantém um gerador previsível para material de credencial.
- **Usar `[System.Web.Security.Membership]::GeneratePassword()`.** Rejeitada: depende de `System.Web`, ausente no PowerShell Core, e não permite controlar o conjunto de caracteres — gera símbolos que quebram os CSVs do repositório.
- **Gerador criptográfico com amostragem por rejeição e complexidade garantida.** (Escolhida)

## Consequências (Impacto em Scripts Legados)

- Senhas geradas passam a conter os símbolos do conjunto padrão completo, e não mais apenas o intervalo ASCII 33–47. Scripts que gravem a senha em CSV continuam seguros, pois vírgula e aspas foram removidas do conjunto padrão.
- O parâmetro `-chars`, antes inerte, passa a ter efeito. Qualquer chamador que já o informasse recebia o conjunto fixo e agora recebe o que pediu — é uma correção, mas altera o resultado observado.
- `-tamanho` passa a ser validado no intervalo de 7 a 256. Chamadas com valores fora da faixa, antes aceitas, agora falham na validação de parâmetro. O piso de 7 é um mínimo de segurança adotado pelo repositório, acima das 4 classes de caractere que a garantia de complexidade exige.
- Senhas maiores que o conjunto de caracteres tornam-se possíveis, o que antes era silenciosamente truncado pelo sorteio sem reposição.

## Fontes

- `bibliotecaDeFuncoes.ps1` — funções `geraSenhaAleatoria` e `sorteiaIndicesSeguros` (versão 13)
- `docs/bibliotecaDeFuncoes.md` — notas de uso
- `.agents/rules/code-standards.md` — princípio "Zero Senhas"
