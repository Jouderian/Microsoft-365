# Repositório de Scripts do Microsoft 365

Este repositório contém uma coleção de utilitários em PowerShell voltados para o gerenciamento, manutenção e extração de relatórios dos serviços de Active Directory, Exchange Online, EntraID (Graph) e Microsoft Teams.

## Resumo dos Scripts

Abaixo você encontra a lista de todos os `scripts` e a descrição da sua principal função:

| Script | Descrição |
|--------|-----------|
| [`analisarAutoExpansaoCaixaPostal.ps1`](docs/analisarAutoExpansaoCaixaPostal.md) | Audita o Archive e a Auto-Expanding Archive das caixas postais no Exchange Online. |
| [`analiseConfiguracoesDeSeguranca.ps1`](docs/analiseConfiguracoesDeSeguranca.md) | Executa o script Orca que analisa as configurações de recomendação do Microsoft Defender para M365. |
| [`ativarAutoArquivamento.ps1`](docs/ativarAutoArquivamento.md) | Ativa de forma massiva o autoarquivamento das caixas postais. |
| [`ativarLitigio.ps1`](docs/ativarLitigio.md) | Script para ativar a retenção de litígio nas caixas postais com licenças: Office 365 E3 e Business Premium. |
| [`bibliotecaDeFuncoes.ps1`](docs/bibliotecaDeFuncoes.md) | Biblioteca matriz de funções de uso geral para centralizar recursos nos demais scripts. |
| [`importarMembrosGrupoDeSeguranca.ps1`](docs/importarMembrosGrupoDeSeguranca.md) | Importa novos membros de um Grupo. |
| [`importarMembrosListaDeDistribuicao.ps1`](docs/importarMembrosListaDeDistribuicao.md) | Importa novos membros para uma lista de distribuição do Exchange. |
| [`liberarBloqueioEmail.ps1`](docs/liberarBloqueioEmail.md) | Libera fluxos e status de uma caixa postal bloqueada no Exchange Online. |
| [`limpaCacheTeamsOutlook.ps1`](docs/limpaCacheTeamsOutlook.md) | Limpa o cache de todas as versões do Microsoft Teams (clássico e novo) e Outlook para o usuário do Windows, encerrando e reabrindo os aplicativos. |
| [`limparCacheTeams.ps1`](docs/limparCacheTeams.md) | Script focado em limpar apenas o cache do Microsoft Teams para resolver problemas de desempenho e autenticação. |
| [`listaPastasCaixaPostal.ps1`](docs/listaPastasCaixaPostal.md) | Audita o interior de um e-mail específico e gera a listagem de suas pastas. |
| [`listarCaixasComEncaminhamento.ps1`](docs/listarCaixasComEncaminhamento.md) | Extrai uma listagem de todas as caixas postais focando em identificar endereços externos de encaminhamento em uso. |
| [`listarCaixasCompartilhadas.ps1`](docs/listarCaixasCompartilhadas.md) | Lista somente caixas do tipo SharedMailbox ou quaisquer caixas que tenham permissão de acesso compartilhado e delegados (Full Access/Send As). |
| [`listarCaixasPostais.ps1`](docs/listarCaixasPostais.md) | Extrai um inventário mestre de todas as caixas postais (inclui atributos do AD, licenças, métricas de armazenamento de arquivo/primário, gerentes, last sign-in). |
| [`listarCaixasPostaisNOVO.ps1`](docs/listarCaixasPostaisNOVO.md) | Inventário de mailboxes otimizado para Windows PowerShell 5.1 priorizando chamadas no Graph Reports (maior velocidade em tenants enormes). |
| [`listarMembrosDeUmaLista.ps1`](docs/listarMembrosDeUmaLista.md) | Mostra os usuários contidos em um grupo ou Lista do EntraID (via Microsoft Graph PowerShell). |
| [`listarMembrosListas.ps1`](docs/listarMembrosListas.md) | Exporta a relação cruzando os membros das Listas do Exchange e de Grupos do M365, incluindo Grupos de Segurança. |
| [`mudarLicencas.ps1`](docs/mudarLicencas.md) | Faz a manutenção ou permuta em massa nas licenças dos usuários oriundos de num arquivo csv. |
| [`removerDispositivos.ps1`](docs/removerDispositivos.md) | Remove do EntraID os dispositivos sem uso e obsoletos há mais de 190 dias. |
| [`removerEventosCalendario.ps1`](docs/removerEventosCalendario.md) | Procura e retira eventos de reuniões problemáticas no calendário de uma caixa postal. |
| `sincroniza_AD_M365.PS1` | Força imediatamente o ciclo de sincronismo Delta entre o Active Directory local e a nuvem. |
| [`testarEnvioHVE.ps1`](docs/testarEnvioHVE.md) | Testa o envio direto de mensagem usando credencial HVE (High Volume Email) do Exchange Online. |
| [`validaGPOs.ps1`](docs/validaGPOs.md) | Faz auditoria offline de GPOs aplicadas no AD DS com suporte para validação extra através de RSoP das máquinas. |

