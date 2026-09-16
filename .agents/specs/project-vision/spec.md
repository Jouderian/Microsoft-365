---
description: Especificação fundacional do projeto — define a intenção do projeto, atores, fluxos de valor core e restrições inegociáveis (LGPD, passwordless, storage protegido, licenciamento, modelo de roles). Consultar antes de qualquer spec de feature.
---

# Especificação Base: Visão Fundacional do Projeto

> A finalidade deste repositório é concentrar e documentar o ecossistema de scripts operacionais (PowerShell) responsáveis pela gestão de ciclo de vida e identidade da base de colaboradores.

## Contexto do Projeto: Active Directory e Microsoft 365

Este repositório contém uma coleção de scripts administrativos desenvolvidos em PowerShell (arquivos `.ps1`), focados no gerenciamento de serviços em nuvem Microsoft 365, Teams, Exchange Online e Active Directory.

## Propósito

Os scripts abrangem funcionalidades como:
- Ativação de políticas corporativas de segurança e governança (Ex.: `ativarLitigio.ps1`, `ativarAutoArquivamento.ps1`).
- Configurações de rotina de TI (Ex.: `mudarLicencas.ps1`, `limpaCacheTeamsOutlook.ps1`).
- Auditorias e listas (Ex.: `listarCaixasPostais.ps1`, `listarCaixasCompartilhadas.ps1`, `validaGPOs.ps1`).
- Integração híbrida e migração (Ex.: `sincroniza_AD_M365.ps1`).

## Restrições Inegociáveis
- **Segurança de Credenciais**: Nada no modelo de *Hardcoded Secrets* passa em homologação.
- **Retrocompatibilidade / Progressão Cautelosa**: Os scripts rodam diariamente. Mudanças (especialmente refatores em módulos Core como `M365_Functions`) não podem quebrar os scripts de origem, a menos que as dependências sejam mapeadas e corrigidas simultaneamente (`tasks.md`).
- **Poder de Veto**: Alterações massivas em arquitetura requerem ciência e homologação (aprovação formal nas issues/beads/tasks) pelo dono do processo.
