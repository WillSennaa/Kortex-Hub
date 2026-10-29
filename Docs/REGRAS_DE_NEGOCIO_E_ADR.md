# 📐 Regras de Negócio e Decisões de Arquitetura — Kortex Hub

## 1. Regras de Negócio (RN)

As Regras de Negócio definem como o sistema deve se comportar e quais restrições se aplicam a cada módulo.

### 1.1 Conta e Autenticação

* **RN01 — Unicidade de Conta:** O e-mail cadastrado deve ser único na plataforma, sem diferenciar maiúsculas de minúsculas.
* **RN02 — Escopo do Banco em Nuvem:** O Supabase (PostgreSQL) armazena **apenas** dados de conta e autenticação, avisos globais, feedbacks e a chave de backup. Nenhum dado dos módulos (Finanças, Treinos, Tarefas e futuros) é enviado ao Supabase.
* **RN03 — Criptografia de Senhas:** A senha jamais é gravada em texto puro; a API em C# aplica hash seguro com *salt* (BCrypt ou Argon2).
* **RN04 — Sessão e Uso Offline:** O primeiro login exige internet. Depois dele, o app funciona offline e a sessão local permanece até o logout. A API emite um token de acesso JWT de curta duração e um refresh token, renovados automaticamente quando houver conexão.
* **RN05 — Confirmação de Alteração de Credenciais:** Troca de senha, troca de e-mail e recuperação de senha exigem um código numérico enviado ao e-mail. O código é de uso único, expira em 15 minutos e é invalidado após 5 tentativas erradas.
* **RN06 — Perfis de Acesso:** O sistema diferencia Usuários Comuns de Administradores (ADMs). O ADM é um usuário completo: usa Finanças, Treinos e Tarefas normalmente, com os próprios dados locais, e além disso pode responder feedbacks, emitir avisos globais e gerenciar outros ADMs (RN41). Os dados dos módulos de cada usuário ficam no dispositivo dele e não são acessíveis ao ADM.
* **RN41 — Área de Administração no Próprio App:** As funções de ADM ficam no mesmo app, sem instalação nem painel separado:
  * **Visibilidade:** o menu lateral mostra a seção "Administração" só quando o perfil do usuário logado é ADMIN. O perfil vem no token de acesso (JWT) emitido pela API.
  * **Segurança:** esconder o menu não é a proteção. Cada endpoint de ADM na API confere o perfil no token e responde `403 Forbidden` para usuários comuns.
  * **Conteúdo:** responder feedbacks, emitir e encerrar avisos globais e gerenciar ADMs. Tudo exige internet (RN30).
  * **Gerenciar ADMs:** um ADM promove uma conta **já existente**, pelo e-mail, a ADM, ou remove o acesso de ADM de outra conta. Não se cria conta nova: a pessoa continua com o mesmo login e os mesmos dados (ADR-07). Sempre deve existir pelo menos um ADM ativo, então o último ADM não pode remover o próprio acesso.
  * **Primeiro ADM:** a conta do dono do projeto é promovida direto no banco (`tipo_usuario = 'ADMIN'` e `nivel_permissao`), uma única vez, na configuração inicial.
  * **Atualização do perfil:** depois de uma promoção ou remoção, o novo perfil vale a partir da próxima renovação do token (no máximo 15 minutos, ADR-10).
