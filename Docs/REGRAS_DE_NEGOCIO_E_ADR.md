1. Regras de Negócio (RN)

    As Regras de Negócio definem como o sistema deve se comportar operacionalmente e quais restrições devem ser applied nos módulos.

1.1 Autenticação e Conta de Usuário

    RN01 — Unicidade de Conta: O e-mail cadastrado deve ser único na plataforma.
    RN02 — Escopo de Armazenamento de Login: O banco de dados remoto em nuvem (Supabase/PostgreSQL) deve armazenar unicamente credenciais e dados essenciais de autenticação (usuarios), garantindo custo zero e privacidade dos dados operacionais do usuário.
    RN09 — Criptografia de Senhas: A senha do usuário jamais deve ser gravada em texto puro; deve-se aplicar algoritmo de hash seguro com salt (ex: BCrypt/Argon2) gerenciado pela API em C#.
    RN10 — Controle de Sessão via Token JWT: O acesso às funcionalidades do app exige validação de um token JWT válido emitido pelo backend em C#.
    RN11 — Confirmação de Alteração de Credenciais: Troca de senha ou e-mail exige o envio e validação de um código numérico enviado ao e-mail cadastrado antes de ser efetivada no banco.
    RN23 — Perfis e Níveis de Acesso: O sistema deve diferenciar Usuários Comuns de Administradores (ADMs), permitindo aos ADMs gerenciar categorias globais e emitir avisos ou relatórios de plataforma.

1.2 Dashboard e Calendário Central

    RN12 — Consolidação Temporal Unificada: O Dashboard principal deve exibir de forma integrada o resumo financeiro, o treino programado e as atividades pendentes da data selecionada.
    RN13 — Filtragem Dinâmica por Data: A seleção de um dia no carrossel/calendário superior deve atualizar em tempo real todos os blocos de dados (Finanças, Treino e Tarefas) correspondentes àquela data específica.

