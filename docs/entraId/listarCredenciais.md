# Listar Credenciais do Entra ID (`listarCredenciais.ps1`)

Este script mapeia e lista todas as credenciais (Client Secrets e Certificados) associadas aos aplicativos (*App Registrations*) e *Enterprise Applications* (*Service Principals*) no Entra ID. O objetivo principal é identificar expirações próximas e prevenir interrupções de serviços.

## Detalhes do Script
- **Caminho:** `entraId/listarCredenciais.ps1`
- **Autor:** Jouderian Nobre
- **Data de Criação:** 04/07/2026
- **Versão:** 01 (04/07/26) - Versão inicial guiada por SDD

## Parâmetros

| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `-TipoAplicacao` | `[string]` | Não | Define o escopo da busca. Valores aceitos: `AppRegistrations`, `EnterpriseApps` ou `Ambos` (Padrão: `Ambos`). |
| `-DiasParaExpirar` | `[int]` | Não | Se informado, filtra e lista apenas credenciais que expiram no intervalo (hoje até *X* dias) ou que já expiraram. |

## Saída do Script
O script gera objetos customizados com as propriedades:
- `AppType`: Tipo da aplicação ("appRegistration" ou "enterpriseApp").
- `AppName`: Nome da aplicação.
- `AppId`: Client ID da aplicação.
- `Owners`: E-mails/Nomes dos proprietários (separados por vírgula).
- `CredentialType`: `Secret` ou `Certificate`.
- `CredentialName`: Display name da credencial.
- `StartDate`: Data de criação/início da validade (`dd-MM-yy`).
- `EndDate`: Data de expiração da credencial (`dd-MM-yy`).
- `DaysRemaining`: Dias restantes até a expiração (valores negativos se já expirados).

O script grava automaticamente o resultado em CSV delimitado por ponto e vírgula (`;`) com codificação UTF-8 no seguinte caminho: `$env:ONEDRIVE\Documentos\WindowsPowerShell\credenciaisEntraID.csv`.

## Módulos Necessários
- `Microsoft.Graph.Authentication`
- `Microsoft.Graph.Applications`

## Como Executar
```powershell
# Listar tudo na tela e salvar em CSV no OneDrive automaticamente
.\entraId\listarCredenciais.ps1

# Listar apenas App Registrations que expiram nos próximos 30 dias e atualizar o CSV
.\entraId\listarCredenciais.ps1 -TipoAplicacao AppRegistrations -DiasParaExpirar 30
```
