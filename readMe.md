# Repositório de Scripts do Microsoft 365

Este repositório contém uma coleção de utilitários em PowerShell voltados para o gerenciamento, manutenção e extração de relatórios dos serviços de Active Directory, Exchange Online, EntraID (Graph) e Microsoft Teams.

## ⚖️ Licenciamento

Este software e seus códigos associados estão licenciados sob a **PolyForm Noncommercial License 1.0.0**. 

- **Uso Livre**: Você pode utilizar, modificar e distribuir o código para fins **não comerciais** (uso educacional, pessoal, ou de experimentação).
- **Citação**: É obrigatório manter os avisos de direitos autorais originais e **citar a fonte** caso incorpore o código.
- **Restrição Comercial**: É **proibido** usar os scripts com finalidades comerciais ou integrá-los de forma corporativa para lucro sem aprovação formal prévia.

Para ver os termos na íntegra, consulte o arquivo `LICENSE` na raiz do repositório.

---

> [!NOTE]
> **Metodologia de Manutenção**
> Para mais detalhes sobre as regras de arquitetura *Agent-Flywheel* deste projeto, ou para ver o status dos planos de desenvolvimento e aprovações, consulte o plano mestre de arquitetura em `.agents/specs/systemArchitecture/plan.md`.

---

## Scripts — Pasta `exchangeOnline`

Scripts focados em gerenciamento de caixas de correio, auditorias de fluxo de e-mails, políticas de autoarquivamento, retenção (litígio) e listas de distribuição no Exchange Online.

| Script | Descrição |
|--------|-----------|
| [`analisarAutoExpansaoCaixaPostal.ps1`](docs/exchangeOnline/analisarAutoExpansaoCaixaPostal.md) | Audita o Archive e a Auto-Expanding Archive das caixas postais no Exchange Online. |
| [`analiseConfiguracoesDeSeguranca.ps1`](docs/exchangeOnline/analiseConfiguracoesDeSeguranca.md) | Executa o script Orca que analisa as configurações de recomendação do Microsoft Defender para M365. |
| [`ativarAutoArquivamento.ps1`](docs/exchangeOnline/ativarAutoArquivamento.md) | Ativa de forma massiva o autoarquivamento das caixas postais. |
| [`ativarLitigio.ps1`](docs/exchangeOnline/ativarLitigio.md) | Script para ativar a retenção de litígio nas caixas postais com licenças: Office 365 E3 e Business Premium. |
| [`importarMembrosListaDeDistribuicao.ps1`](docs/exchangeOnline/importarMembrosListaDeDistribuicao.md) | Importa novos membros para uma lista de distribuição do Exchange. |
| [`liberarBloqueioEmail.ps1`](docs/exchangeOnline/liberarBloqueioEmail.md) | Libera fluxos e status de uma caixa postal bloqueada no Exchange Online. |
| [`listaPastasCaixaPostal.ps1`](docs/exchangeOnline/listaPastasCaixaPostal.md) | Audita o interior de um e-mail específico e gera a listagem de suas pastas. |
| [`listarCaixasComEncaminhamento.ps1`](docs/exchangeOnline/listarCaixasComEncaminhamento.md) | Extrai uma listagem de todas as caixas postais focando em identificar endereços externos de encaminhamento em uso. |
| [`listarCaixasCompartilhadas.ps1`](docs/exchangeOnline/listarCaixasCompartilhadas.md) | Lista somente caixas do tipo SharedMailbox ou quaisquer caixas que tenham permissão de acesso compartilhado e delegados (Full Access/Send As). |
| [`listarCaixasPostais.ps1`](docs/exchangeOnline/listarCaixasPostais.md) | Extrai um inventário mestre de todas as caixas postais (inclui atributos do AD, licenças, métricas de armazenamento de arquivo/primário, gerentes, last sign-in). |
| [`removerEventosCalendario.ps1`](docs/exchangeOnline/removerEventosCalendario.md) | Procura e retira eventos de reuniões problemáticas no calendário de uma caixa postal. |
| [`testarEnvioHVE.ps1`](docs/exchangeOnline/testarEnvioHVE.md) | Testa o envio direto de mensagem usando credencial HVE (High Volume Email) do Exchange Online. |