1.3 Módulo de Finanças

    RN03 — Lançamento Financeiro: Toda transação financeira (Receita ou Despesa) deve obrigatoriamente estar vinculada a uma Conta/Carteira e a uma Categoria.
    RN04 — Cálculo do Saldo: O saldo exibido no Dashboard e na tela de Finanças deve ser calculado dinamicamente com base nas Entradas menos as Saídas registradas.
    RN14 — Transferência Entre Contas: A operação de transferência entre contas deve debitar o valor na conta de origem e creditar simultaneamente na conta de destino, sem alterar o saldo global do usuário.
    RN15 — Personalização Visual de Categorias e Contas: Categorias financeiras e contas/carteiras devem obrigatoriamente conter um código de ícone e um código de cor HEX (#HEX) associados para identificação na interface.
    RN16 — Integridade de Categorias: Não é permitido excluir categorias que possuam transações vinculadas sem antes reatribuí-las ou confirmar o arquivamento.
    RN24 — Distribuição Percentual de Gastos: O resumo financeiro deve calcular e exibir graficamente a proporção de despesas por categoria no mês (gráfico de pizza/rosca).

1.4 Módulo de Treinos

    RN05 — Isolamento de Histórico de Carga: O registro de carga, séries e repetições pertence ao histórico individual da execução do treino (itens_exercicios), preservando o catálogo global de exercícios intacto.
    RN17 — Estrutura Hierárquica de Treino: Uma rotina de treino é composta por um conjunto de exercícios, onde cada exercício especifica a quantidade de séries, repetições, carga (kg) e tempo de descanso.
    RN18 — Carga Opcional: O campo de carga em um exercício pode aceitar valores nulos ou zero para atividades que utilizem o peso do próprio corpo ou alongamentos.
    RN19 — Organização por Pastas de Rotinas: As rotinas de treino podem ser agrupadas em pastas temporais ou temáticas (ex: "Jan - Mar/2026") para facilitar a organização.

1.5 Módulo de Tarefas / Atividades

    RN06 — Status de Conclusão: Tarefas concluídas podem ser desmarcadas a qualquer momento, retornando ao status pendente.
    RN20 — Agrupamento por Pastas: Atividades podem pertencer a pastas específicas (ex: "Faculdade", "Trabalho", "Casa") ou à lista geral "Tarefas Pessoais".
    RN21 — Níveis de Prioridade: As tarefas devem aceitar os níveis de prioridade Baixa, Média e Alta para ordenação e destaque visual no aplicativo.
    RN22 — Progresso Diário de Conclusão: O cabeçalho do módulo de Atividades deve exibir dinamicamente o percentual e a proporção de tarefas concluídas no dia (ex: "3 de 5 concluídas - 60%").

1.6 Persistência e Backup

    RN07 — Operação Offline-First: Todas as operações do usuário (Finanças, Treinos e Tarefas) devem funcionar normalmente sem conexão com a internet.
    RN08 — Propriedade dos Dados do Usuário: O backup dos dados operacionais é de responsabilidade do próprio usuário via exportação/importação de arquivo cifrado integrado ao seu Google Drive pessoal.

2. Registro de Decisões de Arquitetura (ADR - Architecture Decision Records)

    ADR-01: Estratégia de Arquitetura Hybrid/Offline-First com Supabase e Banco Local

    Status: Aprovado

    Contexto:
        Armazenar todas as transações financeiras, treinos e tarefas em um banco de dados em nuvem traria custos crescentes de infraestrutura e hospedagem inviáveis para a fase de MVP e validação de mercado.

    Decisão:
        Adotar o modelo Offline-First. O Supabase (PostgreSQL) será utilizado estritamente para dados de autenticação e conta do usuário (usuarios). Os dados operacionais cotidianos ficarão armazenados localmente no dispositivo (via SQLite/WatermelonDB).

    Consequências:
        Positivas: Custo de infraestrutura zerado (R$ 0,00) no plano grátis do Supabase, altíssima velocidade de resposta do app e maior privacidade para o usuário.

        Negativas/Mitigações: A sincronização entre múltiplos dispositivos do mesmo usuário não é automática; a mitigação é a funcionalidade de backup/restauração via Google Drive.

    ADR-02: Gerenciamento de Autenticação via Web API própria em C# / ASP.NET Core
    
    Status: Aprovado

    Contexto:
        O Supabase oferece recursos nativos como Supabase Auth e Row Level Security (RLS).

    Decisão:
        Utilizar o Supabase puramente como um banco de dados PostgreSQL remoto, conectando através da Web API em C# (.NET). As regras de negócio, hash de senhas e emissão de tokens JWT serão gerenciadas pela própria API em C#.

    Consequências:
        Positivas: Sem dependência severa (vendor lock-in) das ferramentas nativas do Supabase, facilitando a migração para qualquer outro servidor no futuro com apenas a mudança da Connection String.

    ADR-03: Modularização do Protótipo de Alta Fidelidade no Figma
    
    Status: Aprovado

    Contexto:
        O design do app precisa passar por avaliações contínuas de UI/UX (como a revisão de cores com o professor) sem impedir a aplicação dos testes de usabilidade.

    Decisão:
        Utilizar um Guia de Estilos (Design System) no Figma centralizando a paleta de cores e tipografia em componentes reutilizáveis.

    Consequências:
        Positivas: Permite alterar toda a paleta visual do protótipo em instantes com base nos feedbacks do professor, sem quebrar os fluxos nem adiar os testes de usabilidade já agendados.

    ADR-04: Identificadores Únicos Universais (UUID v4) para Entidades
    
    Status: Aprovado

    Contexto:
        Chaves primárias do tipo inteiro autoincrementável (AUTO_INCREMENT / SERIAL) geram conflitos ao criar registros em ambientes offline sem comunicação prévia com o servidor.

    Decisão:
        Todas as tabelas do sistema (tanto na nuvem no Supabase quanto no banco local SQLite) utilizarão UUID v4 de 128 bits como Chave Primária (PK).

    Consequências:
        Positivas: Permite a geração de IDs únicos e seguros diretamente pelo dispositivo móvel no modo offline sem risco de colisão.

        Negativas/Mitigações: Pequeno aumento no consumo de espaço de armazenamento por registro, insignificante perante o volume de dados do app.

    ADR-05: Manutenção de Tabela Sem Row Level Security (RLS) Nativo
    
    Status: Aprovado

    Contexto:
        O Supabase sinaliza a tabela de usuários como UNRESTRICTED caso o recurso de RLS esteja desativado.

    Decisão:
        Manter o RLS desativado no Supabase, pois o acesso ao banco remoto na nuvem será realizado exclusivamente pela Web API em C# ASP.NET Core via String de Conexão com credenciais do servidor, e não por chamadas diretas do aplicativo mobile.

    Consequências:
        Positivas: Simplifica a execução de consultas e comandos SQL via C# / Entity Framework Core sem bloqueios ou regras adicionais do Supabase.

        Negativas/Mitigações: A chave pública 'anon' do Supabase não deve ser exposta no código do aplicativo móvel.

    ADR-06: Portabilidade de Backup via Arquivo Cifrado no Google Drive
    
    Status: Aprovado

    Contexto:
        Como os dados de transações, treinos e tarefas existem apenas no dispositivo local do usuário, é necessário fornecer uma solução segura de troca de aparelho ou restauração.

    Decisão:
        Implementar no React Native um módulo que extrai a base de dados local, criptografa o arquivo e envia para a pasta pessoal do usuário no Google Drive via API oficial do Google.

    Consequências:
        Positivas: Garante a conformidade com a LGPD e privacidade, sem exigir servidores adicionais de armazenamento de dados pessoais.

    ADR-07: Modelagem de Usuários via Single Table Inheritance (STI)
    
    Status: Aprovado

    Contexto:
        O sistema possui dois perfis de usuários (Comum e Administrador) com alguns atributos e permissões distintas.

    Decisão:
        Utilizar uma única tabela de usuários (usuarios) no Supabase contendo a coluna discriminadora tipo_usuario e campos condicionais (como nivel_permissao), em vez de separar em múltiplas tabelas.

    Consequências:
        Positivas: Simplifica a consulta de autenticação no login mantendo apenas uma tabela para verificar credenciais.