# Regras Gerais do Projeto

Estas regras garantem a qualidade do código, manutenção segura e aderência aos padrões globais para este ambiente do OneDrive / Scripts Microsoft 365.

## Regras Inegociáveis

1.  **Idioma:** Entregar sempre as respostas e documentações em português do Brasil.
2.  **Autorização prévia:** Solicite autorização expressa ao usuário antes de realizar alterações no código (`.ps1`) ou nos arquivos sensíveis de configuração.
3.  **Segurança e Credenciais:** Absolutamente proibido o armazenamento de chaves de acesso, tokens ou senhas em *hardcode*. Variáveis de ambiente ou parâmetros interativos devem ser preferidos.
4.  **Gerenciamento de Versão (GIT/File System):** Evite comandos destrutivos. `git reset --hard`, `git clean -fd`, `rm -rf` são **PROIBIDOS**.
5.  **Preservação de Histórico de Arquivos:** Não crie múltiplos arquivos semelhantes ou renomeados (como `.old`, `.new`, `v2`, etc.). Edite o arquivo alvo original quando solicitado (após autorização).
6.  **Consciência Multiagente:** Respeite as edições de outros agentes. Nunca sobrescreva ou reverta alterações sem consultar o plano arquitetural.
7.  **Sincronia do Ciclo SDD:** Após a conclusão de qualquer nova feature, mova as tarefas pendentes do `todo.md` para o `todoDone.md`. Toda alteração deve convergir com a fonte de verdade em `systemArchitecture/plan.md`.
