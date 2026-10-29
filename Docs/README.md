# 📄 Documentação do Kortex Hub

| Documento | Conteúdo |
| :--- | :--- |
| Este arquivo | Requisitos funcionais e não funcionais detalhados |
| [Regras de Negócio e ADRs](REGRAS_DE_NEGOCIO_E_ADR.md) | RN01–RN41 e decisões de arquitetura ADR-01–ADR-15 |
| [Dicionário de Dados e DDL](Dicionario%20Dados%20e%20DDL/README.md) | Tabelas, colunas e scripts SQL (Supabase e SQLite) |
| [Pesquisa](Pesquisa/README.md) | Pesquisa de validação com o público-alvo |
| [Teste de Usabilidade](Teste%20de%20Usabilidade/README.md) | Roteiro do teste do protótipo |

---

### 🎯 Requisitos Funcionais (Detalhes Expandidos)

* **RF01 - Gerir Usuários:** O sistema deve permitir cadastrar, consultar, atualizar, desativar e excluir contas de usuários. A exclusão apaga a conta e todos os dados do usuário, pode ser feita dentro do app ou por um link web e exige código de confirmação por e-mail (RN34), como pede a política do Google Play para apps com criação de conta. A gestão diferencia Usuários Comuns de Administradores (RN06). Um ADM promove uma conta existente a ADM, ou remove esse acesso, pela Área de Administração do próprio app (RN41). Os dados de conta e autenticação ficam no Supabase (PostgreSQL), acessado apenas pela Web API em C#.
* **RF02 - Autenticar Acesso:** A entrada no aplicativo é feita por e-mail e senha (RN07), com suporte à recuperação de senha. A API emite um token JWT de curta duração e um refresh token. Após o primeiro login, o app funciona offline (RN04, ADR-10). Troca de senha, troca de e-mail e recuperação exigem um código de verificação enviado ao e-mail (RN05).
* **RF03 - Visualizar Central:** O aplicativo apresenta um Dashboard inicial em formato de calendário ou linha do tempo. O usuário alterna os dias da semana ou do mês no carrossel superior.
* **RF04 - Centralizar Dados:** O Dashboard consolida as tarefas do dia, o treino agendado (com status Pendente, Concluído ou Faltou) e o resumo financeiro. Todos os blocos são atualizados ao selecionar uma data no calendário (RN08, RN09, RN23).
* **RF05 - Gerir Finanças:** O sistema permite cadastrar contas/carteiras com saldo inicial e registrar receitas e despesas com valor, data prevista, descrição, status (pendente ou efetivada, exibido como "Recebido" na receita e "Pago" na despesa) e forma de pagamento opcional: Débito, Crédito, Pix ou Dinheiro (RN38). Toda transação é vinculada a uma conta e a uma categoria (RN10). Despesas podem ser **parceladas** em 2 a 48 vezes, gerando uma parcela por mês (RN36), ou **repetidas** a cada semana, mês ou ano, com ou sem data de fim (RN37). O usuário também pode transferir valores entre contas (RN14). Os saldos são calculados dinamicamente (RN13).
* **RF06 - Categorizar Transações:** Receitas e despesas são vinculadas a categorias e subcategorias do mesmo tipo (RN11), cada uma com ícone e cor HEX (RN15), e podem receber tags livres. Categorias com transações vinculadas não podem ser excluídas sem reatribuição ou arquivamento (RN16). O resumo mensal exibe a distribuição de despesas por categoria (RN17).
* **RF07 - Gerir Rotinas de Treino:** As rotinas são estruturadas por divisões customizadas (ex.: Treino A, Treino B), com exercícios ordenados contendo séries, repetições, carga-alvo e descanso (RN20). Podem ser agendadas para dias da semana (RN23) e agrupadas em pastas temporais ou temáticas, como "Jan - Mar/2026" (RN22).
* **RF08 - Registrar Treinos e Exercícios:** O usuário inicia uma sessão a partir de uma rotina e registra cada série realizada (carga, repetições e conclusão), vendo a série da sessão anterior como referência. O histórico fica nas sessões e não altera o catálogo de exercícios nem a rotina (RN19). O sistema calcula recordes de carga e volume (RN24), exibe a frequência de treinos e permite registrar o peso corporal com uma meta (RN25). A carga pode ser zero ou nula (RN21).
* **RF09 - Gerir Tarefas (To-Do):** O usuário cria tarefas com título, descrição, prazo e prioridade Baixa, Média ou Alta (RN28), organizadas em pastas como "Faculdade" ou "Trabalho". A pasta padrão "Tarefas Pessoais" não pode ser excluída (RN27).
* **RF10 - Concluir Atividades:** O usuário marca tarefas como concluídas, pode desmarcá-las (RN26) e arquivá-las. O cabeçalho do módulo mostra o progresso do dia, como "3 de 5 concluídas — 60%" (RN29).
* **RF11 - Backup na Conta Google:** Em Configurações → Backup, o usuário conecta voluntariamente uma conta Google (RN31). O app gera um arquivo cifrado com os dados de todos os módulos (RN32) e o envia para o Google Drive do usuário. O mesmo arquivo pode ser restaurado em outro aparelho após o login na mesma conta Kortex. A conta Google pode ser desconectada a qualquer momento.
* **RF12 - Comunicar com a Plataforma:** O usuário pode enviar feedbacks (bug, sugestão ou outro) e visualizar avisos globais. Os ADMs usam o mesmo app: no menu lateral, a seção "Administração" (visível só para ADMs) permite responder feedbacks, emitir avisos com data de expiração e gerenciar ADMs (RN41).
* **RF13 - Compartilhar Rotina:** Na tela da rotina, o usuário compartilha a ficha de treino pelo menu de compartilhamento do Android (WhatsApp, Instagram etc.), como texto formatado ou como imagem. O conteúdo traz o nome da rotina, os exercícios com séries, repetições, carga-alvo e descanso, e um link para baixar o Kortex Hub na Play Store. Não envolve servidor nem dados pessoais (RN39).

