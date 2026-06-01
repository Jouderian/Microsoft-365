# atualizarCredenciaisAD.ps1

> **Sinopse**: Script para atualizar os dados das credenciais no Active Directory com base na planilha QLP (Quadro de Lotação de Pessoal) do RH.

## Descrição
O script realiza a leitura de uma planilha do Excel contendo o Quadro de Lotação de Pessoal (QLP) fornecido pelo departamento de Recursos Humanos, processa as informações e atualiza automaticamente os atributos correspondentes das contas de usuário no Active Directory local (como departamento, cargo, gerente, centro de custo, etc.). Contas desabilitadas ou bloqueadas são desconsideradas para garantir a integridade dos dados e o desempenho do sincronismo.

## Detalhes
- **Autor**: Jouderian Nobre
- **Versão Atual**: 8 (07/05/24) - Ajuste para melhorar o tratamento de erros e rodar no servidor
- **Entrada**: Planilha Excel contendo os dados de lotação (`C:\ScriptsRotinas\atualizaCredenciaisAD\QLP_<Versao>.xlsx`).
- **Saída**: Arquivo de log em formato CSV (`C:\ScriptsRotinas\atualizaCredenciaisAD\Logs\syncQLP_<Data_Hora>.csv`) com o resumo das atualizações.

## Módulos / Dependências
- **ActiveDirectory**: Módulo do Windows PowerShell para administração do AD.
- **ImportExcel**: Módulo necessário para ler arquivos XLSX diretamente sem a necessidade do Microsoft Excel instalado.
- **bibliotecaDeFuncoes.ps1**: Biblioteca interna de funções comuns do repositório.
