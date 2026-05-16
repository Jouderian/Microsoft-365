---
description: Workflow para iniciar uma nova feature usando Spec-Driven Development
---

# Iniciando Nova Feature (Workflow)

Para introduzir uma nova funcionalidade, alteração profunda em script ou refatoração no projeto, você **deve** usar SDD.

### Passo 1: Reserva e Estrutura
- Acione o Agente e decida o nome da feature (ex: `automacaoUsuario`).
- Crie o diretório em `.agents/specs/<nome-da-feature>`.
- Dentro, crie `spec.md`, `plan.md` e `tasks.md`.

### Passo 2: O Manifesto
- Escreva o `spec.md` (Por que as coisas devem mudar? Quem usará? Qual é a regra de negócio e critérios de aceitação?).
- Obtenha validação do usuário nesta etapa.

### Passo 3: O Desenho
- Escreva o `plan.md` contendo a parte técnica (Quais funçōes alteradas, impacto sistêmico, diagramas de fluxo).
- Traga à tona quaisquer bloqueios de segurança M365 (ex: App Registrations Required).

### Passo 4: O Checklist Atômico
- Escreva o `tasks.md` decompondo o `plan.md` em itens que poderão receber flags de `[x]` uma vez que a feature entre para linha de montagem.

### Passo 5: O Código 
Somente neste momento devem ser injetados novos scripts. Tudo deve ser guiado e estritamente atrelado à feature. Em caso de mudanças no escopo, volta ao Passo 2.