---

> [!NOTE]
> **Metodologia de Manutenção**
> Para mais detalhes sobre as regras de arquitetura *Agent-Flywheel* deste projeto, ou para ver o status dos planos de desenvolvimento e aprovações, consulte o arquivo `.agents/BEADS.md`.

---

## Scripts — Pasta `activeDirectory`

Scripts voltados para gestão de credenciais, grupos, computadores e operações no Active Directory local.

| Script | Descrição |
|--------|-----------|
| [`ajustarCaixasDivergenciaUPN_SMTP.ps1`](docs/activeDirectory/ajustarCaixasDivergenciaUPN_SMTP.md) | Ajusta as credenciais do AD cujo UPN está divergente do endereço SMTP no atributo `proxyAddresses`. |
| [`ajustarLimiteExclusaoSyncAD.ps1`](docs/activeDirectory/ajustarLimiteExclusaoSyncAD.md) | Ajusta temporariamente o limite de exclusões do Entra Connect Sync e restaura ao final da operação. |
| [`ajustarPaisCredenciaisAD.ps1`](docs/activeDirectory/ajustarPaisCredenciaisAD.md) | Ajusta os atributos País, Apelido e Código do País de todas as credenciais ativas no AD. |
| [`copiarSystemStateAD.ps1`](docs/activeDirectory/copiarSystemStateAD.md) | Realiza cópia de segurança (backup) do System State do Active Directory. |
| [`criarCredenciaisAD.ps1`](docs/activeDirectory/criarCredenciaisAD.md) | Cria usuários em massa no AD com base em um arquivo CSV. |
| [`expirarUsuariosAD.ps1`](docs/activeDirectory/expirarUsuariosAD.md) | Expira ou libera credenciais com base em uma planilha de agendamento. |
| [`listaEventosCredencial.ps1`](docs/activeDirectory/listaEventosCredencial.md) | Localiza eventos de segurança de credenciais no AD (bloqueio, desbloqueio, alteração de senha e mudanças de informações). |
| [`listarComputadoresAD.ps1`](docs/activeDirectory/listarComputadoresAD.md) | Gera a relação de computadores registrados no Active Directory. |
| [`listarCredenciaisAD.ps1`](docs/activeDirectory/listarCredenciaisAD.md) | Gera um arquivo `.csv` com as principais informações dos usuários do AD. |
| [`listarMembrosGrupoAD.ps1`](docs/activeDirectory/listarMembrosGrupoAD.md) | Lista os membros de um grupo do Active Directory. |
| [`mudarCredenciais.ps1`](docs/activeDirectory/mudarCredenciais.md) | Altera o nome da credencial, domínio e endereço de e-mail de um usuário. |
| [`mudarSenhaUsuariosAD.ps1`](docs/activeDirectory/mudarSenhaUsuariosAD.md) | Altera a senha de um usuário específico no AD. |
| [`mudarSenhaUsuariosBloqueadosAD.ps1`](docs/activeDirectory/mudarSenhaUsuariosBloqueadosAD.md) | Altera aleatoriamente a senha dos usuários bloqueados no Active Directory. |
| [`removerArquivosTemporarios.ps1`](docs/activeDirectory/removerArquivosTemporarios.md) | Script de limpeza de disco otimizado para reduzir espaço utilizado em máquinas Windows. |
| [`removerComputadoresAD.ps1`](docs/activeDirectory/removerComputadoresAD.md) | Remove computadores do AD com base em uma lista fornecida. |
| [`removerDominioAD.ps1`](docs/activeDirectory/removerDominioAD.md) | Remove um domínio específico das credenciais no AD. |
| [`testarConexaoLDAP.ps1`](docs/activeDirectory/testarConexaoLDAP.md) | Testa a conexão LDAP com um servidor Active Directory. |

---

## Arquivos de Suporte

| Arquivo | Descrição |
|---------|-----------|
| `SkuDataComplete.csv` | Tabela de referência com os SKUs e nomes amigáveis das licenças do Microsoft 365, utilizada internamente pela função `ObterDescricaoLicenca` da `bibliotecaDeFuncoes.ps1`. |