---

### 🛡️ Requisitos Não Funcionais (Detalhes Expandidos)

* **RNF01 - Desempenho de Interface:** Metas medidas num Android intermediário, com o app em modo release:
  * **Registro rápido** (pedido da pesquisa): o formulário de receita ou despesa abre com a **conta principal** e a **data de hoje** já preenchidas. O fluxo mínimo é: Novo Registro → tipo (Receita ou Despesa) → valor → categoria → Salvar. Conta, data, forma de pagamento, parcelas e descrição são opcionais para alterar.
  * **Abertura:** o app abre e mostra a Home em até **2 segundos** (abertura a frio).
  * **Navegação:** a troca de tela termina em até **300 ms**, e as listas rolam sem travadas visíveis.

  A interface é modularizada por um Guia de Estilos no Figma.
* **RNF02 - Segurança de Dados:** Senhas passam por hash seguro com *salt* (BCrypt ou Argon2) na API e nunca são gravadas em texto puro (RN03). O login tem limite de tentativas e bloqueio temporário (RN35). As tabelas do Supabase ficam num schema não exposto pela API pública, com RLS ativado e acesso apenas para um papel próprio da Web API, com privilégio mínimo (ADR-05). Tokens (refresh token da API e OAuth do Google) ficam no armazenamento seguro do Android. O backup é cifrado com AES-256-GCM (ADR-11). Tudo isso segue as diretrizes da LGPD.
* **RNF03 - Arquitetura de Software:** A infraestrutura é híbrida: Web API em C# (ASP.NET Core) para conta e autenticação e banco local para os módulos.
  * **API:** Clean Architecture com Programação Orientada a Objetos, dividida nas camadas Domain, Application, Infrastructure e Api, com as dependências apontando sempre para o domínio (ADR-14).
  * **App:** React Native com Expo (ADR-15), organizado por módulo (Finanças, Treinos, Tarefas, Conta). Cada módulo tem pasta, tabelas e telas próprias, e as regras de negócio ficam fora das telas, para permitir novos módulos no futuro.
* **RNF05 - Temas Claro e Escuro:** O app oferece tema claro e escuro, definidos no Guia de Estilos do Figma com os mesmos tokens de cor (fundo, superfície, texto, ação, status). Na primeira abertura, o app segue o tema do sistema Android; depois, vale a escolha do usuário em Configurações → Modo Noturno (`configuracoes.modo_noturno`, RN40).
* **RNF04 - Persistência Local (Offline-First):** Os dados dos módulos ficam em SQLite no dispositivo, um arquivo por usuário (ADR-13), e funcionam 100% offline (RN30). Datas seguem a regra de fuso do ADR-12. Todas as entidades usam UUID v4 como chave primária (ADR-04), valores monetários e de peso são inteiros (ADR-08) e o schema evolui por migrações versionadas (ADR-09).