* **RN07 — Login por E-mail e Senha:** A autenticação no Kortex Hub é feita por e-mail e senha.
* **RN35 — Proteção contra Força Bruta:** A API limita as tentativas de acesso:
  * **Por conta:** após 5 senhas erradas seguidas, a conta fica bloqueada para login por 15 minutos (`usuarios.bloqueado_ate`). O contador zera no primeiro login certo.
  * **Por endereço IP:** no máximo 10 requisições por minuto nos endpoints de login, cadastro, recuperação de senha e envio de códigos (limitador de taxa do ASP.NET Core). Excedido o limite, a API responde `429 Too Many Requests`.
  * **Mensagens neutras:** login errado responde sempre "E-mail ou senha incorretos", e a recuperação de senha responde sempre "Se o e-mail estiver cadastrado, enviaremos um código", para não revelar quais e-mails existem.* **RN34 — Exclusão de Conta:** O usuário pode excluir a própria conta dentro do app (Configurações → Conta) ou por um link web, sem precisar reinstalar o app. A exclusão exige um código enviado ao e-mail (finalidade `EXCLUIR_CONTA`, mesmas regras da RN05) e é definitiva:
  * **Nuvem:** o registro em `usuarios` é apagado fisicamente e o `ON DELETE CASCADE` remove refresh tokens, códigos, chave de backup e feedbacks. Avisos emitidos por um ADM excluído permanecem, sem autor.
  * **Aparelho:** o app apaga o arquivo `kortex_<usuario_id>.db` (ADR-13) e limpa o SecureStore.
  * **Google Drive:** se houver conta Google conectada, o app apaga o arquivo de backup. Mesmo que ele fique no Drive, não pode mais ser decifrado, porque a chave foi apagada junto com a conta (ADR-11).
  * Desativar (`status = INATIVO`) continua existindo como opção reversível, separada da exclusão.

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
* **RN36 — Despesa Parcelada:** Uma despesa pode ser parcelada em 2 a 48 vezes. O app grava a compra em `parcelamentos` e gera **todas as parcelas de uma vez**, como lançamentos comuns ligados à compra (`parcelamento_id`, `parcela_numero`):
  * **Valor:** o total em centavos é dividido igualmente; a sobra da divisão vai para a 1ª parcela, para a soma bater exatamente (ex.: R$ 100,00 em 3x = 33,34 + 33,33 + 33,33).
  * **Datas:** a 1ª parcela vence na data da compra e as seguintes no mesmo dia dos meses seguintes; quando o dia não existe no mês (ex.: 31), vence no último dia do mês.
  * **Status:** todas nascem pendentes; se "Pago" estiver marcado no registro, só a 1ª nasce efetivada. Cada parcela é paga, editada ou excluída individualmente.
  * **Exclusão:** excluir a compra exclui todas as parcelas.
  * A descrição de cada parcela recebe o sufixo "(n/N)". Só despesas podem ser parceladas.
* **RN37 — Despesa Recorrente:** Uma despesa pode se repetir a cada semana, mês ou ano (ex.: aluguel, assinatura), a partir de uma data de início e, opcionalmente, até uma data de fim. O app guarda a **regra** em `recorrencias` e cria cada ocorrência como lançamento comum (`recorrencia_id`):
  * **Geração:** ao abrir o app, ocorrências pendentes são criadas até o fim do mês seguinte, para o usuário ver as contas que vêm por aí. A geração não duplica (no máximo uma ocorrência por regra e data) e não recria uma ocorrência que o usuário excluiu.
  * **Edição da regra:** vale para as ocorrências ainda não geradas e para as pendentes a partir de hoje; ocorrências efetivadas ou passadas não mudam.
  * **Encerramento:** desativar ou excluir a regra para a geração e exclui as ocorrências pendentes futuras; o histórico fica.
  * Mensal no dia 31, 30 ou 29: segue a mesma regra de último dia do mês da RN36.
* **RN38 — Forma de Pagamento:** Cada lançamento pode informar a forma de pagamento: Débito, Crédito, Pix ou Dinheiro (opcional). "Crédito" é só uma marcação, sem mecânica de fatura, limite ou fechamento: serve para filtrar e somar o que foi pago no cartão de crédito. Compras parceladas e despesas recorrentes repassam a forma de pagamento para os lançamentos que geram.

### 1.4 Módulo de Treinos

* **RN19 — Rotina × Sessão:** A **rotina** é o planejamento (exercícios, séries, repetições e carga-alvo). A **sessão** é cada execução real do treino, com as séries efetivamente feitas. O histórico de cargas pertence às sessões, então editar ou excluir uma rotina nunca altera o histórico.
* **RN20 — Estrutura da Rotina:** Uma rotina é composta por exercícios ordenados, e cada um especifica séries, repetições, carga (kg) e tempo de descanso.
* **RN21 — Carga Opcional:** A carga pode ser nula ou zero em exercícios com peso do próprio corpo ou alongamentos.
* **RN22 — Pastas de Rotinas:** As rotinas podem ser agrupadas em pastas temporais ou temáticas (ex.: "Jan - Mar/2026").
* **RN23 — Agenda e Status do Dia:** Cada rotina pode ser agendada para dias da semana. Para uma data, o treino agendado aparece como **Concluído** (há sessão finalizada com `data_local` igual àquela data), **Pendente** (dia atual ou futuro sem sessão) ou **Faltou** (dia passado sem sessão). O dia da sessão é sempre a data local de início (ADR-12): um treino começado às 22h em Brasília conta para aquele dia, mesmo já sendo o dia seguinte em UTC.
* **RN24 — Recordes e Série Anterior:** O recorde de carga é a maior carga em uma série concluída. O recorde de volume é a maior soma de carga × repetições de um exercício numa única sessão. O recorde de repetições é o maior número de repetições em uma série concluída; é o recorde exibido para exercícios sem carga (RN21). A coluna "Anterior" mostra a mesma série da última sessão finalizada com aquele exercício. Esses valores são calculados, nunca digitados.
* **RN25 — Peso Corporal:** O usuário pode registrar o peso corporal por data e definir uma meta, exibidos no gráfico de evolução.
* **RN39 — Compartilhamento de Rotina:** A rotina é compartilhada pelo menu de compartilhamento do Android, como texto formatado ou imagem gerada no aparelho. O conteúdo inclui o nome da rotina, os dias da semana, e os exercícios na ordem, com séries, repetições, carga-alvo e descanso, além de um link para o app na Play Store. Não inclui histórico, recordes, peso corporal nem dados da conta. Funciona offline: só o envio depende do app escolhido pelo usuário.

