# Spec: Importar Membros do Grupo de Segurança (Graph)

## O que é
Este documento mapeia os requisitos do novo fluxo do script `importarMembrosGrupoDeSeguranca.ps1`, que abandonará a dependência de listas `.txt` puras (`Get-Content`) e migrará para processamento dinâmico via CSV (`Import-Csv`), em conjunto à biblioteca moderna do **Microsoft Graph**.

## Atores
- **Operador/Admin de TI**: Inicia as adições em massa com base na planilha CSV de demanda do negócio.

## Requisitos
A nova especificação requer:
- Leitura de um arquivo no formato delimitado CSV (idealmente vírgula ou ponto-e-vírgula resolvido via rotina padrão).
- O arquivo deve processar duas colunas essenciais: `nomeGrupo` e `eMailUsuario`.
- Os módulos necessários são `Microsoft.Graph.Authentication`, `Microsoft.Graph.Groups` e `Microsoft.Graph.Users`.

## Critérios de Aceitação
- [X] Autenticar eficientemente iterando pelas colunas via `import-csv`.
- [X] Buscar adequadamente o **ID do Grupo** na API do Graph usando o texto da coluna `nomeGrupo`.
- [X] Buscar o **ID do Usuário** (Membro) através de `eMailUsuario`.
- [X] Persistir o vínculo membro com `New-MgGroupMember`.
- [X] Evitar abortos em caso de membros ou grupos não listados (aproveitar Try/Catch em alto nível na iteração).
