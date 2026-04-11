# Apagar Listas/Grupos sem Membros 

## Finalidade do Script
Apaga fisicamente Listas de Distribuição (Exchange Online) e Grupos de Segurança M365 (Microsoft Graph) do ambiente que **não possuam membros vinculados**.
Concebido para varrer de forma rapida as Listas e os Grupos de Segurança sem envolver tarefas assíncronas complexas com CSV, garantindo a exclusão definitiva dos itens vazios.

## Como as execuções ocorrem
Apenas Listas do Exchange e EntraID Groups do tipo `SecurityEnabled=$true` onde a propriedade `Count` ou `Length` dos usuários matriculados for equivalente a zero serão removidos.

O script conta com uma barreira local de sincronização de AD: grupos atrelados por OnPremisesSync são sumariamente ignorados do processo de exclusão de acordo com as restrições corporativas de `Auth/Sync` on-premises.

## Variáveis Iniciais (Ambiente)
- Nenhum pacote .csv é importado.
- Os logs operacionais são descarregados instantaneamente em `$env:ONEDRIVE\Documentos\WindowsPowerShell\apagadasVazias_Data_Hora.txt` sem acúmulo de dados confidenciais ou trânsito externo.

## Autenticação
O msGraph irá requisitar os scopes: `"Group.ReadWrite.All"`, e `"GroupMember.Read.All"`.
O Exchange Online exigirá sua rotina tradicional de admin.

**Autor**: Jouderian Nobre
