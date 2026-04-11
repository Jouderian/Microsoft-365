# Tasks: Importar Grupos de Segurança (Graph)

- [ ] Incluir escopos precisos `-Scopes "Group.ReadWrite.All", "Directory.Read.All"` no connect.
- [ ] Construir o framework base do `importarGruposSeguranca.ps1` adotando a Header `<# .SYNOPSIS ... #>`.
- [ ] Validar a necessidade de `Microsoft.Graph.Groups`.
- [ ] Escrever o laço central de looping via `$csv = Import-Csv ...` com tratativa Try/Catch.
- [ ] Gravar informações no arquivo MD correspondente `docs/importarGruposSeguranca.md`.
- [ ] Ligar a rota na planilha do `readMe.md`.
