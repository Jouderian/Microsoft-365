# Padrões de Código, Estilo e Nomenclatura

> Padrões específicos de PowerShell e convenções estruturais adotadas nestes scripts estipuladas ao longo das sessões.

1.  **Nomenclatura (camelCase):** Este projeto convencionou o uso obrigatório de Notação Camelo (`camelCase`) para instanciar/nomear variáveis (`$minhaVariavel`), nomes de arquivos (`meuScript.ps1`) e arquivos/diretórios dos agentes SDD.
2.  **Clean Code:** Siga os Princípios de design e desenvolvimento de código limpo (Modularização, tratamento assertivo de erros com try/catch, clareza).
3.  **Cabeçalho Padrão:** Todo script `.ps1` deve usar o bloco rigoroso `<# .SYNOPSIS ... #>` conforme definido em `.agents/workflows/newScript.md`.
4.  **Alias PowerShell:** É terminantemente proibido o uso de aliases implícitos e não mapeáveis como `%` e `?`. O uso de cmdlets originais e completos é exigido na base para clareza (ex: `ForEach-Object`, `Where-Object`).
