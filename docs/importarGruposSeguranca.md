# Como usar o `importarGruposSeguranca.ps1`

Este script facilita a criação em lote de Grupos de Segurança **(Security Groups)** dentro do Entra ID (Azure AD), alocando de forma automatizada o Proprietário (Owner) correspondente com base no Microsoft Graph.

## Formato do Arquivo de Entrada (CSV)
Crie um arquivo `.csv` na seguinte trilha: `OneDrive\Documentos\WindowsPowerShell\gruposSeguranca.csv` (ou altere a variável no script).

**Estrutura Obrigatória:**
```csv
Nome,Descricao,eMailProprietário
Meu Novo Grupo,Acesso aos arquivos confidenciais do RH,gerente.rh@dominio.com.br
Vendas Seguras,Grupo sem email para o time da ponta,diretor.vendas@dominio.com.br
```
> [!IMPORTANT]
> - Mantenha fidedignamente o nome das colunas `Nome`, `Descricao`, `eMailProprietário` na primeira linha.
> - O separador nativo assumido pelo interpretador na linha de `$delimitador` é `,` (vírgula), se o seu Excel local salvar com ponto-e-vírgula (`;`), pode ser preciso substituir essa vírgula no PS1, ou abrir o CSV em um Bloco de Notas para normalizar.
> - Certifique-se de que a UPN informada no Owner seja um usuário real válido e existente na nuvem de identidade do Tenant.

## O Que Esperar
O processo vai:
1. Validar a conexão aos módulos `Microsoft.Graph.Authentication`, `Microsoft.Graph.Groups` e `Microsoft.Graph.Users`.
2. Solicitar uma janela interativa de Login M365 (caso falte a sessão autorizada).
3. Percorrer o CSV extraindo os caracteres indesejáveis/espaços do `Nome` para derivar internamente o `MailNickname`.
4. Disparar a criação via `New-MgGroup` ativando o modo *Security Enabled*.
5. Promover o email correspondente como *Proprietário Ativo* do Grupo gerado.
6. Gravar um log detalhado chamado `importarGruposSeguranca_AnoMesDia.txt` no seu WindowsPowerShell Documents.

---
*Documentação processada de acordo com as regras de desenvolvimento do framework SDD.*
