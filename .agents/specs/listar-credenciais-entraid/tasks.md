---
description: Lista de tarefas para implementação do script listarCredenciaisEntraId.ps1
---

# Checklist de Implementação: Listar Credenciais do Entra ID

- [x] **Fase 1: Setup e Infraestrutura**
  - [x] Validar e garantir escopos mínimos do Graph API (Application.Read.All)
  - [x] Implementar verificação de conexão com Microsoft.Graph (`Get-MgContext`)
- [x] **Fase 2: Estrutura Principal e Parâmetros**
  - [x] Criar arquivo `listarCredenciaisEntraId.ps1` com cabeçalho de documentação padronizado (`.SYNOPSIS`)
  - [x] Declarar parâmetros: `-TipoAplicacao`, `-DiasParaExpirar`, `-ExportarCsv`
- [x] **Fase 3: Coleta e Filtro de App Registrations**
  - [x] Chamar `Get-MgApplication -All`
  - [x] Iterar e obter proprietários (`Get-MgApplicationOwner`) com tratamento de erro (`try/catch`)
  - [x] Mapear as coleções de Secrets (`PasswordCredentials`) e Certificados (`KeyCredentials`)
- [x] **Fase 4: Coleta e Filtro de Enterprise Applications**
  - [x] Chamar `Get-MgServicePrincipal -All`
  - [x] Filtrar ruídos (excluir Managed Identities `ServicePrincipalType -eq 'ManagedIdentity'` e SPs da Microsoft)
  - [x] Iterar e obter proprietários (`Get-MgServicePrincipalOwner`) com tratamento de erro (`try/catch`)
  - [x] Mapear as coleções de Secrets (`PasswordCredentials`) e Certificados (`KeyCredentials`)
- [x] **Fase 5: Consolidação dos Dados e Cálculos**
  - [x] Calcular dias restantes (`DaysRemaining`) e formatar datas (`yyyy-MM-dd`)
  - [x] Filtrar por `-DiasParaExpirar` se fornecido
  - [x] Gerar objeto de saída padronizado (`[PSCustomObject]`)
- [x] **Fase 6: Exportação e Tratamento de Erros**
  - [x] Implementar gravação em CSV via `-ExportarCsv` com codificação UTF-8
  - [x] Assegurar que falhas pontuais de leitura não parem a execução principal
- [x] **Fase 7: Validação e Testes**
  - [x] Executar script com diferentes combinações de parâmetros
  - [x] Validar a geração correta do CSV e exibição no console
