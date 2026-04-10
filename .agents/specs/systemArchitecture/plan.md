# System Architecture Plan

Fonte de verdade técnica para Execução e Estado do Sistema.

## 1. Executable (Ambiente e Execução)
*   **Modelos de Execução:** Os scripts dependem do módulo Microsoft 365, Teams (ExchangeOnlineManagement, MicrosoftTeams) e ActiveDirectory em Windows PowerShell 5.1/7+.
*   **Agentes:** Consultam primeiro as normas em `.agents/rules/general.md` e `.agents/rules/codeStandards.md`.
*   **Workflow:** Para criar um novo script, siga `.agents/workflows/newScript.md`.

## 2. State (Estado Atual)
**Verde (Estável):** Repositório totalmente documentado sob a governança SDD. Todos os scripts possuem cabeçalho padronizado, o `readMe.md` cobre a raiz e a pasta `activeDirectory`, e o workflow de criação modular é o padrão.
