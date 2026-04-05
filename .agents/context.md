# Contexto do Projeto: Microsoft-365

Este repositório contém uma coleção de scripts administrativos desenvolvidos em PowerShell (arquivos `.ps1`), focados no gerenciamento de serviços em nuvem Microsoft 365, Teams, Exchange Online e Active Directory.

## Propósito

Os scripts abrangem funcionalidades como:
*   Ativação de políticas corporativas de segurança e governança (Ex.: `ativarLitigio.ps1`, `ativarAutoArquivamento.ps1`).
*   Configurações de rotina de TI (Ex.: `mudarLicencas.ps1`, `limpaCacheTeamsOutlook.ps1`).
*   Auditorias e listas (Ex.: `listarCaixasPostais.ps1`, `listarCaixasCompartilhadas.ps1`, `validaGPOs.ps1`).
*   Integração híbrida e migração (Ex.: `sincroniza_AD_M365.PS1`).

## Padrões Adotados (Agent-Flywheel)

Este projeto usa a metodologia **Spec-Driven Agent-Flywheel**:
1.  **.agents/BEADS.md**: Atua como a "única fonte da verdade", guardando o Backlog contínuo de novas automações ou otimizações, execução de estado do ambiente, ações tomadas e decisões consolidadas.
2.  **Multiperfil de Agente**: O sistema conta com agentes de inteligência artificial autônomos ou sob demanda (como o Antigravity) apoiando as tarefas diárias e resolução de bugs. 
3.  Qualquer agente entrando no repositório **deve** primeiro consultar `.agents/BEADS.md` antes de propor ou executar modificações nos scripts.
