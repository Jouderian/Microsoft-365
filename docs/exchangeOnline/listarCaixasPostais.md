# listarCaixasPostais.ps1

> **Sinopse**: Extrai uma listagem com as principais caracteristica de todas as caixas postais do Exchange (Microsoft 365).

## Descrição
O script se conecta ao ambiente do Microsoft 365, busca todas as caixas postais existentes e extrai uma série de informações sobre cada caixa postal, como nome, UPN, cidade, empresa, tipo, tamanho utilizado, entre outros. As informações são gravadas em um arquivo CSV para análise posterior.

## Detalhes
- **Autor**: Jouderian Nobre
- **Versão Atual**: 25 (31/05/26) - Otimização de altíssima performance com pré-carga única Graph/Exchange e gerenciamento otimizado de memória
- **Saída**: Arquivo CSV (`$($env:ONEDRIVE)\Documentos\WindowsPowerShell\listaDeCaixasPostais.csv`) contendo as seguintes 29 colunas de informações:
  - **Nome**: Nome de exibição (`displayName`).
  - **UPN**: User Principal Name (`userPrincipalName`).
  - **Cidade**: Cidade do usuário (`City`).
  - **UF**: Estado/Província (`State`).
  - **Empresa**: Nome da empresa (`CompanyName`).
  - **Escritorio**: Escritório associado (`Office`).
  - **Departamento**: Departamento (`Department`).
  - **Cargo**: Cargo/Título profissional (`jobTitle`).
  - **Gerente**: Nome do gerente/gestor (`Manager`).
  - **CC**: Código de Centro de Custo (`postalCode`).
  - **nomeCC**: Nome ou endereço do Centro de Custo (`streetAddress`).
  - **Tipo**: Tipo de caixa postal (`recipientTypeDetails`).
  - **AD**: Se é sincronizado com o Active Directory local (`isDirSynced`).
  - **Desabilitada**: Se a conta está desabilitada (`accountDisabled`).
  - **SenhaNaoExpira**: Se a senha está configurada para não expirar (`passwordPolicies`).
  - **Compartilhada**: Se é uma caixa postal compartilhada (`isShared`).
  - **Encaminhada**: Se possui encaminhamento ativo (`ForwardingAddress`).
  - **Litigio**: Se o Litígio de Preservação está ativo (`litigationHoldEnabled`).
  - **usado(GB)**: Tamanho utilizado em GB.
  - **Arquivamento**: Status da caixa de arquivamento (`archiveStatus`).
  - **Arquivamento(GB)**: Tamanho utilizado na caixa de arquivamento em GB.
  - **Criacao**: Data de criação da conta.
  - **MudancaSenha**: Data da última alteração de senha.
  - **ultimoSyncAD**: Data da última sincronização com o AD local.
  - **ultimoAcesso**: Data do último acesso/interação com a caixa.
  - **conta**: Alias da caixa postal.
  - **objectId**: Guid único da caixa postal.
  - **Licencas**: Licenças principais do Office 365 atribuídas (traduzidas via SKU).
  - **outrasLicencas**: Demais licenças e SKUs associadas.

## Módulos / Dependências
- **ExchangeOnlineManagement**
- **Microsoft.Graph** (Microsoft.Graph.Users)
