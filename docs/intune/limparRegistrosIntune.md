# limparRegistrosIntune.ps1

## Sinopse
Verifica e ajusta o serviço dmWapPushService e limpa registros de Enrollments do Intune.

## Descrição
Este script assegura que o serviço dmWapPushService esteja em Automatic (sem trigger) e rodando.
Em seguida, exclui as subchaves em `HKLM:\SOFTWARE\Microsoft\Enrollments` e ajusta a flag `MmpEnrollmentFlag`.
Por fim, executa um `gpupdate /force` para forçar a atualização de políticas.

## Detalhes
- **Autor:** Jouderian Nobre
- **Versão:** 02 (03/06/26) - Refatorado para seguir os padrões SDD de Clean Code e modularização.
- **Saída:** Console
