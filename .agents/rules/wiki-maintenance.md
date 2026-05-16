---
trigger: always_on
description: >
---

# Manutenção da Base de Conhecimento (Wiki)

## Quando atualizar
Ao final de qualquer sessão que envolva:
- Decisões arquiteturais ou trade-offs
- Correções de bugs não-triviais
- Novos padrões, convenções ou refatorações
- Mudanças em specs, APIs, schema Drizzle ou contratos públicos
- Novos middlewares, services ou componentes React
- Resolução de problemas que exigiram investigação
- Alterações no modelo de autenticação, LGPD ou licenciamento

## Como atualizar
1. Leia `.agents/wiki/index.md` para identificar as páginas existentes
2. Atualize as páginas afetadas OU crie novas se o tópico não existir
3. Atualize o `index.md` se novas páginas foram criadas
4. Faça commit das mudanças no wiki junto com o código

## Formato das páginas wiki
- Markdown com cross-references usando links relativos
- Cabeçalho: `Última atualização: YYYY-MM-DD`
- Seção `## Fontes` no final, apontando para specs, ADRs, arquivos e sessões
- Sintetize, não copie — specs, ADRs e plan.md continuam sendo fonte de verdade

## O que NÃO deve ir no wiki
- Código-fonte (já está no repositório)
- Conteúdo que duplica specs ou ADRs verbatim
- Informações temporárias ou específicas de uma sessão
- Decisões arquiteturais formais (devem ser ADRs em `.agents/adrs/` via `/register-adr`)