### 1.5 Módulo de Tarefas / Atividades

* **RN26 — Status de Conclusão:** Tarefas concluídas podem ser desmarcadas a qualquer momento e voltam ao status pendente.
* **RN27 — Pastas de Tarefas:** As tarefas pertencem a pastas (ex.: "Faculdade", "Trabalho", "Casa"). Todo usuário possui a pasta padrão "Tarefas Pessoais", criada no primeiro acesso, que não pode ser excluída. Para excluir uma pasta, suas tarefas devem antes ser movidas.
* **RN28 — Níveis de Prioridade:** As tarefas aceitam as prioridades Baixa, Média (padrão) e Alta, usadas para ordenação e destaque visual.
* **RN29 — Progresso Diário:** O cabeçalho do módulo exibe a proporção de tarefas concluídas entre as que têm prazo no dia (ex.: "3 de 5 concluídas — 60%"), desconsiderando arquivadas e excluídas. O prazo é guardado como data local (`data_prazo`) e hora local opcional (`hora_prazo`), sem conversão para UTC (ADR-12): uma tarefa para "hoje às 23h" pertence a hoje.

### 1.6 Persistência e Backup

* **RN30 — Operação Offline-First:** Todas as operações dos módulos funcionam sem internet. Só ações de conta (cadastro, primeiro login, troca de credenciais, exclusão de conta), envio de feedback, leitura de avisos e backup exigem conexão.
* **RN31 — Backup na Conta Google do Usuário:** Para fazer backup, o usuário conecta voluntariamente uma conta Google nas configurações do app. A conexão pode ser desfeita a qualquer momento. O backup de todos os módulos é salvo no Google Drive do próprio usuário, que mantém a propriedade dos dados.
* **RN32 — Backup Cifrado:** O arquivo de backup é sempre cifrado antes de sair do dispositivo. Ele só pode ser restaurado pela mesma conta Kortex que o gerou, com o usuário autenticado.
* **RN33 — Exclusão Lógica:** Registros dos módulos são excluídos logicamente (data de exclusão preenchida), preservando a integridade do histórico e permitindo desfazer a ação. Como o app não faz `DELETE`, as restrições das chaves estrangeiras não disparam sozinhas; as regras equivalentes ficam em triggers do banco local:
  * não é possível excluir um registro que ainda tem dependentes ativos (conta ou categoria com lançamentos, pasta com tarefas, exercício usado em rotina ativa — RN16, RN27);
  * nenhum registro ativo pode apontar para um registro excluído (inclusive ao desfazer uma exclusão);
  * excluir uma pasta de rotinas desagrupa as rotinas dela.

### 1.7 Interface

* **RN40 — Tema da Interface:** Na primeira abertura, o app usa o tema do sistema Android (claro ou escuro) e grava a escolha em `configuracoes.modo_noturno`. A partir daí, vale o que o usuário escolher em Configurações → Modo Noturno, mesmo que o tema do sistema mude.

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

**Contexto:** O Supabase oferece autenticação pronta (Supabase Auth), que cobriria cadastro, login, confirmação de e-mail, recuperação de senha e refresh tokens sem servidor próprio. A alternativa considerada foi usar o Supabase Auth e deixar para um servidor só a chave de backup e a exclusão de conta.

