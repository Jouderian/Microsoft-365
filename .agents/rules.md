# Regras e Diretrizes para Agentes

Estas regras garantem a qualidade do código, manutenção segura e aderência aos padrões globais solicitados pelo usuário para este ambiente.

**Regras Inegociáveis:**
1.  **Idioma:** Entregar sempre as respostas e documentações em português do Brasil.
2.  **Autorização prévia:** Solicite autorização expressa ao usuário antes de realizar alterações no código (`.ps1`) ou nos arquivos sensíveis de configuração.
3.  **Segurança e Credenciais:** Absolutamente proibido o armazenamento de chaves de acesso, tokens ou senhas em *hardcode*. Variáveis de ambiente ou parâmetros interativos devem ser preferidos.
4.  **Clean Code:** Siga os Princípios de design e desenvolvimento de código limpo (Clean Code) como base em todos os scripts PowerShell (Modularização, tratamento assertivo de erros, clareza).
5.  **Nomenclatura:** Utilize Notação Camelo (camelCase) para instanciar/nomear variáveis e scripts.
6.  **Gerenciamento de Versão (GIT):** Evite comandos destrutivos. `git reset --hard`, `git clean -fd`, `rm -rf` são **PROIBIDOS**.
7.  **Preservação de Histórico de Arquivos:** Não crie múltiplos arquivos semelhantes ou renomeados (como `.old`, `.new`, `v2`, etc.). Edite o arquivo alvo original quando solicitado (após autorização).
8.  **Validação de Front-End *(se aplicável)*:** Após editar qualquer HTML/JS/CSS presente no projeto, abra o arquivo localmente no formato navegador e valide visualmente antes de finalizar a tarefa.
9.  **Consciência Multiagente:** Respeite as edições de outros agentes. Nunca sobrescreva, desfaça ou reverta alterações documentadas em `.agents/BEADS.md` por agentes pares sem verificar meticulosamente o contexto prévio.
10. **Metodologia Flywheel (BEADS):** Leia o arquivo `.agents/BEADS.md` para entender as necessidades pendentes antes de iniciar o plano de ação de qualquer nova tarefa. Atualize a seção adequada quando sua tarefa for validada com sucesso pelo usuário.
