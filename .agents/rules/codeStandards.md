---
trigger: always_on
---

---
trigger: always_on
---

---
description: Padrões de código — princípios de design, logging, estilo, nomenclatura e cobertura de testes
---

# Padrões de Código

> Regras de qualidade, estilo e convenções aplicáveis a todo código do projeto.

---

## Princípios de Design

Todo código gerado deve seguir os princípios de **Arquitetura Limpa** e **Código Limpo**:

- **Clean Code:** Siga os Princípios de design e desenvolvimento de código limpo (Modularização, tratamento assertivo de erros com try/catch, clareza).
- **Separação de Concerns:** separar orquestração (como/quando) de lógica de negócio (o quê).
- **Funções pequenas e nomeadas:** preferir funções curtas com nomes que expressem a intenção. Evitar funções longas com múltiplas responsabilidades.
- **Sem efeitos colaterais ocultos:** métodos devem fazer o que o nome promete — sem mutações inesperadas de estado ou dependências implícitas.
- **Código autoexplicativo:** preferir clareza a comentários. Comentários devem explicar o "por quê", não o "o quê".
- **Imutabilidade:** preferir dados imutáveis e funções puras quando prático.
- **Idempotência**: Todos os scripts devem rodar 1 ou 100 vezes e causar o mesmo final state desejado. Trate checagens antecipadas (`if (não existe) { cria } else { ignora }`).
- **Zero Senhas**: Jamais commite `SecureStrings` legíveis, tokens em plain-text ou *Hardcoded secrets*. Deixe o operador lidar com o KeyVault ou entrada paramétrica (`-ClientSecret`).
- **Nomenclatura (camelCase):** Este projeto convencionou o uso obrigatório de Notação Camelo (`camelCase`) para instanciar/nomear variáveis (`$minhaVariavel`), nomes de arquivos (`meuScript.ps1`) e arquivos/diretórios dos agentes SDD.
- **Tratamento explícito de erros:** não ignore erros; registre e faça log.
- **Tratamento de exceções:** scripts em lote ou loops devem usar `try { ... } catch { ... }` para evitar que erros interrompam o script, registrando e gerando log.
- **Cabeçalho Padrão:** Todo script `.ps1` deve usar o bloco rigoroso `<# .SYNOPSIS ... #>` conforme definido em `.agents/workflows/newScript.md`.
- **Alias PowerShell:** É terminantemente proibido o uso de aliases implícitos e não mapeáveis como `%` e `?`. O uso de cmdlets originais e completos é exigido na base para clareza (ex: `ForEach-Object`, `Where-Object`).