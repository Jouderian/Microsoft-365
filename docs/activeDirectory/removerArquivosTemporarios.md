# removerArquivosTemporarios.ps1

> **Sinopse**: Script de limpeza de disco corporativo otimizado para reduzir o espaço ocupado na máquina local.

## Descrição
Limpa arquivos temporários, caches e outros resíduos de lixo eletrônico presentes no sistema operacional e em **TODOS os perfis de usuários em 'C:\Users'**.

O alcance da limpeza abrange:
- Pastas temporárias globais e exclusivas de usuário
- Caches de navegadores (Chrome, Edge, Firefox)
- Caches das miniaturas (Thumbnails) e ícones corrompidos do Explorer
- Logs administrativos e caches do Windows Update
- Lixeira do sistema (Recycle Bin completada)

**Resiliência**: O script implementa proteção inteligente anti-deadlock (Timeout programado em Background Job de 7 minutos) para contornar processos críticos que negam fechamento como o *wuauserv*, não congelando a interface.

## Parâmetros
- **`-MostrarLogTerminal`** *(Switch)*: Ao ser chamado durante a invocação do script (`.\removerArquivosTemporarios.ps1 -MostrarLogTerminal`), ativa a saída interativa colorida ecoando todo o passo-a-passo no console. O padrão é salvar silenciosamente.

## Detalhes
- **Autor**: Felipe Jesus
- **Colaborador**: Jouderian Nobre
- **Versão Atual**: 04 (13/04/26) - Refatoração para múltiplos usuários em C:\Users, mitigação assíncrona (Timeout do WinUpdate em Job) e introdução de exibição via console.
- **Privilégios**: Requer execução como `Administrador` (UAC).
- **Saída Log**: Persistido em `$env:TEMP\Limpeza_Disco.log`.

## Módulos / Dependências
- Nenhum módulo externo (Comandos embutidos do Windows PowerShell 5.1+).
