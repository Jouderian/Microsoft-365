# Repositório de Scripts do Microsoft 365

Este repositório contém uma coleção de utilitários em PowerShell voltados para o gerenciamento, manutenção e extração de relatórios dos serviços de Active Directory, Exchange Online, EntraID (Graph) e Microsoft Teams.

## Resumo dos Scripts

Abaixo você encontra a lista de todos os `scripts` e a descrição da sua principal função:

| Script | Descrição |
|--------|-----------|
| `analisarAutoExpansaoCaixaPostal.ps1` | Audita o Archive e a Auto-Expanding Archive das caixas postais no Exchange Online. |
| `analiseConfiguracoesDeSeguranca.ps1` | Executa o script Orca que analisa as configurações de recomendação do Microsoft Defender para M365. |
| `ativarAutoArquivamento.ps1` | Ativa de forma massiva o autoarquivamento das caixas postais. |
| `ativarLitigio.ps1` | Script para ativar a retenção de litígio nas caixas postais com licenças: Office 365 E3 e Business Premium. |
| `bibliotecaDeFuncoes.ps1` | Biblioteca matriz de funções de uso geral para centralizar recursos nos demais scripts. |
| `importarMembrosGrupoDeSeguranca.ps1` | Importa novos membros de um Grupo. |
| `importarMembrosListaDeDistribuicao.ps1` | Importa novos membros para uma lista de distribuição do Exchange. |
| `liberarBloqueioEmail.ps1` | Libera fluxos e status de uma caixa postal bloqueada no Exchange Online. |
| `limpaCacheTeamsOutlook.ps1` | Limpa o cache de todas as versões do Microsoft Teams (clássico e novo) e Outlook para o usuário do Windows, encerrando e reabrindo os aplicativos. |
| `limparCacheTeams.ps1` | Script focado em limpar apenas o cache do Microsoft Teams para resolver problemas de desempenho e autenticação. |
| `listaPastasCaixaPostal.ps1` | Audita o interior de um e-mail específico e gera a listagem de suas pastas. |
| `listarCaixasComEncaminhamento.ps1` | Extrai uma listagem de todas as caixas postais focando em identificar endereços externos de encaminhamento em uso. |
| `listarCaixasCompartilhadas.ps1` | Lista somente caixas do tipo SharedMailbox ou quaisquer caixas que tenham permissão de acesso compartilhado e delegados (Full Access/Send As). |
| `listarCaixasPostais.ps1` | Extrai um inventário mestre de todas as caixas postais (inclui atributos do AD, licenças, métricas de armazenamento de arquivo/primário, gerentes, last sign-in). |
| `listarCaixasPostaisNOVO.ps1` | Inventário de mailboxes otimizado para Windows PowerShell 5.1 priorizando chamadas no Graph Reports (maior velocidade em tenants enormes). |
| `listarMembrosDeUmaLista.ps1` | Mostra os usuários contidos em um grupo ou Lista do EntraID (via Microsoft Graph PowerShell). |
| `listarMembrosListas.ps1` | Exporta a relação cruzando os membros das Listas do Exchange e de Grupos do M365, incluindo Grupos de Segurança. |
| `mudarLicencas.ps1` | Faz a manutenção ou permuta em massa nas licenças dos usuários oriundos de num arquivo csv. |
| `removerDispositivos.ps1` | Remove do EntraID os dispositivos sem uso e obsoletos há mais de 190 dias. |
| `removerEventosCalendario.ps1` | Procura e retira eventos de reuniões problemáticas no calendário de uma caixa postal. |
| `sincroniza_AD_M365.PS1` | Força imediatamente o ciclo de sincronismo Delta entre o Active Directory local e a nuvem. |
| `testarEnvioHVE.ps1` | Testa o envio direto de mensagem usando credencial HVE (High Volume Email) do Exchange Online. |
| `validaGPOs.ps1` | Faz auditoria offline de GPOs aplicadas no AD DS com suporte para validação extra através de RSoP das máquinas. |

---

> [!NOTE]
> **Metodologia de Manutenção**
> Para mais detalhes sobre as regras de arquitetura *Agent-Flywheel* deste projeto, ou para ver o status dos planos de desenvolvimento e aprovações, consulte o arquivo `.agents/BEADS.md`.
