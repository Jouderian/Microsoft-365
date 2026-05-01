# ativarAutoArquivamento.ps1

> **Sinopse**: Ativa o autoarquivamento das caixas postais

## Descrição
O script se conecta ao ambiente do Microsoft 365, busca todas as caixas postais (Usuários e Compartilhadas) existentes e ativa o autoarquivamento das caixas que ainda não possuem o recurso habilitado.

## Detalhes
- **Autor**: Jouderian Nobre
- **Versão Atual**: 05 (01/05/26) - Expansão para incluir caixas compartilhadas e melhora na validação de status
- **Saída**: Arquivo de log com o histórico das ações. Exemplo: `autoArquivamento_MAI26.txt`

## Módulos / Dependências
- ExchangeOnlineManagement
