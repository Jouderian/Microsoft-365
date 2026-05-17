# validaGPOs.ps1

> **Sinopse**: Auditoria offline de GPOs aplicadas a usuários e OUs no AD DS, com geração de relatório dinâmico em HTML.

## Descrição

Realiza uma auditoria estática e rápida das heranças e dos links efetivos de Group Policy Objects (GPOs) que impactam as Contas de Usuário e suas respectivas Unidades Organizacionais (OUs) no Active Directory. Ele faz a varredura das heranças de OUs e containers (com suporte a fallback para `CN=Users`), cruza permissões e WMI Filters nas GPOs, calcula um score (0-100) para cada link com base em vulnerabilidades ou desativações, e gera um relatório moderno estilo "tech" em formato HTML de alta legibilidade.

A evolução do script garante o funcionamento de forma **100% autônoma e independente** (sem dependências de importações externas) e elimina parâmetros mortos ouplacebos de RSoP remotos, focando na excelência e velocidade offline.

## Detalhes
- **Autor Original**: Felipe Aquino
- **Data de Criação**: 05/04/2026
- **Versão Atual**: 02 (17/05/2026)
- **Saídas**:
  - Relatório HTML interativo com filtros dinâmicos (`GPO_Audit_Report.html`) na mesma pasta do script.
  - Arquivo de log persistente de execução (`validaGPOs_execution.log`) na mesma pasta do script.

## Parâmetros
- `-searchBase`: Caminho LDAP Distinguished Name (DN) inicial para a varredura no AD DS (padrão: raiz do domínio atual).
- `-includeUsersSample`: Switch opcional que ativa a exibição de uma amostra lazy de usuários correspondentes na listagem de OUs do HTML final.
- `-usersSampleSize`: Tamanho da amostra de usuários a ser exibida (padrão: 10).
- `-logPath`: Caminho absoluto ou relativo para a gravação física do log de auditoria (padrão: `validaGPOs_execution.log` local).

## Módulos / Dependências
O script valida e instala interativamente de forma local as dependências de RSAT necessárias para execução:
- **`ActiveDirectory`**: Coleta de domínios, OUs e usuários.
- **`GroupPolicy`**: Leitura de links de GPOs, heranças, permissões e status.
