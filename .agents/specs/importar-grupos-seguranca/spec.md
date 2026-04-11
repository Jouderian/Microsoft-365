# Spec: Importar Grupos de Segurança (Graph)

## O que é
A rotina tem como foco criar novos Grupos de Segurança no M365 (via infraestrutura Entra ID/Azure AD) a partir da leitura de um arquivo CSV, utilizando a API moderna do Microsoft Graph, em vez da defasada API original (AzureAD). Os grupos nasceram puramente com foco em permissionamento (sem caixa de correio atrelada).

## Atores
- **Administrador de TI**: Aciona o script para otimizar tempo na esteira de criação de múltiplas áreas ou times no Entra ID.

## Requisitos
- A fonte de dados é exclusiva de um arquivo delimitado ou texto tabulado/vírgula contendo colunas mandatórias.
- As colunas obrigatórias presentes no arranjo dos dados são:
  1. `Nome` (Opcionalmente será utilizado como DisplayName e NickName)
  2. `Descricao` (Detalhe da finalidade institucional do grupo)
  3. `eMailProprietário` (A referida UPN do responsável que gere e aprova os recursos alocados ao grupo)

## Critérios de Aceitação
- [X] O script consegue autenticar com sucesso usando `Connect-MgGraph`.
- [X] O script mapeia internamente o `eMailProprietário` para resgatar o UserID do AD do Graph.
- [X] O script processa a lista gerando Security Groups desabilitados para Mail `(-MailEnabled $false -SecurityEnabled $true)`.
- [X] O script designa com sucesso o usuário identificado como Proprietário do recém-criado Grupo.
- [X] Se houver erros operacionais (ex: Owner não encontrado), deve persistir a mensagem em um log auditável.