**Decisão:** Não usar o Supabase Auth. O Supabase é usado apenas como banco PostgreSQL remoto, acessado por uma Web API própria em C# (ASP.NET Core). Regras de negócio, hash de senhas, códigos de verificação e emissão de tokens JWT ficam na API. O motivo principal é ter controle total sobre a autenticação e construir o back-end em C#, o que também faz parte do objetivo de aprendizado e de portfólio do projeto.

**Consequências:**
* **Positivas:**
  * Controle completo das regras de conta (RN01–RN07, RN34, RN35) e da custódia da chave de backup (ADR-11).
  * Nenhuma dependência das ferramentas de autenticação do Supabase: migrar para outro PostgreSQL exige só trocar a connection string.
* **Negativas/Mitigações:**
  * A segurança da autenticação passa a ser responsabilidade do projeto: hash de senha (RN03), limite de tentativas (RN35), rotação de tokens (ADR-10) e códigos de uso único (RN05) precisam de testes.
  * A API precisa de hospedagem própria e de um serviço de envio de e-mail para os códigos (decisões pendentes, a registrar em ADRs próprios).
  * Como o app é offline-first, a API só é chamada em ações de conta, feedback, avisos e backup (RN30). Por isso, uma hospedagem gratuita com "cold start" (servidor que dorme sem uso) é aceitável no MVP.

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

### ADR-05: Schema Privado, RLS e Papel de Privilégio Mínimo para a API

**Status:** Aprovado (substitui a versão anterior, em que a API conectava como `postgres` no schema `public`)

**Contexto:** No Supabase, tabelas do schema `public` ficam expostas automaticamente pela API REST (PostgREST) para quem tiver a URL do projeto e a chave `anon`. Essa chave é pública por design. Além disso, conectar a Web API como `postgres` dá a ela poder de apagar tabelas e alterar o banco inteiro: se a connection string vazar, o estrago é total.

**Decisão:** Três camadas de proteção:
1. **Schema privado:** as tabelas ficam no schema `kortex`, que não é exposto pela API REST do Supabase. O schema `public` fica sem tabelas do projeto. (Em Project Settings → API → Exposed schemas, `kortex` **não** deve ser adicionado.)
2. **RLS em todas as tabelas,** com uma única policy que libera o acesso só para o papel da API. Os papéis `anon` e `authenticated` não têm policy nem privilégio (`REVOKE`) e ficam bloqueados mesmo se o schema for exposto por engano.
3. **Papel próprio da API (`kortex_api`):** pode só ler e gravar dados (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) no schema `kortex`. Não pode criar, alterar nem apagar tabelas. As migrações continuam sendo executadas com o usuário `postgres`, fora da API.

A senha do `kortex_api` e a connection string ficam apenas em variáveis de ambiente do servidor, nunca no app mobile nem no Git. A connection string usa `Search Path=kortex`.

**Consequências:**
* **Positivas:** Um vazamento da connection string da API expõe dados, mas não permite destruir o banco. A API pública do Supabase não alcança as tabelas por dois caminhos independentes (schema não exposto e RLS).
* **Negativas/Mitigações:** Toda tabela nova precisa de `ENABLE ROW LEVEL SECURITY`, da policy `api_acesso_total` e dos `GRANT` para `kortex_api`. Isso faz parte do DoD de qualquer migração no Supabase. Confirme na documentação do Supabase o formato do usuário ao conectar por um papel próprio através do pooler de conexões.

### ADR-06: Backup Cifrado no Google Drive do Usuário

**Status:** Aprovado

**Contexto:** Os dados dos módulos existem só no dispositivo. É preciso permitir troca de aparelho e restauração sem armazenar esses dados em servidor próprio.

**Decisão:**
* O usuário conecta uma conta Google para o backup em Configurações → Backup (RN31).
* O app usa OAuth do Google com o escopo mínimo necessário: `drive.appdata` (pasta oculta do app) ou `drive.file` (só arquivos criados pelo app). O escopo exato deve ser confirmado na documentação do Google ao implementar.
* O módulo em React Native exporta o arquivo SQLite do usuário logado (`kortex_<usuario_id>.db`, ADR-13), cifra com AES-256-GCM (ADR-11) e envia para o Drive do usuário. Na restauração, o app confere se `configuracoes.usuario_id` do arquivo é o usuário autenticado.
* Os tokens OAuth ficam no armazenamento seguro do Android (`expo-secure-store` / Keystore), nunca no SQLite nem no Supabase.

**Consequências:**
* **Positivas:** Conformidade com a LGPD e privacidade, sem servidor para armazenar dados pessoais.
* **Negativas/Mitigações:** O app precisa de um projeto no Google Cloud com tela de consentimento OAuth configurada.

