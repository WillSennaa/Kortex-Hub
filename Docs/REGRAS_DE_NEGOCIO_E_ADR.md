# 📐 Regras de Negócio e Decisões de Arquitetura — Kortex Hub

## 1. Regras de Negócio (RN)

As Regras de Negócio definem como o sistema deve se comportar e quais restrições se aplicam a cada módulo.

### 1.1 Conta e Autenticação

* **RN01 — Unicidade de Conta:** O e-mail cadastrado deve ser único na plataforma, sem diferenciar maiúsculas de minúsculas.
* **RN02 — Escopo do Banco em Nuvem:** O Supabase (PostgreSQL) armazena **apenas** dados de conta e autenticação, avisos globais, feedbacks e a chave de backup. Nenhum dado dos módulos (Finanças, Treinos, Tarefas e futuros) é enviado ao Supabase.
* **RN03 — Criptografia de Senhas:** A senha jamais é gravada em texto puro; a API em C# aplica hash seguro com *salt* (BCrypt ou Argon2).
* **RN04 — Sessão e Uso Offline:** O primeiro login exige internet. Depois dele, o app funciona offline e a sessão local permanece até o logout. A API emite um token de acesso JWT de curta duração e um refresh token, renovados automaticamente quando houver conexão.
* **RN05 — Confirmação de Alteração de Credenciais:** Troca de senha, troca de e-mail e recuperação de senha exigem um código numérico enviado ao e-mail. O código é de uso único, expira em 15 minutos e é invalidado após 5 tentativas erradas.
* **RN06 — Perfis de Acesso:** O sistema diferencia Usuários Comuns de Administradores (ADMs). Os ADMs podem emitir avisos globais, responder feedbacks e cadastrar outros ADMs. Os dados dos módulos de cada usuário ficam no dispositivo dele e não são acessíveis ao ADM.
* **RN07 — Login por E-mail e Senha:** A autenticação no Kortex Hub é feita por e-mail e senha.

### 1.2 Dashboard e Calendário Central

* **RN08 — Consolidação Temporal Unificada:** O Dashboard exibe de forma integrada o resumo financeiro, o treino agendado e as atividades da data selecionada.
* **RN09 — Filtragem Dinâmica por Data:** Selecionar um dia no carrossel/calendário superior atualiza todos os blocos (Finanças, Treino e Tarefas) para aquela data.

### 1.3 Módulo de Finanças

* **RN10 — Lançamento Financeiro:** Toda transação (Receita ou Despesa) deve estar vinculada a uma Conta/Carteira e a uma Categoria, e o tipo da transação deve ser igual ao tipo da categoria.
* **RN11 — Subcategorias:** Uma categoria pode ter subcategorias de um único nível (ex.: Alimentação › Delivery), sempre do mesmo tipo da categoria-pai. Nos relatórios, os valores das subcategorias somam na categoria-pai.
* **RN12 — Status de Pagamento:** Uma transação pode estar **pendente** (prevista para uma data) ou **efetivada** (paga ou recebida, com data de efetivação).
* **RN13 — Cálculo do Saldo:** O saldo de cada conta é calculado dinamicamente: saldo inicial + receitas efetivadas − despesas efetivadas + transferências recebidas − transferências enviadas. Transações pendentes não alteram o saldo. O saldo global é a soma das contas não arquivadas.
* **RN14 — Transferência Entre Contas:** A transferência é um registro próprio, que debita a conta de origem e credita a de destino ao mesmo tempo. Ela não é receita nem despesa, não entra nos gráficos por categoria e não altera o saldo global. Origem e destino devem ser contas diferentes.
* **RN15 — Personalização Visual:** Categorias financeiras e contas devem ter um código de ícone e uma cor HEX (`#RRGGBB`).
* **RN16 — Integridade de Categorias e Contas:** Não é permitido excluir categorias ou contas que tenham lançamentos vinculados. O usuário deve reatribuir os lançamentos ou arquivar a categoria/conta.
* **RN17 — Distribuição Percentual de Gastos:** O resumo financeiro exibe a proporção de despesas por categoria no mês em gráfico de pizza/rosca.
* **RN18 — Precisão Monetária:** Valores monetários são armazenados como números inteiros em centavos e formatados em reais apenas na interface.

### 1.4 Módulo de Treinos

