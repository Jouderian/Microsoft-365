---
description: Plano de implementação detalhado para mapeamento de credenciais do Entra ID
---

# Plano de Implementação: Listar Credenciais do Entra ID

Este plano detalha o design técnico para a construção do script `listarCredenciais.ps1` no repositório sob a pasta `entraId/`, em conformidade com as regras do projeto e SDD.

## 1. Arquitetura do Script

O script será executado localmente ou em esteiras de automação, consumindo o SDK do PowerShell `Microsoft.Graph.Applications` (`Microsoft.Graph` v2).

```
[Operador/Automation]
         │
         ▼
 ┌──────────────┐
 │ . biblioteca │  (Importação de C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1)
 └──────┬───────┘
        │
        ▼
 ┌─────────────┐
 │ Connect-Mg* │  (Autenticação utilizando escopos adequados)
 └──────┬──────┘
        │
        ▼
┌───────────────────────┐
│ listarCredenciais.ps1 │
└──────┬─────────────┬──┘
       │             │
       ▼ (AppRegs)   ▼ (EnterpriseApps)
┌────────────┐ ┌─────────────┐
│  Get-MgApp │ │ Get-MgServP │
└──────┬─────┘ └──────┬──────┘
       │              │
       ▼ (Owners)     ▼ (Filtro Microsoft / Managed Identity)
┌──────────────┐      │
│ Get-MgAppOwn │      ▼ (Owners)
└──────┬───────┘ ┌────────────────┐
       │         │ Get-MgServPOwn │
       │         └──────┬─────────┘
       │                │
       └───────┬────────┘
               │
               ▼
┌───────────────────────────┐
│ Mapeamento de Credenciais │ (Cálculo de expiração, DaysRemaining)
└──────┬────────────────────┘
       │
       ├─► [Console Output] (Format-Table / Out-GridView / Objects)
       │
       └─► [CSV Export] (Export-Csv)
```

## 2. Decisões Técnicas

### 2.1 Autenticação e Escopos
* **Biblioteca:** Importação da biblioteca comum através do caminho padrão:
  ```powershell
  . "C:\ScriptsRotinas\bibliotecas\bibliotecaDeFuncoes.ps1"
  ```
* **Autenticação:** O script validará o módulo e fará a conexão conforme o padrão dos outros scripts do repositório:
  ```powershell
  VerificaModulo -NomeModulo "Microsoft.Graph.Applications" -MensagemErro "Modulo Microsoft.Graph.Applications ausente no console."
  try {
    Connect-MgGraph -Scopes "Application.Read.All" -NoWelcome -ErrorAction Stop
  } catch {
    Write-Host "Erro ao conectar no Microsoft Graph: $($_.Exception.Message)" -ForegroundColor Red
    Exit 1
  }
  ```
  Ao finalizar o processamento, executará o `Disconnect-MgGraph` para encerrar a sessão de forma limpa.

### 2.2 Coleta de Dados e Paginação
* Utilizar `-All` nos cmdlets `Get-MgApplication` and `Get-MgServicePrincipal` para garantir que todos os registros do tenant sejam obtidos de forma paginada automaticamente pelo SDK.

### 2.3 Filtragem de Ruído (Service Principals)
* Para focar apenas em credenciais gerenciadas manualmente, os *Service Principals* serão filtrados:
  * Excluir `ServicePrincipalType -eq 'ManagedIdentity'` (Identidades Gerenciadas que rotacionam automaticamente).
  * Excluir aplicativos da Microsoft (onde o `AppOwnerOrganizationId` corresponde ao ID da Microsoft `f8c544b2-5c81-438b-b40b-41da1a550342` ou pelo `PublisherName -eq 'Microsoft Services'`).
  * Filtrar SPs onde as tags indiquem integração implícita que não requer manutenção.

### 2.4 Extração de Credenciais
* **App Registrations:**
  * Secrets: Propriedade `.PasswordCredentials` (contém `KeyId`, `DisplayName`, `StartDateTime`, `EndDateTime`).
  * Certificados: Propriedade `.KeyCredentials` (contém `KeyId`, `DisplayName`, `StartDateTime`, `EndDateTime`, `Usage`).
* **Service Principals:**
  * Secrets: Propriedade `.PasswordCredentials`.
  * Certificados: Propriedade `.KeyCredentials`.

### 2.5 Tratamento de Proprietários (Owners)
* Para cada aplicativo, buscar owners usando `Get-MgApplicationOwner -ApplicationId $app.Id` ou `Get-MgServicePrincipalOwner -ServicePrincipalId $sp.Id`.
* Consolidar os nomes ou e-mails dos proprietários em uma única string separada por vírgulas (ex: `"User A, User B"`).
* Se a busca falhar ou o aplicativo não possuir owners, retornar `"Sem Proprietário"`.

### 2.6 Formatação do Output
Será gerado um array de objetos customizados (`[PSCustomObject]`) com as seguintes propriedades:
* `AppType`: Tipo de aplicação ("appRegistration" ou "enterpriseApp").
* `AppName`: Nome de exibição da aplicação.
* `AppId`: ID do aplicativo (Client ID).
* `Owners`: Nomes/emails dos proprietários separados por vírgula.
* `CredentialType`: `"Secret"` ou `"Certificate"`.
* `CredentialName`: Display Name/Hint da credencial.
* `StartDate`: Data de início (`dd-MM-yy`).
* `EndDate`: Data de expiração (`dd-MM-yy`).
* `DaysRemaining`: Quantidade de dias restantes até expirar.

### 2.7 Desempenho e Robustez
* **Tratamento de erros individual:** A busca de proprietários de cada aplicativo deve rodar dentro de um bloco `try-catch`. Falhas na busca de um app individual (por exemplo, permissão ou app deletado recentemente) não podem parar o script.
* **Exportação CSV:** O script grava o relatório automaticamente no arquivo `$arquivo` (`$env:ONEDRIVE\Documentos\WindowsPowerShell\credenciaisEntraID.csv`). Utilizar o cmdlet `Export-Csv -Path $arquivo -NoTypeInformation -Encoding utf8 -Delimiter ";"` de forma eficiente.

## 3. Plano de Testes

* **Cenário 1: Listagem Completa (`-TipoAplicacao Ambos`)**
  * Verificar se lista tanto App Registrations quanto Enterprise Apps no console.
* **Cenário 2: Filtro por Tipo de Aplicativo**
  * Testar `-TipoAplicacao AppRegistrations` e `-TipoAplicacao EnterpriseApps` separadamente.
* **Cenário 3: Alerta de Expiração (`-DiasParaExpirar 30`)**
  * Verificar se apenas credenciais vencidas ou com expiração próxima de 30 dias são retornadas.
* **Cenário 4: Exportação**
  * Validar se a exportação para o caminho indicado em `-ExportarCsv` gera o arquivo formatado corretamente.
