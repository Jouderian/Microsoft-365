# testarConexaoLDAP.ps1

> **Sinopse**: Testar a conexão LDAP com um servidor Active Directory

## Descrição
Script de utilidade em PowerShell.

## Detalhes
- **Autor**: Vanderson Hay (Original), Jouderian Nobre (Evolução)
- **Versão Atual**: 02 (01/07/25) - Jouderian Nobre: Melhoria para solicitar as informações do usuário e tratar erros
- **Saída**: Informações exibidas no console se foi possível conectar ao servidor LDAP e autenticar o usuário com sucesso.

## Módulos / Dependências
- **System.DirectoryServices** (usado internamente via .NET)