* **RN19 — Rotina × Sessão:** A **rotina** é o planejamento (exercícios, séries, repetições e carga-alvo). A **sessão** é cada execução real do treino, com as séries efetivamente feitas. O histórico de cargas pertence às sessões, então editar ou excluir uma rotina nunca altera o histórico.
* **RN20 — Estrutura da Rotina:** Uma rotina é composta por exercícios ordenados, e cada um especifica séries, repetições, carga (kg) e tempo de descanso.
* **RN21 — Carga Opcional:** A carga pode ser nula ou zero em exercícios com peso do próprio corpo ou alongamentos.
* **RN22 — Pastas de Rotinas:** As rotinas podem ser agrupadas em pastas temporais ou temáticas (ex.: "Jan - Mar/2026").
* **RN23 — Agenda e Status do Dia:** Cada rotina pode ser agendada para dias da semana. Para uma data, o treino agendado aparece como **Concluído** (há sessão finalizada naquele dia), **Pendente** (dia atual ou futuro sem sessão) ou **Faltou** (dia passado sem sessão).
* **RN24 — Recordes e Série Anterior:** O recorde de carga é a maior carga em uma série concluída. O recorde de volume é a maior soma de carga × repetições de um exercício numa única sessão. A coluna "Anterior" mostra a mesma série da última sessão finalizada com aquele exercício. Esses valores são calculados, nunca digitados.
* **RN25 — Peso Corporal:** O usuário pode registrar o peso corporal por data e definir uma meta, exibidos no gráfico de evolução.

### 1.5 Módulo de Tarefas / Atividades

* **RN26 — Status de Conclusão:** Tarefas concluídas podem ser desmarcadas a qualquer momento e voltam ao status pendente.
* **RN27 — Pastas de Tarefas:** As tarefas pertencem a pastas (ex.: "Faculdade", "Trabalho", "Casa"). Todo usuário possui a pasta padrão "Tarefas Pessoais", criada no primeiro acesso, que não pode ser excluída. Para excluir uma pasta, suas tarefas devem antes ser movidas.
* **RN28 — Níveis de Prioridade:** As tarefas aceitam as prioridades Baixa, Média (padrão) e Alta, usadas para ordenação e destaque visual.
* **RN29 — Progresso Diário:** O cabeçalho do módulo exibe a proporção de tarefas concluídas entre as que têm prazo no dia (ex.: "3 de 5 concluídas — 60%"), desconsiderando arquivadas e excluídas.

### 1.6 Persistência e Backup

* **RN30 — Operação Offline-First:** Todas as operações dos módulos funcionam sem internet. Só ações de conta (cadastro, primeiro login, troca de credenciais), envio de feedback, leitura de avisos e backup exigem conexão.
* **RN31 — Backup na Conta Google do Usuário:** Para fazer backup, o usuário conecta voluntariamente uma conta Google nas configurações do app. A conexão pode ser desfeita a qualquer momento. O backup de todos os módulos é salvo no Google Drive do próprio usuário, que mantém a propriedade dos dados.
* **RN32 — Backup Cifrado:** O arquivo de backup é sempre cifrado antes de sair do dispositivo. Ele só pode ser restaurado pela mesma conta Kortex que o gerou, com o usuário autenticado.
* **RN33 — Exclusão Lógica:** Registros dos módulos são excluídos logicamente (data de exclusão preenchida), preservando a integridade do histórico e permitindo desfazer a ação.

---

## 2. Registro de Decisões de Arquitetura (ADR)

### ADR-01: Arquitetura Híbrida Offline-First (Supabase + SQLite)

**Status:** Aprovado

**Contexto:** Armazenar transações, treinos e tarefas em nuvem traria custos crescentes de infraestrutura, inviáveis na fase de MVP.

**Decisão:** O Supabase (PostgreSQL) guarda apenas conta, autenticação, avisos, feedbacks e a chave de backup (RN02). Os dados dos módulos ficam no SQLite local do dispositivo.

**Consequências:**
* **Positivas:** Custo de banco zerado no plano gratuito do Supabase, resposta instantânea do app e maior privacidade.
* **Negativas/Mitigações:** Não há sincronização automática entre aparelhos. A mitigação é o backup/restauração via Google Drive (ADR-06). As colunas de auditoria (ADR-09) deixam o caminho aberto para uma sincronização futura.

### ADR-02: Autenticação via Web API própria em C# / ASP.NET Core

**Status:** Aprovado

**Contexto:** O Supabase oferece recursos nativos como Supabase Auth e Row Level Security (RLS).

**Decisão:** Usar o Supabase apenas como banco PostgreSQL remoto, acessado pela Web API em C# (.NET). Regras de negócio, hash de senhas e emissão de tokens JWT ficam na API.