### ADR-07: Usuários em Tabela Única (Single Table Inheritance)

**Status:** Aprovado

**Contexto:** O sistema possui dois perfis (Comum e Administrador) com alguns atributos e permissões distintos.

**Decisão:** Usar uma única tabela `usuarios` com a coluna discriminadora `tipo_usuario`. Os dois perfis compartilham os mesmos dados de cadastro (nome, sobrenome, e-mail, senha); o único campo exclusivo é `nivel_permissao`, obrigatório para ADMIN e proibido para COMUM (`CHECK ck_usuarios_sti`). A data de nascimento não é coletada, porque nenhuma funcionalidade usa e a LGPD pede guardar só o necessário.

**Consequências:**
* **Positivas:** O login consulta uma única tabela, e o mesmo usuário pode virar ADM sem migrar dados.
* **Negativas/Mitigações:** `nivel_permissao` fica nula para usuários comuns, controlada pela constraint `ck_usuarios_sti`.

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
* A versão do schema fica em `PRAGMA user_version`. Cada mudança é um script de migração numerado (`001_inicial.sql`, `002_dados_padrao.sql`, `003_lista_compras.sql`…), executado em ordem na abertura do app, dentro de uma transação.
* As tabelas principais possuem `criado_em`, `atualizado_em` e `excluido_em` (soft delete, RN33).
* Datas e horários seguem os formatos do ADR-12, validados por `CHECK`.

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

### ADR-12: Regra de Fuso Horário

**Status:** Aprovado

**Contexto:** Gravar tudo em UTC faz o "dia" de um registro depender da conversão. Um treino começado às 22h em Brasília (UTC−3) fica com data UTC do dia seguinte e apareceria como **Faltou** (RN23); o mesmo vale para tarefas com prazo à noite (RN29). Além disso, misturar formatos de horário (`...00Z` e `...00.000Z`, gerado pelo `toISOString()`) quebra a comparação de texto no SQLite.

**Decisão:** Separar dois tipos de valor:
* **Data de calendário** — "a que dia isso pertence": `TEXT 'YYYY-MM-DD'` na **data local** do aparelho no momento do registro. Usada em `data_prevista`, `data_efetivacao`, `transferencias.data`, `registros_peso.data`, `tarefas.data_prazo` e `sessoes_treino.data_local`.
* **Hora local de agenda:** `TEXT 'HH:MM'` (24h), sem fuso. Usada em `tarefas.hora_prazo`.
* **Instante** — "quando aconteceu": `TEXT` ISO-8601 em **UTC com milissegundos** (`YYYY-MM-DDTHH:MM:SS.sssZ`), exatamente o formato de `Date.prototype.toISOString()`. Usado em `iniciada_em`, `finalizada_em`, `concluida_em`, `arquivada_em` e nas colunas de auditoria.
* Toda consulta "do dia" filtra pela data de calendário, nunca convertendo instantes. O app gera a data local com uma função utilitária única (com testes), não com `toISOString().slice(0, 10)`, que devolve a data UTC.
* Os formatos são validados por `CHECK` (`x IS date(x)`, `x IS strftime('%Y-%m-%dT%H:%M:%fZ', x)`), que também rejeitam datas inexistentes como `2026-02-30`.

**Consequências:**
* **Positivas:** O dia de cada registro não muda com fuso nem com horário de verão. Durações continuam exatas pelos instantes UTC.
* **Negativas/Mitigações:** Se o usuário viajar para outro fuso, registros novos usam a data local do lugar onde ele está. Para o público-alvo (Brasil), é o comportamento esperado.

### ADR-13: Um Arquivo SQLite por Usuário

**Status:** Aprovado

**Contexto:** O backup (ADR-06) exporta o arquivo SQLite inteiro. Se várias contas usassem o mesmo banco no aparelho, o backup de um usuário levaria os dados dos outros, e cada tabela precisaria de `usuario_id` com validação de que registros ligados são do mesmo dono.

**Decisão:**
* Cada conta tem o próprio arquivo: `kortex_<usuario_id>.db`. O app abre o arquivo do usuário logado.
* As tabelas locais **não** têm a coluna `usuario_id`. O UUID do dono fica em `configuracoes` (chave `usuario_id`) e é conferido na abertura e na restauração do backup.
* Exercícios padrão do app são identificados por `exercicios.personalizado = 0` (antes: `usuario_id` nulo).

