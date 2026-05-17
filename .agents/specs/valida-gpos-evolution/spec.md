---
description: Especificação funcional para a evolução e refatoração do script validaGPOs.ps1
---

# Especificação Funcional — Evolução do `validaGPOs.ps1`

## 1. Visão Geral e Objetivos

O script [`validaGPOs.ps1`](/activeDirectory/validaGPOs.ps1) é um utilitário desenvolvido originalmente por **Felipe Aquino** em **Abr/26**, cujo objetivo é auditar os *links* e a herança de *GPOs* aplicados no *Active Directory Domain Services* (AD DS), gerando um relatório em HTML.

Esta evolução visa:
1. **Remover Parâmetros Mortos de RSoP:** Limpar a interface e o código do script retirando os switches e timeouts associados a uma validação de RSoP remota que não possui implementação lógica por trás, focando o script 100% em uma auditoria offline de altíssima velocidade.
2. **Independência Absoluta:** Permitir que o script rode de forma isolada em qualquer máquina ou Controlador de Domínio sem depender de importação de bibliotecas externas.
3. **Otimização de Performance no AD:** Reescrever a lógica de coleta de usuários/OUs para que seja extremamente leve, com carregamento sob demanda (*lazy loading*) e sem estouro de memória em domínios grandes.
4. **Padronização e Governança:** Adequar todas as variáveis e parâmetros do script para o padrão **camelCase** obrigatório do repositório, inserir o cabeçalho padrão de ajuda baseado em comentários, incorporar logs de execução locais persistentes (`.log`) e enriquecer a página de documentação [`validaGPOs.md`](/docs/activeDirectory/validaGPOs.md).

---

## 2. Atores e Responsabilidades

* **Autor Original:** Felipe Aquino (criação estrutural e engine de auditoria de herança de GPO).
* **Colaborador / Evolução:** Jouderian Nobre (manutenção, refatoração de performance, portabilidade e governança).
* **Operador (Administrador de AD/M365):** Executa o script no PowerShell para obter um status de conformidade rápida de heranças de GPOs do domínio.

---

## 3. Escopo Funcional (In/Out)

### O que está no escopo (IN):
- Limpeza dos parâmetros de RSoP e pré-teste e das respectivas menções no script.
- Renomeação de todas as variáveis e parâmetros de PascalCase para camelCase.
- Criação de uma função interna e autônoma de logs (`Grava-LogLocal`) que suporta console colorido e escrita em arquivo de log (`validaGPOs_execution.log`) de forma simultânea.
- Criação de um validador interno de dependências (`Verifica-ModuloLocal`) com suporte para instalação interativa de módulos RSAT necessários (`ActiveDirectory` e `GroupPolicy`).
- Otimização do `Get-ADUser` para trazer apenas dados mínimos (`DistinguishedName` e `Enabled`), reduzindo em até 95% o tráfego de rede do AD.
- Consulta sob demanda (*lazy loading*) de amostras de usuários, apenas para as OUs especificadas, se a opção de amostra estiver ativa.
- Correção e enriquecimento do Comment-Based Help no topo do script com informações de autoria (Felipe Aquino), criação (Abr/26), histórico de alteração e descrição de funcionamento.
- Atualização completa do arquivo de documentação complementar em [`docs/activeDirectory/validaGPOs.md`](/docs/activeDirectory/validaGPOs.md).

### O que está fora do escopo (OUT):
- Validação remota de computadores via WMI, WinRM ou execução ativa do utilitário `gpResult` (funcionalidade RSoP removida).
- Acoplamento com a [`bibliotecaDeFuncoes.ps1`](/bibliotecaDeFuncoes.ps1).

---

## 4. Critérios de Aceitação

1. O script roda de forma **autônoma** (zero importações externas) e gera o relatório HTML perfeitamente no caminho especificado.
2. O script gera um arquivo de log físico `.log` correspondente em cada execução, registrando síncronamente cada etapa da auditoria offline.
3. Não existem variáveis ou parâmetros expostos em **PascalCase** no escopo do script (exceto variáveis intrínsecas do sistema ou propriedades de objetos retornados por cmdlets do AD).
4. O cabeçalho Comment-Based Help está devidamente preenchido apontando o autor original como Felipe Aquino e a data de criação como 05/04/2026.
5. A documentação em `docs/activeDirectory/validaGPOs.md` está totalmente detalhada, contendo sinopse descritiva real e dependências de módulos listadas.
