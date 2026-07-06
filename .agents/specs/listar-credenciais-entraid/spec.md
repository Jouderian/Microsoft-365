---
description: Especificação para o script de auditoria e listagem de credenciais (Secrets e Certificados) do Entra ID
---

# Especificação: Listar Credenciais do Entra ID

> [!NOTE]
> Documento de especificação (SDD) para o script `listarCredenciais.ps1`.

## 1. Visão Geral
* **Funcionalidade:** Auditoria de Credenciais do Entra ID.
* **Objetivo:** Mapear e listar todas as credenciais (Client Secrets e Certificados) associadas aos aplicativos (*App Registrations* e *Enterprise Applications*) no Entra ID, visando identificar proativamente vencimentos próximos e prevenir interrupções de serviço.
* **Ator Principal:** Operador de TI / Administrador M365 (via PowerShell local ou automação).

## 2. Requisitos Funcionais
1. **Conexão:** O script deve validar a conexão com o Microsoft Graph, requerendo os escopos adequados.
2. **Coleta de Dados:** 
   * Deve recuperar todos os *App Registrations* (`Get-MgApplication`) e *Enterprise Applications* (`Get-MgServicePrincipal`).
   * Extrair as coleções de `PasswordCredentials` e `KeyCredentials`.
   * Buscar os proprietários (Owners) de cada aplicativo (`Get-MgApplicationOwner` e `Get-MgServicePrincipalOwner`).
    * **Filtro de Ruído:** Para Service Principals, implementar filtragem que exclua aplicativos autogerenciáveis ou nativos da Microsoft (1st-party apps e Managed Identities) para focar apenas em credenciais que exigem renovação manual pelo administrador.
3. **Parâmetros de Entrada:**
   * `-TipoAplicacao` `[string]`: (Opcional) Define o escopo da busca. Valores aceitos: `AppRegistrations`, `EnterpriseApps` ou `Ambos` (Padrão: `Ambos`).
   * `-DiasParaExpirar` `[int]`: Se informado, filtra e lista apenas credenciais que expiram no intervalo (hoje até *X* dias) ou que já expiraram.
   * *Nota:* O script exporta automaticamente o resultado para `$env:ONEDRIVE\Documentos\WindowsPowerShell\credenciaisEntraID.csv`.
4. **Formatação de Saída:** O objeto resultante de cada credencial listada deve conter:
   * `AppType` (Tipo da Aplicação: `appRegistration` ou `enterpriseApp`)
   * `AppName` (Nome da Aplicação)
   * `AppId` (Client ID)
   * `Owners` (Nomes/E-mails dos proprietários)
   * `CredentialType` (Secret ou Certificate)
   * `CredentialName` (Display Name da credencial, se existir)
   * `StartDate` (Data de criação/início)
   * `EndDate` (Data de expiração)
   * `DaysRemaining` (Dias restantes até expirar; pode ser negativo se já expirou)

## 3. Requisitos Não Funcionais
1. **Segurança (Zero Senhas):** O script nunca deve possuir chaves de acesso ou *secrets* em *hardcode*. A responsabilidade pela autenticação (`Connect-MgGraph`) fica a cargo do chamador do script.
2. **Permissões Mínimas:** Requer escopo `Application.Read.All` no Graph API.
3. **Idempotência & Resiliência:** 
   * A coleta é apenas leitura, não alterando estado.
   * Exceções ao ler um App específico devem ser tratadas (`try/catch`), logadas, e o loop deve prosseguir sem falhar a execução geral do script.
4. **Padrões de Código:**
   * Nomenclatura em *camelCase* (`listarCredenciais.ps1`, `$diasParaExpirar`).
   * Verbos completos do PowerShell, proibido o uso de aliases implícitos (`%`, `?`).
   * Inclusão do cabeçalho de documentação padronizado (`<# .SYNOPSIS #>`).
   * Idioma principal: pt-BR.

## 4. Critérios de Aceitação
* [ ] O script extrai com sucesso tanto Secrets quanto Certificados.
* [ ] A saída em tela e no CSV formata as datas de forma legível e calcula corretamente o campo `DaysRemaining`.
* [ ] O uso de `-DiasParaExpirar` exibe apenas credenciais com vencimento no limiar especificado ou já vencidas.
* [ ] O script implementa o filtro em *Service Principals* para evitar alertas de *secrets* autogerenciados pela Microsoft.
* [ ] Erros isolados não derrubam a execução do restante do mapeamento.
