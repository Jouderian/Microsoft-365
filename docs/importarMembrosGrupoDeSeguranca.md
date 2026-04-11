# Como usar o `importarMembrosGrupoDeSeguranca.ps1`

Este script atua na gestão em massa de Grupos de Segurança do Entra ID, inserindo dinamicamente múltiplos usuários em múltiplos grupos mediante um único lote (CSV) utilizando a API do Microsoft Graph.

## Formato do Arquivo de Entrada (CSV)
Crie o arquivo sob a estrutura `OneDrive\Documentos\WindowsPowerShell\membrosGruposSeguranca.csv` (variável mapeável no topo do script).

**Estrutura Obrigatória:**
```csv
nomeGrupo,eMailUsuario
Diretoria,marcos.diretor@dominio.com.br
Vendas Regionais,lucas.vendedor@dominio.com.br
Diretoria,lucia.ceo@dominio.com.br
Centro de Custos,marcos.diretor@dominio.com.br
```
> [!IMPORTANT]
> - Mantenha fidedignamente o nome `nomeGrupo` e `eMailUsuario` na primeira linha.
> - O separador nativo assumido pelo script na variável delimitadora é `;` (ponto e vírgula), formato padrão do Excel em pt-BR. Caso utilize a formatação nativa inglesa (US), modifique a variável no script para a vírgula.
> - Certifique-se de que o campo `nomeGrupo` **exatamente condiz** com o *DisplayName* exposto no Painel de Admin, do contrário o Graph lançará advertência *não encontrado*.

## O Que Esperar
O processo vai:
1. Validar a conexão aos módulos `Microsoft.Graph` essenciais (Autenticação, Grupos e Usários).
2. Solicitar Logon com permissões de Leitura e Gravação (`Group.ReadWrite.All`).
3. Percorrer o CSV descobrindo em tempo real os IDs de cada Ator (ID do Usuário + ID do Grupo respectivo daquela linha).
4. Proceder com o vínculo daquele usuário diretamente na API ativando `$DirectoryObjectId`.
5. Salvar todo o rastro das aprovações/falhas em tela no sub-diretório WindowsPowerShell com nome: `importarMembros_AnoMesDia.txt`.

---
*Manutenção realizada focando modernização completa de `AzureAD` *(obsoleto)* para *Graph*. Guideline **SDD**.*