**Consequências:**
* **Positivas:** Sem dependência das ferramentas nativas do Supabase (vendor lock-in). Migrar para outro PostgreSQL exige só trocar a connection string.
* **Negativas/Mitigações:** A API precisa de hospedagem própria (avaliar planos gratuitos de Render, Railway ou Azure App Service).

### ADR-03: Modularização do Protótipo de Alta Fidelidade no Figma

**Status:** Aprovado

**Contexto:** O design do app passa por avaliações contínuas de UI/UX (como a revisão de cores com o professor) sem poder atrasar os testes de usabilidade.

**Decisão:** Usar um Guia de Estilos (Design System) no Figma, centralizando paleta de cores e tipografia em componentes reutilizáveis.

**Consequências:**
* **Positivas:** Permite alterar toda a paleta do protótipo em instantes, sem quebrar os fluxos nem adiar os testes de usabilidade.

### ADR-04: UUID v4 como Chave Primária

**Status:** Aprovado

**Contexto:** Chaves inteiras autoincrementáveis (AUTO_INCREMENT / SERIAL) geram conflitos quando registros são criados offline.

**Decisão:** Todas as tabelas (Supabase e SQLite) usam UUID v4 como chave primária. No SQLite, o UUID é gerado pelo app e armazenado como `TEXT`; no PostgreSQL, usa-se `gen_random_uuid()`.

**Consequências:**
* **Positivas:** IDs únicos gerados no próprio dispositivo, sem risco de colisão em backups e restaurações.
* **Negativas/Mitigações:** Pequeno aumento de armazenamento por registro, insignificante para o volume do app.

### ADR-05: Row Level Security Ativado sem Policies (Bloqueio da API Pública)

**Status:** Aprovado (substitui a decisão anterior de manter o RLS desativado)

**Contexto:** No Supabase, tabelas do schema `public` ficam expostas automaticamente pela API REST (PostgREST) para quem tiver a URL do projeto e a chave `anon`. Essa chave é pública por design. Com o RLS desativado, qualquer pessoa poderia ler a tabela `usuarios`, inclusive `senha_hash`. Não basta "não expor a chave no app".

**Decisão:**
1. Ativar o RLS em **todas** as tabelas **sem criar nenhuma policy**. Sem policy, o acesso é negado aos papéis `anon` e `authenticated`.
2. Revogar os privilégios desses papéis sobre as tabelas (`REVOKE ALL ... FROM anon, authenticated`).
3. A Web API em C# conecta pela connection string com o usuário dono das tabelas (`postgres`), que não é afetado pelo RLS.
4. A connection string e a chave `service_role` ficam apenas em variáveis de ambiente do servidor, nunca no app mobile nem no Git.

**Consequências:**
* **Positivas:** A API pública do Supabase fica inutilizável para essas tabelas, sem nenhuma mudança no código C# / Entity Framework Core.
* **Negativas/Mitigações:** Toda tabela nova precisa receber `ENABLE ROW LEVEL SECURITY`. Isso faz parte do DoD de qualquer migração no Supabase.

### ADR-06: Backup Cifrado no Google Drive do Usuário

**Status:** Aprovado

**Contexto:** Os dados dos módulos existem só no dispositivo. É preciso permitir troca de aparelho e restauração sem armazenar esses dados em servidor próprio.

**Decisão:**
* O usuário conecta uma conta Google para o backup em Configurações → Backup (RN31).
* O app usa OAuth do Google com o escopo mínimo necessário: `drive.appdata` (pasta oculta do app) ou `drive.file` (só arquivos criados pelo app). O escopo exato deve ser confirmado na documentação do Google ao implementar.
* O módulo em React Native exporta o banco SQLite, cifra o arquivo com AES-256-GCM (ADR-11) e envia para o Drive do usuário.
* Os tokens OAuth ficam no armazenamento seguro do Android (`expo-secure-store` / Keystore), nunca no SQLite nem no Supabase.

**Consequências:**
* **Positivas:** Conformidade com a LGPD e privacidade, sem servidor para armazenar dados pessoais.
* **Negativas/Mitigações:** O app precisa de um projeto no Google Cloud com tela de consentimento OAuth configurada.

### ADR-07: Usuários em Tabela Única (Single Table Inheritance)

**Status:** Aprovado

**Contexto:** O sistema possui dois perfis (Comum e Administrador) com alguns atributos e permissões distintos.

**Decisão:** Usar uma única tabela `usuarios` com a coluna discriminadora `tipo_usuario` e campos condicionais (`data_nascimento`, `nivel_permissao`). Uma `CHECK constraint` garante que `nivel_permissao` exista só para ADMIN.