**Consequências:**
* **Positivas:** Isolamento total entre contas no mesmo aparelho, backup do usuário igual ao arquivo dele, exclusão de conta local é apagar um arquivo (RN34), consultas mais simples.
* **Negativas/Mitigações:** Os seeds (categorias e exercícios padrão) são gravados em cada arquivo novo. O volume é pequeno.

### ADR-14: Clean Architecture na API e Organização por Módulo no App

**Status:** Aprovado

**Contexto:** O RNF03 deixava em aberto "MVC ou Clean Architecture". A API cuida de regras sensíveis (senha, tokens, códigos, chave de backup) e deve servir de portfólio em C#. O app tem quatro módulos e deve receber módulos novos no futuro.

**Decisão — API (C# / ASP.NET Core):** Clean Architecture com Programação Orientada a Objetos, em quatro projetos. As dependências apontam sempre para dentro, em direção ao domínio:

| Camada | Conteúdo | Depende de |
| :--- | :--- | :--- |
| `Kortex.Domain` | Entidades com comportamento (ex.: `Usuario.RegistrarFalhaLogin()`, `RefreshToken.Rotacionar()`), objetos de valor (`Email`), enumerações e regras de negócio | Nada |
| `Kortex.Application` | Casos de uso, uma classe por ação (ex.: `RealizarLogin`, `ExcluirConta`), DTOs e interfaces de saída (`IUsuarioRepositorio`, `IEnviadorEmail`, `IGeradorToken`, `IHashSenha`) | Domain |
| `Kortex.Infrastructure` | Implementações das interfaces: EF Core + Npgsql (schema `kortex`), BCrypt/Argon2, emissão de JWT, serviço de e-mail | Application, Domain |
| `Kortex.Api` | Controllers finos, autenticação, autorização por papel, limitador de taxa (RN35), injeção de dependência | Application, Infrastructure |

Dentro de cada camada, o código é separado por contexto: **Contas** (cadastro, login, tokens, códigos, exclusão), **Feedback**, **Avisos** e **Backup** (chave).

**Decisão — App (React Native + Expo):** Organização por módulo, com as regras de negócio separadas das telas:

```
src/
├── modulos/
│   ├── financas/   (telas, componentes, dominio, repositorio)
│   ├── treinos/
│   ├── tarefas/
│   └── conta/      (login, cadastro, backup, configurações)
└── compartilhado/  (banco e migrações, tema claro/escuro, componentes de UI, datas e dinheiro)
```

`dominio/` contém funções puras, sem tela nem banco (ex.: dividir parcelas, gerar ocorrências de recorrência, calcular o status do treino do dia). `repositorio/` é o único lugar que fala com o SQLite e aplica o filtro de exclusão lógica (ADR-09).

**Consequências:**
* **Positivas:** Regras testáveis sem banco nem tela. Trocar de banco, de provedor de e-mail ou de biblioteca afeta só a Infrastructure (API) ou o repositório (app). Um módulo novo no app é uma pasta nova em `modulos/` e uma migração.
* **Negativas/Mitigações:** Mais arquivos e mais cerimônia do que um MVC simples. Para não exagerar numa API pequena, não se usa mediador nem CQRS: cada caso de uso é uma classe chamada diretamente pelo controller.

### ADR-15: Expo para o App Android

**Status:** Aprovado

**Contexto:** O desenvolvimento é solo e só para Android no MVP. O app precisa de SQLite, armazenamento seguro de tokens e login do Google para o backup (código nativo).

**Decisão:**
* Usar **Expo** com `expo-sqlite` (banco local), `expo-secure-store` (tokens, ADR-10) e uma biblioteca de login do Google para o Drive (ADR-06).
* Como o login do Google exige código nativo, o desenvolvimento usa um **development build** (`expo-dev-client`), e não o Expo Go.
* **Builds:** pelo EAS Build (o plano gratuito tem uma cota mensal de builds Android) ou localmente (`npx expo run:android` para desenvolvimento; `eas build --local` para produção, em Linux, macOS ou WSL). Perfis no `eas.json`: **APK** para testes internos e **AAB** para a Play Store.

**Consequências:**
* **Positivas:** Menos configuração nativa, atualizações de SDK guiadas e builds sem precisar de Android Studio na fase inicial.
* **Negativas/Mitigações:** A cota gratuita do EAS é limitada: gerar build só quando houver versão para testar, e usar o build local quando a cota acabar. Bibliotecas nativas precisam ser compatíveis com o Expo (conferir antes de adotar).
