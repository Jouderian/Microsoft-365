# limparCacheTeamsOutlook.ps1

> **Sinopse**: Limpa o cache das aplicações Microsoft Teams (clássico e novo) e do Outlook (clássico e novo) para o usuário atual, oferecendo controle parametrizado.

## Descrição
Este script é uma ferramenta de manutenção pontual executada no contexto do usuário para resolver problemas comuns de lentidão, sincronização de perfil, travamento ou erros de autenticação no Microsoft Teams e Microsoft Outlook. Ele fecha os aplicativos selecionados com segurança, remove os diretórios de cache temporários e os reinicia em seguida.

## Parâmetros
- `-somenteTeams`: Restringe a execução exclusivamente à finalização, limpeza e reabertura do Microsoft Teams.
- `-somenteOutlook`: Restringe a execução exclusivamente à finalização, limpeza e reabertura do Microsoft Outlook.
- *(Sem parâmetros)*: Executa a rotina completa para ambas as aplicações por padrão.

## Detalhes
- **Autor**: Felipe Aquino
- **Versão Atual**: 03
- **Criação**: 17/03/26
- **Modificação**: 17/05/26
- **Saída**: Logs estruturados em tempo real no console.

## Módulos / Dependências
- Nenhum módulo ou permissão administrativa externa é necessário.
