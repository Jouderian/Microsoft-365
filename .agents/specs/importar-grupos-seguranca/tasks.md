# Tasks: Importar Grupos de Segurança (Graph)

- [X] Incluir escopos precisos `-Scopes "Group.ReadWrite.All", "Directory.Read.All"` no connect.
- [X] Construir o framework base do `importarGruposSeguranca.ps1` adotando a Header `<# .SYNOPSIS ... #>`.
- [X] Validar a necessidade de `Microsoft.Graph.Groups`.
- [X] Escrever o laço central de looping via `$csv = Import-Csv ...` com tratativa Try/Catch.
- [X] Gravar informações no arquivo MD correspondente `docs/importarGruposSeguranca.md`.
- [X] Ligar a rota na planilha do `readMe.md`.
