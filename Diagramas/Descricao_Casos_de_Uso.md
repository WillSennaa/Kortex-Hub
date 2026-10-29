# 📝 Descrição dos Atores e Casos de Uso — Kortex Hub

Complementa o [diagrama de casos de uso](README.md#1-casos-de-uso). Os números entre parênteses remetem aos requisitos (RF/RNF), às regras de negócio (RN) e às decisões de arquitetura (ADR) da [documentação](../Docs/REGRAS_DE_NEGOCIO_E_ADR.md).

## Sumário

**Atores:** [Usuário Base](#usuário-base) · [Usuário Comum](#usuário-comum) · [ADM](#adm)

**Casos de uso:**

| Código | Caso de uso | Ator | Requisito |
| :---: | :--- | :--- | :---: |
| UC01 | [Realizar Cadastro](#uc01--realizar-cadastro) | Usuário Comum | RF01 |
| UC02 | [Realizar Login](#uc02--realizar-login) | Usuário Base | RF02 |
| UC03 | [Recuperar Senha](#uc03--recuperar-senha) | Usuário Base | RF02 |
| UC04 | [Editar Dados da Conta](#uc04--editar-dados-da-conta) | Usuário Base | RF01 |
| UC05 | [Excluir Conta](#uc05--excluir-conta) | Usuário Base | RF01 |
| UC06 | [Visualizar Dashboard](#uc06--visualizar-dashboard) | Usuário Base | RF03, RF04 |
| UC07 | [Gerir Finanças](#uc07--gerir-finanças) | Usuário Base | RF05, RF06 |
| UC08 | [Gerir Treinos](#uc08--gerir-treinos) | Usuário Base | RF07, RF08 |
| UC09 | [Gerir Tarefas](#uc09--gerir-tarefas) | Usuário Base | RF09, RF10 |
| UC10 | [Configurar](#uc10--configurar) | Usuário Base | RNF05 |
| UC11 | [Fazer Backup na Conta Google](#uc11--fazer-backup-na-conta-google) | Usuário Base | RF11 |
| UC12 | [Relatar Problema ou Feedback](#uc12--relatar-problema-ou-feedback) | Usuário Base | RF12 |
| UC13 | [Visualizar Avisos](#uc13--visualizar-avisos) | Usuário Base | RF12 |
| UC14 | [Responder Feedback](#uc14--responder-feedback) | ADM | RF12 |
| UC15 | [Emitir Avisos Globais](#uc15--emitir-avisos-globais) | ADM | RF12 |
| UC16 | [Gerenciar ADMs](#uc16--gerenciar-adms) | ADM | RF01 |
| UC17 | [Compartilhar Rotina](#uc17--compartilhar-rotina) | Usuário Base | RF13 |
| INC1 | [Validar Credenciais](#inc1--validar-credenciais) | (incluído) | RF02 |
| INC2 | [Confirmar Código por E-mail](#inc2--confirmar-código-por-e-mail) | (incluído) | RF01, RF02 |
| INC3 | [Acompanhar Progresso Diário](#inc3--acompanhar-progresso-diário) | (incluído) | RF10 |
| INC4 | [Verificar Perfil de ADM](#inc4--verificar-perfil-de-adm) | (incluído) | RF12 |

---

## Atores

### Usuário Base

**Descrição:**

Ator abstrato (generalização) que reúne o que é comum a todas as pessoas que usam o Kortex Hub. Usuário Comum e ADM herdam dele.

**Atributos (tabela `usuarios` no Supabase):**
- Nome e sobrenome;
- E-mail (único, usado como login);
- Senha (gravada apenas como hash BCrypt ou Argon2);
- Status da conta (ativa ou inativa);
- Perfil (`tipo_usuario`: COMUM ou ADMIN);
- Controle de tentativas de login (`falhas_login`, `bloqueado_ate`).

**Identificação do perfil:**
O perfil é a coluna discriminadora `tipo_usuario` da tabela única `usuarios` (ADR-07) e chega ao app dentro do token JWT emitido no login.

**Casos de uso:**
Realizar Login; Recuperar Senha; Editar Dados da Conta; Excluir Conta; Visualizar Dashboard; Gerir Finanças; Gerir Treinos; Gerir Tarefas; Configurar; Fazer Backup na Conta Google; Relatar Problema ou Feedback; Visualizar Avisos; Compartilhar Rotina.

**Regras:**
- Os dados dos módulos (Finanças, Treinos, Tarefas) ficam só no aparelho, num arquivo SQLite próprio da conta (ADR-13); só conta, autenticação, avisos, feedbacks e chave de backup vão para a nuvem (RN02).
- Depois do primeiro login, o app funciona offline (RN04, RN30).

**Acesso:** app Android.

### Usuário Comum

**Descrição:**

Pessoa que usa o Kortex Hub para organizar a própria rotina: finanças, treinos e tarefas, num único app.

**Responsabilidades:**
- Criar a própria conta;
- Registrar receitas, despesas, transferências, treinos e tarefas;
- Manter o backup dos próprios dados na sua conta Google, se quiser;
- Enviar feedback sobre o app.

**Casos de uso:**
Realizar Cadastro.
Herda de Usuário Base todos os demais.

**Regras:**
- O cadastro pelo app cria sempre o perfil COMUM; o perfil ADM só é concedido por outro ADM (RN41).
- O usuário mantém a propriedade dos seus dados: o backup fica no Google Drive dele, cifrado (RN31, RN32).

**Acesso:** app Android.
**Tabela:** `usuarios` com `tipo_usuario = 'COMUM'`.

### ADM

**Descrição:**

Usuário que administra a plataforma. É um usuário completo, que usa os módulos normalmente com os próprios dados, e tem acesso a uma Área de Administração no mesmo app (RN41).

**Responsabilidades:**
- Responder os feedbacks dos usuários;
- Emitir e encerrar avisos globais;
- Promover contas existentes a ADM e remover esse acesso.

**Casos de uso:**
Responder Feedback; Emitir Avisos Globais; Gerenciar ADMs.
Herda de Usuário Base todos os demais.

**Regras:**
- A seção "Administração" do menu lateral só aparece para o perfil ADMIN; cada ação de ADM é conferida também pela API (RN41).
- Deve existir sempre pelo menos um ADM ativo; o último ADM não pode remover o próprio acesso.
- O primeiro ADM é definido direto no banco, uma única vez, na configuração inicial.
- O ADM não acessa os dados dos módulos de outros usuários, que ficam só nos aparelhos deles (RN06).

**Acesso:** app Android (mesma instalação dos usuários comuns).
**Tabela:** `usuarios` com `tipo_usuario = 'ADMIN'` e `nivel_permissao` preenchido.

---

## Casos de uso

### UC01 — Realizar Cadastro

**Resumo:**

Permite que um visitante crie sua conta no Kortex Hub.

**Ator(es):** Usuário Comum (visitante ainda não cadastrado).

**Pré-condição:** Aparelho conectado à internet; o e-mail informado não pode estar cadastrado.

**Fluxo Principal:**
1. O visitante acessa a tela de cadastro e informa nome, sobrenome, e-mail, senha e confirmação da senha.
2. O sistema valida os campos obrigatórios e se o e-mail já existe, sem diferenciar maiúsculas (RN01).
3. O sistema gera o hash da senha e grava o usuário com o perfil COMUM (RN03).
4. O sistema inclui o caso de uso **Confirmar Código por E-mail** (finalidade CONFIRMAR_EMAIL).
5. O sistema cria o banco local da conta, com os dados padrão (pasta "Tarefas Pessoais", categorias e exercícios), e exibe a Home.

**Fluxos Alternativos:**
- A1. E-mail já cadastrado: o sistema informa e não cria a conta.
- A2. Senhas diferentes ou campos inválidos: o sistema destaca os campos e não envia o formulário.
- A3. Sem internet: o sistema avisa que o cadastro exige conexão.

**Regras de negócio:**
- O cadastro pelo app cria sempre o perfil COMUM.
- A senha nunca é gravada em texto puro (RN03).

**Pós-condição:** Conta ativa, e-mail confirmado e banco local criado.

**Inclusão:** Confirmar Código por E-mail.

### UC02 — Realizar Login

**Resumo:**

Permite que o usuário entre no app com e-mail e senha.

**Ator(es):** Usuário Base.

**Pré-condição:** Conta cadastrada e ativa; internet no primeiro login.

**Fluxo Principal:**
1. O usuário informa e-mail e senha.
2. O sistema inclui o caso de uso **Validar Credenciais**.
3. A API emite o token de acesso (15 min) e o refresh token (30 dias), guardados no armazenamento seguro do Android (ADR-10).
4. O app abre o banco local da conta (`kortex_<usuario_id>.db`) e exibe a Home.

**Fluxos Alternativos:**
- A1. Credenciais inválidas: o sistema responde "E-mail ou senha incorretos", sem dizer qual dos dois (RN35).
- A2. Conta bloqueada por tentativas: o sistema informa que o login está bloqueado por 15 minutos (RN35).
- A3. Já houve login no aparelho e não há internet: o app abre direto com a sessão local (RN04).

**Regras de negócio:**
- Após 5 senhas erradas seguidas, o login da conta fica bloqueado por 15 minutos (RN35).
- Os dados locais não dependem do token; ele só é exigido nas chamadas à API.

**Pós-condição:** Usuário autenticado e Home exibida.

**Inclusão:** Validar Credenciais.

### UC03 — Recuperar Senha

**Resumo:**

Permite redefinir a senha esquecida.

**Ator(es):** Usuário Base.

**Pré-condição:** Aparelho conectado à internet.

**Fluxo Principal:**
1. Na tela de login, o usuário toca em "Recuperar Senha" e informa o e-mail.
2. O sistema responde sempre "Se o e-mail estiver cadastrado, enviaremos um código" (RN35).
3. O sistema inclui o caso de uso **Confirmar Código por E-mail** (finalidade RECUPERAR_SENHA).
4. O usuário informa e confirma a nova senha.
5. O sistema grava o novo hash, revoga os refresh tokens antigos e volta para o login.

**Fluxos Alternativos:**
- A1. Senhas diferentes: o sistema destaca os campos.

**Regras de negócio:**
- A mensagem neutra evita revelar quais e-mails estão cadastrados (RN35).
- A troca de senha não afeta os backups, porque a chave de backup não é derivada da senha (ADR-11).

**Pós-condição:** Senha alterada.

**Inclusão:** Confirmar Código por E-mail.

### UC04 — Editar Dados da Conta

**Resumo:**

Permite consultar e alterar nome, sobrenome, e-mail e senha.

**Ator(es):** Usuário Base.

**Pré-condição:** Usuário autenticado e com internet.

**Fluxo Principal:**
1. O usuário abre Menu Lateral → Meus Dados.
2. O sistema exibe nome, sobrenome e e-mail.
3. O usuário altera o dado desejado e confirma.
4. Para troca de e-mail ou de senha, o sistema inclui o caso de uso **Confirmar Código por E-mail** (finalidades TROCAR_EMAIL ou TROCAR_SENHA).
5. O sistema grava a alteração e atualiza a tela.

**Fluxos Alternativos:**
- A1. Novo e-mail já cadastrado: o sistema informa e não altera.
- A2. Desativar conta: o usuário pode desativar a conta (status INATIVO), o que é reversível e diferente de excluir.

**Regras de negócio:**
- Troca de e-mail ou de senha exige código de uso único, válido por 15 minutos e invalidado após 5 tentativas erradas (RN05).

**Pós-condição:** Dados da conta atualizados.

**Inclusão:** Confirmar Código por E-mail (só para e-mail e senha).

### UC05 — Excluir Conta

**Resumo:**

Permite que o usuário apague definitivamente a conta e todos os seus dados, como exige a política do Google Play.

**Ator(es):** Usuário Base.

**Pré-condição:** Usuário autenticado e com internet.

**Fluxo Principal:**
1. O usuário abre Menu Dados → Excluir conta.
2. O sistema mostra o que acontece: conta, dados do aparelho e backup são apagados, e a ação não pode ser desfeita.
3. O sistema inclui o caso de uso **Confirmar Código por E-mail** (finalidade EXCLUIR_CONTA).
4. A API apaga o usuário; em cascata saem tokens, códigos, chave de backup e feedbacks (RN34).
5. O app apaga o arquivo de backup do Google Drive (se houver conta Google conectada), o banco local e o armazenamento seguro.
6. O sistema exibe a tela "Conta excluída".

**Fluxos Alternativos:**
- A1. Exclusão pelo link web: o mesmo fluxo, a partir de uma página web, para quem já desinstalou o app (RN34).
- A2. O usuário é o último ADM: o sistema impede a exclusão até que outra conta seja promovida (RN41).

**Regras de negócio:**
- Mesmo que o arquivo de backup fique no Drive, ele não pode mais ser decifrado, porque a chave foi apagada com a conta (ADR-11).

**Pós-condição:** Conta e dados do usuário apagados.

**Inclusão:** Confirmar Código por E-mail.

### UC06 — Visualizar Dashboard

**Resumo:**

Mostra, na Home, o resumo do dia: finanças, treino agendado e tarefas.

**Ator(es):** Usuário Base.

**Pré-condição:** Usuário autenticado (funciona offline).

**Fluxo Principal:**
1. O usuário abre a Home.
2. O sistema exibe o calendário da semana com o dia de hoje selecionado.
3. O sistema exibe o resumo financeiro do dia, o treino agendado com o status (Pendente, Concluído ou Faltou) e as tarefas do dia.
4. O sistema inclui o caso de uso **Acompanhar Progresso Diário**.
5. O usuário seleciona outro dia, e todos os blocos são atualizados para aquela data (RN09).

**Fluxos Alternativos:**
- A1. O usuário abre o calendário do mês para escolher uma data distante.
- A2. O usuário toca em "Novo Registro" e vai para o registro rápido (RNF01).

**Regras de negócio:**
- O dia de cada registro é a data local do aparelho (ADR-12).
- Status do treino: Concluído se há sessão finalizada naquele dia, Pendente para hoje ou futuro, Faltou para dia passado sem sessão (RN23).

**Pós-condição:** Nenhuma alteração de dados.

**Inclusão:** Acompanhar Progresso Diário.

### UC07 — Gerir Finanças

**Resumo:**

Permite cadastrar contas e categorias e registrar receitas, despesas e transferências.

**Ator(es):** Usuário Base.

**Pré-condição:** Usuário autenticado (funciona offline).

**Fluxo Principal:**
1. O usuário abre o módulo Finanças e toca em "+".
2. O usuário escolhe Receita, Despesa ou Transferência.
3. O formulário abre com a conta principal e a data de hoje preenchidas (RNF01).
4. O usuário informa o valor e a categoria e, se quiser, descrição, forma de pagamento, tags e observação.
5. O sistema valida e grava o lançamento; o saldo das contas é recalculado (RN13).

**Fluxos Alternativos:**
- A1. Despesa parcelada: o usuário escolhe de 2 a 48 parcelas; o sistema gera todas as parcelas de uma vez (RN36).
- A2. Despesa recorrente: o usuário escolhe semanal, mensal ou anual e, se quiser, a data de fim; o sistema guarda a regra e cria as ocorrências (RN37).
- A3. Transferência: o usuário informa conta de origem e de destino, que devem ser diferentes (RN14).
- A4. Gerir contas e categorias: o usuário cria contas, categorias e subcategorias, ou arquiva as que não usa mais.
- A5. Excluir categoria ou conta com lançamentos: o sistema impede e sugere reatribuir os lançamentos ou arquivar (RN16).
- A6. Consultar: o usuário vê transações do mês, saldo das contas e gráfico de despesas por categoria (RN17).

**Regras de negócio:**
- Toda transação tem conta e categoria, do mesmo tipo da transação (RN10).
- Subcategorias têm um único nível e o mesmo tipo da categoria-pai (RN11).
- Valores em centavos, sem ponto flutuante (RN18).
- "Crédito" é só uma forma de pagamento, sem fatura nem limite (RN38).
- Só despesas podem ser parceladas ou repetidas.

**Pós-condição:** Lançamentos gravados no banco local e saldos atualizados.

### UC08 — Gerir Treinos

**Resumo:**

Permite montar rotinas de treino, executar sessões e acompanhar a evolução.

**Ator(es):** Usuário Base.

**Pré-condição:** Usuário autenticado (funciona offline).

**Fluxo Principal:**
1. O usuário abre o módulo Treinos → Rotinas e cria uma rotina, com nome, pasta, dias da semana, local e exercícios (séries, repetições, carga-alvo e descanso).
2. No dia agendado, o usuário inicia a rotina.
3. O sistema cria a sessão e mostra cada exercício com a coluna "Anterior" (RN24).
4. O usuário registra carga e repetições de cada série e marca as concluídas.
5. O usuário finaliza o treino; o sistema grava a sessão e atualiza histórico e recordes.

**Fluxos Alternativos:**
- A1. Descartar treino: a sessão é excluída logicamente (RN33).
- A2. Exercício sem carga: a carga fica nula, e o recorde exibido é o de repetições (RN21, RN24).
- A3. Estatísticas: o usuário vê a frequência de treinos e registra o peso corporal, com meta (RN25).
- A4. Compartilhar: na tela Ver Rotina, o usuário pode seguir para **Compartilhar Rotina**.

**Regras de negócio:**
- Rotina é o plano; sessão é a execução. Editar ou excluir uma rotina nunca altera o histórico (RN19).
- Recordes e coluna "Anterior" são calculados, nunca digitados (RN24).

**Pós-condição:** Rotinas, sessões e séries gravadas no banco local.

### UC09 — Gerir Tarefas

**Resumo:**

Permite organizar tarefas em pastas, com prazo e prioridade, e marcá-las como concluídas.

**Ator(es):** Usuário Base.

**Pré-condição:** Usuário autenticado (funciona offline).

**Fluxo Principal:**
1. O usuário abre o módulo Atividades.
2. O usuário cria uma tarefa com título, descrição, pasta, prazo (data e, se quiser, hora) e prioridade.
3. O sistema grava a tarefa e a exibe na pasta.
4. O usuário marca a tarefa como concluída; o progresso do dia é atualizado (RN29).

**Fluxos Alternativos:**
- A1. Desmarcar: a tarefa volta para pendente (RN26).
- A2. Arquivar: a tarefa sai das listas, mas continua no banco.
- A3. Nova pasta: o usuário cria pastas como "Faculdade" ou "Trabalho".
- A4. Excluir pasta com tarefas: o sistema pede para mover as tarefas antes (RN27).

**Regras de negócio:**
- A pasta padrão "Tarefas Pessoais" não pode ser excluída (RN27).
- Prioridades: Baixa, Média (padrão) e Alta (RN28).

**Pós-condição:** Tarefas gravadas no banco local.

### UC10 — Configurar

**Resumo:**

Permite ajustar preferências do app, como o tema e as notificações.

**Ator(es):** Usuário Base.

**Pré-condição:** Usuário autenticado.

**Fluxo Principal:**
1. O usuário abre Menu Lateral → Configurações.
2. O sistema exibe as opções: notificações, preferências dos módulos, Backup e Modo Noturno.
3. O usuário altera uma opção.
4. O sistema grava a preferência em `configuracoes` e aplica na hora.

**Fluxos Alternativos:**
- A1. Backup: o usuário segue para **Fazer Backup na Conta Google**.

**Regras de negócio:**
- Na primeira abertura, o tema segue o do sistema Android; depois, vale a escolha do usuário (RN40).

**Pós-condição:** Preferência gravada no banco local.

### UC11 — Fazer Backup na Conta Google

**Resumo:**

Permite salvar uma cópia cifrada dos dados no Google Drive do usuário e restaurá-la em outro aparelho.

**Ator(es):** Usuário Base.

**Pré-condição:** Usuário autenticado e com internet.

**Fluxo Principal:**
1. O usuário abre Configurações → Backup e toca em "Conectar conta Google".
2. O usuário autoriza o acesso do app à pasta de dados dele no Drive (OAuth).
3. O sistema obtém a chave de backup da conta pela API (ADR-11).
4. O usuário toca em "Fazer backup agora".
5. O sistema cifra o banco local com AES-256-GCM e envia o arquivo ao Drive.
6. O sistema mostra a data e o tamanho do último backup.

**Fluxos Alternativos:**
- A1. Restaurar: o sistema baixa o arquivo, confere se ele pertence à conta logada, pede confirmação e substitui os dados do aparelho (ADR-06).
- A2. Desconectar: o usuário desconecta a conta Google a qualquer momento (RN31).
- A3. Sem internet: o sistema avisa que o backup exige conexão.

**Regras de negócio:**
- O arquivo sai do aparelho sempre cifrado e só pode ser restaurado pela mesma conta Kortex (RN32).
- Os tokens do Google ficam no armazenamento seguro do Android, nunca no banco.

**Pós-condição:** Backup cifrado no Drive do usuário (ou dados restaurados).

### UC12 — Relatar Problema ou Feedback

**Resumo:**

Permite enviar bugs, sugestões ou outros comentários e acompanhar as respostas.

**Ator(es):** Usuário Base.

**Pré-condição:** Usuário autenticado e com internet.

**Fluxo Principal:**
1. O usuário abre Menu Lateral → Enviar feedback.
2. O usuário escolhe o tipo (Bug, Sugestão ou Outro) e escreve a mensagem.
3. O sistema grava o feedback com o status "Aguardando".
4. Em "Meus feedbacks", o usuário vê os envios e as respostas dos ADMs.

**Fluxos Alternativos:**
- A1. Sem internet: o sistema avisa que o envio exige conexão.

**Regras de negócio:**
- Feedbacks ficam no Supabase e são apagados junto com a conta (RN34).

**Pós-condição:** Feedback registrado.

### UC13 — Visualizar Avisos

**Resumo:**

Mostra os avisos globais emitidos pelos ADMs.

**Ator(es):** Usuário Base.

**Pré-condição:** Usuário autenticado; internet para buscar avisos novos.

**Fluxo Principal:**
1. O usuário abre o Menu Notificações.
2. O sistema exibe, em "Avisos do Kortex", os avisos ativos (sem data de expiração ou ainda dentro dela).
3. O usuário lê o aviso.

**Fluxos Alternativos:**
- A1. Sem internet: o sistema mostra os últimos avisos carregados.

**Regras de negócio:**
- Aviso com data de expiração vencida não aparece.

**Pós-condição:** Nenhuma alteração de dados.

### UC14 — Responder Feedback

**Resumo:**

Permite ao ADM ler e responder os feedbacks dos usuários.

**Ator(es):** ADM.

**Pré-condição:** ADM autenticado e com internet.

**Fluxo Principal:**
1. O sistema inclui o caso de uso **Verificar Perfil de ADM**.
2. O ADM abre Administração → Feedbacks e filtra os pendentes.
3. O ADM abre um feedback, escreve a resposta e envia.
4. O sistema grava a resposta e a data; o feedback passa para "Respondido".

**Fluxos Alternativos:**
- A1. O ADM filtra por "Respondidos" ou "Todos" para consultar.

**Regras de negócio:**
- Resposta e data de resposta são gravadas juntas (constraint `ck_feedback_resposta`).

**Pós-condição:** Feedback respondido e visível para o usuário em "Meus feedbacks".

**Inclusão:** Verificar Perfil de ADM.

### UC15 — Emitir Avisos Globais

**Resumo:**

Permite ao ADM publicar e encerrar avisos para todos os usuários.

**Ator(es):** ADM.

**Pré-condição:** ADM autenticado e com internet.

**Fluxo Principal:**
1. O sistema inclui o caso de uso **Verificar Perfil de ADM**.
2. O ADM abre Administração → Avisos → Novo Aviso.
3. O ADM informa título (até 100 caracteres), mensagem e, se quiser, a data de validade, conferindo a prévia.
4. O ADM publica; o aviso passa a aparecer para todos os usuários.

**Fluxos Alternativos:**
- A1. Encerrar: o ADM encerra um aviso ativo antes da validade.

**Regras de negócio:**
- A validade, quando informada, deve ser posterior à criação.
- Se a conta do ADM for excluída, o aviso continua, sem autor (RN34).

**Pós-condição:** Aviso publicado (ou encerrado).

**Inclusão:** Verificar Perfil de ADM.

### UC16 — Gerenciar ADMs

**Resumo:**

Permite ao ADM promover uma conta existente a ADM ou remover esse acesso.

**Ator(es):** ADM.

**Pré-condição:** ADM autenticado e com internet.

**Fluxo Principal:**
1. O sistema inclui o caso de uso **Verificar Perfil de ADM**.
2. O ADM abre Administração → Gerenciar ADMs.
3. O ADM informa o e-mail de uma conta existente e toca em "Tornar ADM".
4. O sistema altera o perfil da conta para ADMIN.
5. O novo perfil vale a partir da próxima renovação do token da pessoa (RN41).

**Fluxos Alternativos:**
- A1. E-mail sem conta: o sistema informa que a pessoa precisa se cadastrar antes.
- A2. Remover acesso: o ADM remove o perfil de outra conta, que volta a ser COMUM.
- A3. Último ADM: o sistema impede a remoção do próprio acesso.

**Regras de negócio:**
- Não se cria conta nova: a pessoa mantém o mesmo login e os mesmos dados (ADR-07).
- Sempre deve existir pelo menos um ADM ativo (RN41).

**Pós-condição:** Perfil da conta alterado.

**Inclusão:** Verificar Perfil de ADM.

### UC17 — Compartilhar Rotina

**Resumo:**

Permite enviar uma rotina de treino para amigos, como texto ou imagem.

**Ator(es):** Usuário Base.

**Pré-condição:** Rotina cadastrada (funciona offline; o envio depende do app escolhido).

**Fluxo Principal:**
1. Na tela Ver Rotina, o usuário toca no ícone de compartilhar.
2. O sistema mostra a prévia da imagem e as opções "Compartilhar como imagem" e "Compartilhar como texto".
3. O usuário escolhe uma opção.
4. O sistema gera o conteúdo (nome, dias, exercícios com séries, repetições, carga e descanso, e link da Play Store) e abre o menu de compartilhamento do Android.

**Fluxos Alternativos:**
- A1. O usuário cancela o menu de compartilhamento; nada é enviado.

**Regras de negócio:**
- Histórico, recordes, peso corporal e dados da conta nunca são compartilhados (RN39).

**Pós-condição:** Nenhuma alteração de dados.

### INC1 — Validar Credenciais

**Resumo:**

Confere e-mail e senha na API e controla o limite de tentativas.

**Ator(es):** — (incluído por Realizar Login).

**Pré-condição:** E-mail e senha informados.

**Fluxo Principal:**
1. A API busca a conta pelo e-mail, sem diferenciar maiúsculas.
2. A API confere se a conta está ativa e não está bloqueada.
3. A API compara a senha com o hash gravado.
4. Senha certa: o contador de falhas é zerado e o login segue.

**Fluxos Alternativos:**
- A1. Senha errada: a API soma uma falha; na 5ª seguida, bloqueia o login por 15 minutos (RN35).
- A2. Mais de 10 requisições por minuto do mesmo IP: a API responde 429 (RN35).

**Regras de negócio:**
- A resposta de erro é sempre neutra: "E-mail ou senha incorretos".

**Pós-condição:** Credenciais aceitas ou recusadas.

### INC2 — Confirmar Código por E-mail

**Resumo:**

Envia um código numérico ao e-mail e confere o que o usuário digita.

**Ator(es):** — (incluído por Realizar Cadastro, Recuperar Senha, Editar Dados da Conta e Excluir Conta).

**Pré-condição:** Ação que exige confirmação, com a finalidade definida.

**Fluxo Principal:**
1. A API gera o código, grava apenas o hash e envia o código ao e-mail.
2. O usuário digita o código recebido.
3. A API confere o código, a finalidade e a validade e marca o código como usado.
4. A ação que incluiu este caso de uso continua.

**Fluxos Alternativos:**
- A1. Código errado: soma uma tentativa; na 5ª, o código é invalidado.
- A2. Código expirado: o usuário toca em "Reenviar Código".

**Regras de negócio:**
- O código é de uso único, expira em 15 minutos e é invalidado após 5 tentativas erradas (RN05).
- Finalidades: CONFIRMAR_EMAIL, TROCAR_EMAIL, TROCAR_SENHA, RECUPERAR_SENHA e EXCLUIR_CONTA.

**Pós-condição:** Código usado e ação autorizada.

### INC3 — Acompanhar Progresso Diário

**Resumo:**

Calcula e exibe quantas tarefas do dia foram concluídas.

**Ator(es):** — (incluído por Visualizar Dashboard).

**Pré-condição:** Data selecionada no calendário.

**Fluxo Principal:**
1. O sistema conta as tarefas com prazo na data selecionada, desconsiderando arquivadas e excluídas.
2. O sistema conta as concluídas entre elas.
3. O sistema exibe o progresso, por exemplo: "3 de 5 concluídas (60%)".

**Fluxos Alternativos:**
- A1. Nenhuma tarefa no dia: o bloco informa que não há tarefas para a data.

**Regras de negócio:**
- O dia do prazo é a data local, sem conversão para UTC (RN29, ADR-12).

**Pós-condição:** Nenhuma alteração de dados.

### INC4 — Verificar Perfil de ADM

**Resumo:**

Garante que só ADMs executem as ações de administração.

**Ator(es):** — (incluído por Responder Feedback, Emitir Avisos Globais e Gerenciar ADMs).

**Pré-condição:** Usuário autenticado.

**Fluxo Principal:**
1. O app lê o perfil no token e mostra a seção "Administração" só para ADMIN.
2. A cada ação de administração, a API confere o perfil no token.
3. Perfil ADMIN: a ação segue.

**Fluxos Alternativos:**
- A1. Perfil COMUM: a API responde 403 Forbidden e a ação não é executada.

**Regras de negócio:**
- Esconder o menu não é a proteção; a conferência na API é obrigatória (RN41).

**Pós-condição:** Ação de administração autorizada ou recusada.