---

## Scripts — Pasta `entraId`

Scripts voltados para a governança do Microsoft Entra ID (Azure AD), manutenção e provisionamento massivo de grupos de segurança puros, controle de licenças de usuários e listagem de privilégios.

| Script | Descrição |
|--------|-----------|
| [`apagarListasSemMembros.ps1`](docs/entraId/apagarListasSemMembros.md) | Apaga fisicamente Listas de Distribuição e Grupos de Segurança M365 (vazios e sem membros). |
| [`importarGruposSeguranca.ps1`](docs/entraId/importarGruposSeguranca.md) | Importa e provisiona Grupos de Segurança puros no Entra ID a partir de um CSV, definindo automaticamente seu proprietário. |
| [`importarMembrosGrupoDeSeguranca.ps1`](docs/entraId/importarMembrosGrupoDeSeguranca.md) | Importa novos membros de um Grupo. |
| [`listarAdministradoresTenant.ps1`](docs/entraId/listarAdministradoresTenant.md) | Lista todos os usuários com papéis administrativos no tenant M365 via Microsoft Graph. |
| [`listarCredenciais.ps1`](docs/entraId/listarCredenciais.md) | Lista e audita credenciais (Secrets e Certificados) das aplicações e service principals no Entra ID. |
| [`listarMembrosDeUmaLista.ps1`](docs/entraId/listarMembrosDeUmaLista.md) | Mostra os usuários contidos em um grupo ou Lista do EntraID (via Microsoft Graph PowerShell). |
| [`listarMembrosListas.ps1`](docs/entraId/listarMembrosListas.md) | Exporta a relação cruzando os membros das Listas do Exchange e de Grupos do M365, incluindo Grupos de Segurança. |
| [`mudarLicencas.ps1`](docs/entraId/mudarLicencas.md) | Faz a manutenção ou permuta em massa nas licenças dos usuários oriundos de um arquivo csv. |
| [`removerDispositivos.ps1`](docs/entraId/removerDispositivos.md) | Remove do EntraID os dispositivos sem uso e obsoletos há mais de 190 dias. |

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
| [`sincronizaAdM365.ps1`](docs/activeDirectory/sincronizaAdM365.md) | Força imediatamente o ciclo de sincronismo Delta entre o Active Directory local e a nuvem. |
| [`testarConexaoLDAP.ps1`](docs/activeDirectory/testarConexaoLDAP.md) | Testa a conexão LDAP com um servidor Active Directory. |
| [`validaGPOs.ps1`](docs/activeDirectory/validaGPOs.md) | Faz auditoria offline de GPOs aplicadas no AD DS com suporte para validação extra através de RSoP das máquinas. |

---

## Scripts — Pasta `intune`

Scripts voltados para gerenciamento de dispositivos móveis e desktops no Microsoft Intune (MDM).

| Script | Descrição |
|--------|-----------|
| [`limparRegistrosIntune.ps1`](docs/intune/limparRegistrosIntune.md) | Verifica e ajusta o serviço dmwappushservice e limpa registros de Enrollments do Intune. |

---

## Scripts — Pasta `suporteUsuario`

Scripts client-side executados no ambiente do usuário final para resolução de problemas e manutenção do ecossistema local.

| Script | Descrição |
|--------|-----------|
| [`limparCacheTeamsOutlook.ps1`](docs/suporteUsuario/limparCacheTeamsOutlook.md) | Limpa o cache de todas as versões do Microsoft Teams (clássico e novo) e Outlook para o usuário do Windows, de forma parametrizada. |

---

## Arquivos de Suporte e Biblioteca Core

Estes arquivos residem na raiz do repositório por serem compartilhados ou servirem de biblioteca matriz de funções de uso geral.

| Arquivo | Descrição |
|---------|-----------|
| [`bibliotecaDeFuncoes.ps1`](docs/bibliotecaDeFuncoes.md) | Biblioteca matriz de funções de uso geral para centralizar recursos nos demais scripts. |
| `SkuDataComplete.csv` | Tabela de referência com os SKUs e nomes amigáveis das licenças do Microsoft 365, utilizada internamente para obter as descrições de licenciamento. |