**Consequências:**
* **Positivas:** O login consulta uma única tabela.
* **Negativas/Mitigações:** Colunas que podem ficar nulas, controladas pela constraint `ck_usuarios_sti`.

### ADR-08: Valores Monetários e de Peso como Inteiros

**Status:** Aprovado

**Contexto:** O SQLite não possui tipo decimal exato. Com `REAL` (ponto flutuante), `0.1 + 0.2` resulta em `0.30000000000000004`, e somas de muitos lançamentos acumulam erro.

**Decisão:** Dinheiro em `INTEGER` de **centavos** (`valor_centavos`) e peso/carga em `INTEGER` de **gramas** (`carga_gramas`, `peso_gramas`). A conversão para "R$ 12,50" ou "32,5 kg" acontece só na interface.

**Consequências:**
* **Positivas:** Somas e saldos exatos. Comparações de recordes sem erro de arredondamento.
* **Negativas/Mitigações:** Toda entrada e saída de valor passa por funções utilitárias de conversão, que devem ter testes unitários.

### ADR-09: Migrações Versionadas e Colunas de Auditoria no Banco Local

**Status:** Aprovado

**Contexto:** O banco SQLite vive no celular do usuário. Quando um módulo novo for lançado (listas de compras, notas, cálculo alimentar), o banco já existente precisa ser atualizado sem perder dados.

**Decisão:**
* A versão do schema fica em `PRAGMA user_version`. Cada mudança é um script de migração numerado (`001_inicial.sql`, `002_lista_compras.sql`…), executado em ordem na abertura do app, dentro de uma transação.
* As tabelas principais possuem `criado_em`, `atualizado_em` e `excluido_em` (soft delete, RN33).
* Datas são gravadas como texto ISO-8601 em UTC.

**Consequências:**
* **Positivas:** Atualizações seguras do app. Base pronta para sincronização futura (resolver conflitos pelo `atualizado_em`) e para desfazer exclusões.
* **Negativas/Mitigações:** Todas as consultas precisam filtrar `excluido_em IS NULL`. Isso deve ficar centralizado na camada de repositório.

### ADR-10: Sessão com JWT de Curta Duração e Refresh Token

**Status:** Aprovado

**Contexto:** O app é offline-first, mas a autenticação depende da API. Um JWT expirado não pode impedir o usuário de usar o app sem internet (ex.: na academia).

**Decisão:**
* A API emite um **token de acesso JWT** (validade sugerida: 15 minutos) e um **refresh token** (validade sugerida: 30 dias), guardado no SecureStore do app.
* No banco fica só o hash do refresh token (`refresh_tokens`). A cada uso ele é rotacionado: o antigo é revogado e aponta para o novo.
* Os dados locais **não** dependem do JWT. O token só é exigido nas chamadas à API. Offline, o app abre normalmente com a sessão local.
* O logout revoga o refresh token e limpa o SecureStore.

**Consequências:**
* **Positivas:** Uso offline ilimitado após o primeiro login. Se um refresh token for reutilizado (sinal de roubo), a API revoga toda a cadeia.
* **Negativas/Mitigações:** Se o usuário ficar mais de 30 dias offline, terá de fazer login de novo ao precisar da API. Os dados locais continuam acessíveis.

### ADR-11: Custódia da Chave de Backup

**Status:** Aprovado

**Contexto:** O backup é cifrado (RN32). Se a chave fosse derivada da senha, uma troca ou recuperação de senha tornaria os backups antigos irrecuperáveis.

**Decisão:**
* Na primeira ativação do backup, a API gera uma chave AES-256 aleatória para o usuário. A API a cifra com uma chave-mestra do servidor (variável de ambiente) e guarda em `chaves_backup`.
* O app recebe a chave pela API (usuário autenticado), guarda no SecureStore e a usa para cifrar e decifrar o arquivo.
* O arquivo cifrado fica no Google Drive do usuário. A chave fica no Supabase. Um sem o outro é inútil.

**Consequências:**
* **Positivas:** Troca e recuperação de senha não afetam os backups. O Google não consegue ler o conteúdo, e o Supabase não tem os dados.
* **Negativas/Mitigações:** Não é criptografia ponta a ponta: quem controla o servidor **e** obtém o arquivo do Drive poderia decifrá-lo. Para o MVP, esse risco é aceito e documentado. A chave-mestra deve ser rotacionável (coluna `versao`).
