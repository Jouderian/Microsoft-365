# Especificação: Refatoração da Extração e Limpeza de Listas e Grupos

## O Quê
Refatoraremos as lógicas de extração e limpeza de membros das Listas de Distribuição (Exchange) e Grupos de Segurança (EntraID/Graph). 
1. `listarMembrosListas.ps1` receberá um parâmetro para escolher entre "Apenas Listar" (padrão) e "ListarEApagar" grupos sem nenhum membro (tanto DLs quanto SSGs via Graph).
2. Criação de um novo script `apagarListasSemMembros.ps1` que varre as listas e deleta diretamente as vazias do ambiente sem exportar logs detalhados de membros.

## Por Quê
1. Mitigar o risco de exclusão acidental de listas importantes ao usar o script principal de listagem rotineiramente.
2. Fornecer uma trilha limpa de manutenção delegável providenciando uma ferramenta direcionada unicamente para exclusão (SSG e DLs vazias) com alto ganho de I/O.

## Critérios de Aceite
- [ ] O script `listarMembrosListas.ps1` deve assumir "ApenasListar" por padrão, parando de apagar DLs vazias.
- [ ] O script `listarMembrosListas.ps1` quando invocado com `ListarEApagar` deve remover DLs vazias *e também Grupos de Segurança vazios*.
- [ ] O novo script `apagarListasSemMembros.ps1` conecta ao Exchange e MsGraph, rastreia e remove Listas e Grupos de Segurança sem impacto local (exceto logs), reportando "Excluída".
