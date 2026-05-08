# removerArquivosTemporarios.ps1

> **Sinopse**: Script de limpeza de disco corporativo otimizado para reduzir o espaço ocupado na máquina local.

## Descrição
Limpa arquivos temporários, caches e outros resíduos de lixo eletrônico presentes no sistema operacional e em **TODOS os perfis de usuários em 'C:\Users'**.

O alcance da limpeza abrange:
- Pastas temporárias globais e exclusivas de usuário
- Caches de navegadores (Chrome, Edge, Firefox)
- Arquivos de cache e temporários do Microsoft Teams (Classic e New Teams)
- Caches das miniaturas (Thumbnails) e ícones corrompidos do Explorer
- Logs administrativos e caches do Windows Update
- Lixeira do sistema (Recycle Bin completada)

**Resiliência**: O script implementa proteção inteligente anti-deadlock (Timeout programado em Background Job de 7 minutos) para contornar processos críticos que negam fechamento como o *wuauserv*, não congelando a interface.

## Parâmetros
- **`-MostrarLogTerminal`** *(Switch)*: Ativa a saída interativa colorida no console. Se omitido, os logs são registrados apenas no arquivo.
- **`-NaoFecharTeams`** *(Switch)*: Impede que o script encerre forçosamente o Microsoft Teams. Por padrão, o script fecha o Teams para garantir a limpeza completa do cache.

## Detalhes
- **Autor**: Felipe Jesus
- **Colaborador**: Jouderian Nobre
- **Versão Atual**: 04 (08/05/26) - Inclusão de limpeza de cache do Teams (Classic e New) e introdução do parâmetro `-NaoFecharTeams` para controle de processos.
- **Privilégios**: Requer execução como `Administrador` (UAC).
- **Saída Log**: Persistido em `$env:TEMP\Limpeza_Disco.log`.

## Módulos / Dependências
- Nenhum módulo externo (Comandos embutidos do Windows PowerShell 5.1+).
