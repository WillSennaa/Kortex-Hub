# 🗄️ Dicionário de Dados e Scripts DDL — Kortex Hub

O banco do Kortex Hub é dividido em duas partes (ADR-01):

| Parte | SGBD | O que guarda | Script |
| :--- | :--- | :--- | :--- |
| ☁️ Nuvem | Supabase (PostgreSQL) | Conta, autenticação, avisos globais, feedbacks e chave de backup | [`supabase_nuvem.sql`](supabase_nuvem.sql) |
| 📱 Local | SQLite (no dispositivo, um arquivo por usuário) | Todos os dados dos módulos (Finanças, Treinos, Tarefas) | Migrações: [`001_inicial.sql`](001_inicial.sql) (schema) e [`002_dados_padrao.sql`](002_dados_padrao.sql) (dados padrão) |

> Os arquivos `.sql` são a **fonte da verdade**. Este documento explica o significado de cada tabela e coluna. Os diagramas ficam em [Diagramas](../../Diagramas/README.md).

### Convenções gerais

| Regra | Como é aplicada | Referência |
| :--- | :--- | :--- |
| Chave primária | UUID v4 (`UUID` no Postgres, `TEXT` no SQLite), gerado no dispositivo | ADR-04 |
| Dinheiro | `INTEGER` em **centavos** no SQLite (R$ 12,50 → `1250`) | ADR-08 |
| Peso e carga | `INTEGER` em **gramas** (32,5 kg → `32500`) | ADR-08 |
| Data de calendário (SQLite) | `TEXT 'YYYY-MM-DD'` na **data local** do aparelho; decide a que dia o registro pertence | ADR-12 |
| Hora de agenda (SQLite) | `TEXT 'HH:MM'` local, sem fuso | ADR-12 |
| Instante (SQLite) | `TEXT` ISO-8601 **UTC com milissegundos** (`2026-10-21T13:00:00.000Z`, formato do `toISOString()`) | ADR-12 |
| Validação de formato | `CHECK (x IS date(x))` e `CHECK (x IS strftime('%Y-%m-%dT%H:%M:%fZ', x))`; rejeitam `ontem` e `2026-02-30` | ADR-12 |
| Booleanos (SQLite) | `INTEGER` 0/1 com `CHECK` | — |
| Auditoria | `criado_em`, `atualizado_em` e `excluido_em` (soft delete) nas tabelas principais | ADR-09 |
| Integridade com soft delete | Triggers bloqueiam excluir registro com dependentes ativos e apontar para registro excluído | RN33 |
| Versão do schema local | `PRAGMA user_version`; cada mudança vira uma migração numerada (`001_…`, `002_…`), executada em ordem | ADR-09 |
| Dados padrão | Migração `002`: pasta "Tarefas Pessoais", 9 categorias e 11 subcategorias, 25 exercícios; UUIDs fixos, `padrao = 1` / `personalizado = 0` | RN11, RN27 |
| Chaves estrangeiras (SQLite) | Cada conexão deve executar `PRAGMA foreign_keys = ON;` | — |
| Dono dos dados locais | Um arquivo `kortex_<usuario_id>.db` por conta; sem coluna `usuario_id` nas tabelas | ADR-13 |

---

## ☁️ PARTE 1 — Banco em Nuvem (Supabase / PostgreSQL)

**Acesso:** somente pela Web API em C#, com o papel `kortex_api` (só `SELECT`, `INSERT`, `UPDATE`, `DELETE`). As tabelas ficam no schema privado `kortex`, que não é exposto pela API REST do Supabase, e têm RLS com uma policy que libera só esse papel (ADR-05).

**Exclusão de conta (RN34):** `DELETE` em `usuarios` remove em cascata `refresh_tokens`, `codigos_verificacao`, `chaves_backup` e `feedbacks` do usuário.

### `usuarios` — contas (Single Table Inheritance, ADR-07)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador do usuário. |
| nome | VARCHAR(100) | NOT NULL | Nome. |
| sobrenome | VARCHAR(100) | NOT NULL | Sobrenome. |
| email | VARCHAR(150) | NOT NULL, UNIQUE (`lower(email)`) | Login; único sem diferenciar maiúsculas (RN01). |
| senha_hash | VARCHAR(255) | NOT NULL | Hash BCrypt/Argon2 gerado pela API (RN03). |
| email_verificado_em | TIMESTAMPTZ | NULL | Quando o e-mail foi confirmado. |
| status | VARCHAR(20) | NOT NULL, CHECK `ATIVO`/`INATIVO` | Conta ativa ou desativada (reversível; a exclusão é definitiva — RN34). |
| tipo_usuario | VARCHAR(20) | NOT NULL, CHECK `COMUM`/`ADMIN` | Discriminador do STI. |
| nivel_permissao | VARCHAR(50) | NULL | Obrigatório para ADMIN, proibido para COMUM (`ck_usuarios_sti`). Único campo exclusivo de um perfil (ADR-07). |
| falhas_login | SMALLINT | NOT NULL, padrão 0, ≥ 0 | Senhas erradas seguidas; zera no login certo (RN35). |
| bloqueado_ate | TIMESTAMPTZ | NULL | Login bloqueado até este instante, após 5 falhas (RN35). |
| criado_em / atualizado_em | TIMESTAMPTZ | NOT NULL | Auditoria. |

### `refresh_tokens` — sessões de longa duração (ADR-10)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador. |
| usuario_id | UUID | FK → usuarios, CASCADE | Dono da sessão. |
| token_hash | VARCHAR(255) | NOT NULL, UNIQUE | Hash do refresh token (o token fica só no SecureStore do app). |
| dispositivo | VARCHAR(100) | NULL | Descrição do aparelho. |
| criado_em / expira_em | TIMESTAMPTZ | NOT NULL | Emissão e validade. |
| revogado_em | TIMESTAMPTZ | NULL | Preenchido no logout ou na rotação. |
| substituido_por | UUID | FK → refresh_tokens, NULL | Token que substituiu este na rotação (detecção de reuso). |

### `codigos_verificacao` — códigos enviados por e-mail (RN05, RN34)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador. |
| usuario_id | UUID | FK → usuarios, CASCADE | Usuário que solicitou. |
| finalidade | VARCHAR(30) | CHECK | `CONFIRMAR_EMAIL`, `TROCAR_EMAIL`, `TROCAR_SENHA`, `RECUPERAR_SENHA`, `EXCLUIR_CONTA`. |
| codigo_hash | VARCHAR(255) | NOT NULL | Hash do código numérico. |
| novo_email | VARCHAR(150) | Obrigatório só em `TROCAR_EMAIL` | E-mail que será aplicado após a confirmação. |
| tentativas | SMALLINT | 0 a 5 | Tentativas erradas; ao chegar em 5 o código é invalidado. |
| criado_em / expira_em | TIMESTAMPTZ | NOT NULL | Validade sugerida: 15 minutos. |
| usado_em | TIMESTAMPTZ | NULL | Uso único. |

### `chaves_backup` — chave de cifragem do backup (ADR-11)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| usuario_id | UUID | PK, FK → usuarios, CASCADE | Uma chave por usuário. Apagada com a conta, o backup no Drive fica ilegível. |
| chave_cifrada | BYTEA | NOT NULL | Chave AES-256 do usuário, cifrada pela API com a chave-mestra do servidor. |
| versao | SMALLINT | NOT NULL | Permite rotação da chave. |
| criado_em / atualizado_em | TIMESTAMPTZ | NOT NULL | Auditoria. |

### `notificacoes_sistema` — avisos globais

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador. |
| admin_id | UUID | FK → usuarios, SET NULL, NULL | ADM que emitiu o aviso. Fica NULL se a conta do ADM for excluída (RN34). |
| titulo | VARCHAR(100) | NOT NULL | Título. |
| conteudo | TEXT | NOT NULL | Mensagem. |
| criado_em | TIMESTAMPTZ | NOT NULL | Emissão. |
| expira_em | TIMESTAMPTZ | NULL, > criado_em | Até quando aparece no app. |

### `feedbacks` — relatos e sugestões

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador. |
| usuario_id | UUID | FK → usuarios, CASCADE | Quem enviou. |
| admin_id | UUID | FK → usuarios, SET NULL | ADM que respondeu. |
| tipo | VARCHAR(20) | CHECK `BUG`/`SUGESTAO`/`OUTRO` | Classificação. |
| mensagem | TEXT | NOT NULL | Conteúdo. |
| resposta | TEXT | NULL | Resposta do ADM. |
| enviado_em | TIMESTAMPTZ | NOT NULL | Envio. |
| respondido_em | TIMESTAMPTZ | NULL, junto com `resposta` | Substitui o antigo booleano `respondido`. |

---

## 📱 PARTE 2 — Banco Local (SQLite)

Cada conta tem o próprio arquivo `kortex_<usuario_id>.db` (ADR-13). Tudo o que está no arquivo pertence ao dono dele, por isso as tabelas não têm `usuario_id`.

### Geral

#### `configuracoes` — preferências chave/valor

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| chave | TEXT | PK | Ex.: `usuario_id` (dono do arquivo, conferido ao abrir e ao restaurar), `modo_noturno`, `notificacoes_ativas`, `meta_peso_gramas`, `backup_google_email`, `backup_ultimo_em`. |
| valor | TEXT | NULL | Valor serializado. |
| atualizado_em | TEXT | NOT NULL | Última alteração. |

> Tokens OAuth do Google e o refresh token da API **não** ficam no SQLite: ficam no armazenamento seguro do Android (`expo-secure-store` / Keystore).

### Módulo Finanças

#### `contas` — contas e carteiras

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| nome | TEXT | NOT NULL | Ex.: "Conta Corrente (Nubank)". |
| tipo | TEXT | CHECK | `CORRENTE`, `CARTEIRA`, `POUPANCA`, `INVESTIMENTO`. |
| saldo_inicial_centavos | INTEGER | NOT NULL, padrão 0 | Saldo no momento do cadastro. |
| cor_hex | TEXT | `#RRGGBB` | Cor na interface (RN15). |
| icone_codigo | TEXT | NOT NULL | Ícone (RN15). |
| principal | INTEGER | 0/1; no máximo uma ativa (`ux_contas_principal`) | Conta sugerida por padrão no registro rápido. Não pode estar arquivada. |
| arquivada | INTEGER | 0/1 | Some das listas mas mantém o histórico (RN16). |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria e soft delete. Exclusão bloqueada se houver lançamentos ou transferências ativos (`trg_conta_exclusao`). |

#### `categorias_financeiras` — categorias e subcategorias

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| categoria_pai_id | TEXT | FK → categorias_financeiras, NULL, ≠ id | Preenchido = subcategoria (1 nível, mesmo tipo do pai, pai ativo — RN11). Validado no INSERT e no UPDATE. |
| nome | TEXT | NOT NULL, único por tipo/pai | Ex.: "Alimentação" › "Delivery". |
| tipo | TEXT | CHECK `RECEITA`/`DESPESA` | Separa as abas Entradas/Despesas. Só muda se não houver subcategorias nem lançamentos (`trg_categoria_tipo_upd`). |
| cor_hex / icone_codigo | TEXT | NOT NULL | Identificação visual (RN15). |
| padrao | INTEGER | 0/1 | 1 = criada pelo seed inicial do app. |
| arquivada | INTEGER | 0/1 | Alternativa à exclusão quando há lançamentos (RN16). |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria e soft delete. Exclusão bloqueada se houver lançamentos ou subcategorias ativos (`trg_categoria_exclusao`). |

#### `parcelamentos` — compras parceladas (RN36)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| descricao | TEXT | NOT NULL | Ex.: "TV Samsung". As parcelas recebem o sufixo "(n/N)". |
| valor_total_centavos | INTEGER | > 0, ≥ quantidade de parcelas | Valor da compra. |
| quantidade_parcelas | INTEGER | 2 a 48 | Número de parcelas geradas. |
| data_compra | TEXT | NOT NULL, data válida | Data local da compra; vencimento da 1ª parcela. |
| forma_pagamento | TEXT | NULL ou `DEBITO`/`CREDITO`/`PIX`/`DINHEIRO` | Repassada a todas as parcelas (RN38). |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria. Excluir a compra exclui as parcelas (`trg_parcelamento_exclusao`). |

#### `recorrencias` — regras de despesa recorrente (RN37)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| tipo | TEXT | `DESPESA` | Só despesas se repetem no MVP; a coluna existe para ampliar no futuro. |
| conta_id | TEXT | FK → contas, RESTRICT, conta ativa | Conta das ocorrências. |
| categoria_id | TEXT | FK → categorias_financeiras, RESTRICT, mesmo tipo | Categoria das ocorrências. |
| descricao | TEXT | NOT NULL | Ex.: "Aluguel". |
| valor_centavos | INTEGER | > 0 | Valor de cada ocorrência. |
| forma_pagamento | TEXT | NULL ou `DEBITO`/`CREDITO`/`PIX`/`DINHEIRO` | Repassada às ocorrências (RN38). |
| frequencia | TEXT | `SEMANAL`/`MENSAL`/`ANUAL` | Intervalo entre ocorrências. |
| data_inicio | TEXT | NOT NULL, data válida | Data local da 1ª ocorrência. |
| data_fim | TEXT | NULL, ≥ início | Última data possível; NULL = sem fim. |
| ultima_gerada_em | TEXT | NULL, data válida | Data da última ocorrência criada pelo gerador. |
| ativa | INTEGER | 0/1 | Desativada = para de gerar. |
| observacao | TEXT | NULL | Nota livre. |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria. |

#### `transacoes_financeiras` — receitas e despesas

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| conta_id | TEXT | FK → contas, RESTRICT, conta ativa | Conta movimentada (RN10). |
| categoria_id | TEXT | FK → categorias_financeiras, RESTRICT, categoria ativa | Categoria ou subcategoria (RN10). |
| tipo | TEXT | CHECK; igual ao da categoria (trigger) | `RECEITA` ou `DESPESA` (RN10). |
| descricao | TEXT | NOT NULL | Ex.: "Supermercado Carrefour". |
| valor_centavos | INTEGER | > 0 | Valor sempre positivo; o sinal vem do `tipo`. |
| data_prevista | TEXT | NOT NULL, data válida | Vencimento ou data esperada (data local). |
| data_efetivacao | TEXT | NULL, data válida | Quando foi paga/recebida (data local). NULL = pendente (RN12). Na tela: "Recebido" (receita) ou "Pago" (despesa). |
| forma_pagamento | TEXT | NULL ou `DEBITO`/`CREDITO`/`PIX`/`DINHEIRO` | Opcional. "Crédito" é só marcação, sem fatura (RN38). |
| parcelamento_id | TEXT | FK → parcelamentos, CASCADE, NULL | Preenchido = parcela de uma compra (RN36). Só em despesas. |
| parcela_numero | INTEGER | ≥ 1, ≤ quantidade de parcelas; junto com `parcelamento_id` | Número da parcela; único por compra. |
| recorrencia_id | TEXT | FK → recorrencias, SET NULL, NULL | Preenchido = ocorrência de uma despesa recorrente (RN37); única por regra e data. |
| observacao | TEXT | NULL | Nota livre. |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria e soft delete. Desfazer a exclusão exige conta e categoria ativas. |

Um lançamento é **avulso**, **parcela** ou **ocorrência recorrente**, nunca parcela e recorrente ao mesmo tempo (`CHECK`).

#### `transferencias` — movimentação entre contas (RN14)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| conta_origem_id | TEXT | FK → contas, RESTRICT, conta ativa | Conta debitada. |
| conta_destino_id | TEXT | FK → contas, RESTRICT, conta ativa, ≠ origem | Conta creditada. |
| valor_centavos | INTEGER | > 0 | Valor transferido. |
| data | TEXT | NOT NULL, data válida | Data da transferência (data local). |
| descricao | TEXT | NULL | Nota livre. |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria e soft delete. |

#### `tags` e `transacoes_tags`

| Tabela | Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- | :--- |
| tags | id | TEXT | PK | UUID. |
| | nome | TEXT | único entre as ativas | Ex.: "viagem-2026". |
| | criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria. |
| transacoes_tags | transacao_id | TEXT | PK, FK CASCADE | Transação. |
| | tag_id | TEXT | PK, FK CASCADE | Tag. |

#### Visão `vw_saldo_contas`

Saldo de cada conta = `saldo_inicial` + receitas efetivadas − despesas efetivadas + transferências recebidas − transferências enviadas (RN13). Expõe `arquivada`; o saldo global é a soma das linhas com `arquivada = 0`.

### Módulo Treinos

#### `pastas_rotinas` (RN22)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| nome | TEXT | NOT NULL | Ex.: "Jan - Mar/2026". |
| ordem | INTEGER | NOT NULL | Ordem de exibição. |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria. Excluir a pasta desagrupa as rotinas (`trg_pasta_rotinas_exclusao`). |

#### `exercicios` — catálogo

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| nome | TEXT | NOT NULL | Ex.: "Supino Reto (Halter)". |
| grupo_muscular | TEXT | NOT NULL | Filtro "Todos os Músculos". |
| equipamento | TEXT | NULL | Filtro "Todo o Equipamento" (`HALTER`, `BARRA`, `POLIA`, `MAQUINA`, `PESO_CORPORAL`…). |
| video_execucao_url | TEXT | NULL | Link de demonstração. |
| personalizado | INTEGER | 0/1, padrão 1 | 0 = exercício padrão do app (seed); 1 = criado pelo usuário. |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria. Exclusão bloqueada se o exercício estiver em rotina ativa; o histórico não bloqueia. |

#### `rotinas` — a ficha planejada (antiga `treinos`)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| pasta_id | TEXT | FK → pastas_rotinas, SET NULL, pasta ativa | Pasta da rotina. |
| nome | TEXT | NOT NULL | Ex.: "Peito/Tríceps". |
| local | TEXT | NULL | Ex.: "Panobianco". |
| ativa | INTEGER | 0/1 | Rotinas inativas não aparecem na agenda. |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria. |

#### `rotinas_dias_semana` — agenda (RN23)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| rotina_id | TEXT | PK, FK CASCADE | Rotina. |
| dia_semana | INTEGER | PK, 0–6 | 0 = domingo … 6 = sábado (igual ao `getDay()` local). Ex.: "Ter/Sex" → linhas 2 e 5. |

#### `rotinas_exercicios` — metas da ficha (antiga `itens_exercicios`)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| rotina_id | TEXT | FK → rotinas, CASCADE | Rotina. |
| exercicio_id | TEXT | FK → exercicios, RESTRICT, exercício ativo | Exercício. |
| ordem | INTEGER | único na rotina | Ordem de execução. |
| series_alvo | INTEGER | > 0 | Séries planejadas. |
| repeticoes_alvo | INTEGER | > 0 | Repetições planejadas. |
| carga_alvo_gramas | INTEGER | NULL ou ≥ 0 | NULL/0 para peso corporal ou alongamento (RN21). |
| descanso_segundos | INTEGER | ≥ 0 | Tempo de descanso. |
| criado_em / atualizado_em | TEXT | — | Auditoria. |

#### `sessoes_treino` — cada treino executado (RN19)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| rotina_id | TEXT | FK → rotinas, SET NULL | Rotina de origem (NULL = treino livre ou rotina excluída). |
| nome_rotina | TEXT | NOT NULL | Cópia do nome na data do treino, para o histórico não mudar. |
| data_local | TEXT | NOT NULL, data válida | Dia do treino no fuso do aparelho, no início. Usado na agenda (RN23, ADR-12). |
| iniciada_em | TEXT | NOT NULL, instante UTC | Início. |
| finalizada_em | TEXT | NULL, instante UTC, ≥ início | NULL = treino em andamento. Duração = fim − início. |
| observacao | TEXT | NULL | Nota livre. |
| criado_em / atualizado_em / excluido_em | TEXT | — | "Descartar treino" = excluir a sessão. |

#### `series_realizadas` — histórico de execução (RN19, RN24)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| sessao_id | TEXT | FK → sessoes_treino, CASCADE | Sessão. |
| exercicio_id | TEXT | FK → exercicios, RESTRICT | Exercício executado. |
| ordem_exercicio | INTEGER | NOT NULL | Posição do exercício na sessão. |
| numero_serie | INTEGER | > 0; único por sessão/ordem | Coluna "SÉRIE". |
| carga_gramas | INTEGER | NULL ou ≥ 0 | Coluna "KG". |
| repeticoes | INTEGER | ≥ 0 | Coluna "REPS". |
| concluida | INTEGER | 0/1 | Checkbox da série. |
| criado_em / atualizado_em | TEXT | — | Auditoria. |

#### `registros_peso` — evolução do peso corporal (RN25)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| data | TEXT | NOT NULL, data válida | Data da pesagem (data local). |
| peso_gramas | INTEGER | > 0 | Peso. A meta fica em `configuracoes.meta_peso_gramas`. |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria. |

#### Visão `vw_recordes_exercicios`

Por exercício, só com séries concluídas de sessões finalizadas (RN24):

| Coluna | Significado |
| :--- | :--- |
| recorde_carga_gramas | Maior carga em uma série. |
| recorde_volume_gramas | Maior soma de carga × repetições do exercício numa única sessão. |
| recorde_repeticoes | Maior número de repetições em uma série. É o recorde exibido quando o exercício não tem carga (RN21). |

A coluna "ANTERIOR" da tela de treino vem da última sessão finalizada com o mesmo exercício e número de série.

### Módulo Tarefas / Atividades

#### `pastas_tarefas` (antiga `categorias_tarefas`)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| nome | TEXT | único entre as ativas | Ex.: "Faculdade". |
| icone | TEXT | NOT NULL | Emoji ou código do ícone (ex.: 🎓). |
| cor_hex | TEXT | NULL ou `#RRGGBB` | Cor opcional. |
| padrao | INTEGER | 0/1; só uma; imutável | 1 = "Tarefas Pessoais"; não pode ser excluída nem perder o indicador (RN27). |
| ordem | INTEGER | NOT NULL | Ordem de exibição. |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria. Exclusão bloqueada se houver tarefas ativas (inclusive arquivadas). |

#### `tarefas`

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| pasta_id | TEXT | FK → pastas_tarefas, RESTRICT, pasta ativa | Pasta (padrão: "Tarefas Pessoais"). |
| titulo | TEXT | NOT NULL | Título. |
| descricao | TEXT | NULL | Descrição / notas. |
| data_prazo | TEXT | NULL, data válida | Dia do prazo (data local). NULL = sem prazo. Base do progresso diário (RN29). |
| hora_prazo | TEXT | NULL, `HH:MM`; exige `data_prazo` | Hora local do prazo, opcional. |
| prioridade | TEXT | CHECK `BAIXA`/`MEDIA`/`ALTA` | Padrão `MEDIA` (RN28). |
| concluida_em | TEXT | NULL, instante UTC | NULL = pendente; desmarcar volta para NULL (RN26). |
| arquivada_em | TEXT | NULL, instante UTC | Tarefas arquivadas saem das listas (RF10). |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria e soft delete. |

---

## ⚙️ Triggers do banco local

| Trigger | Tabela | Regra |
| :--- | :--- | :--- |
| `trg_transacao_tipo_categoria_ins/_upd` | transacoes_financeiras | Tipo da transação = tipo da categoria (RN10). |
| `trg_transacao_ref_ativa_ins/_upd` | transacoes_financeiras | Lançamento ativo só com conta e categoria ativas (RN33). |
| `trg_subcategoria_valida_ins/_upd` | categorias_financeiras | Subcategoria: mesmo tipo, pai ativo, 1 nível (RN11). |
| `trg_categoria_tipo_upd` | categorias_financeiras | Tipo só muda sem subcategorias e sem lançamentos (RN10, RN11). |
| `trg_categoria_exclusao` | categorias_financeiras | Não exclui com lançamentos, subcategorias ou recorrências ativos (RN16). |
| `trg_parcela_numero_valido` | transacoes_financeiras | Número da parcela ≤ quantidade de parcelas (RN36). |
| `trg_parcelamento_exclusao` | parcelamentos | Excluir a compra exclui todas as parcelas (RN36). |
| `trg_recorrencia_valida_ins/_upd` | recorrencias | Tipo igual ao da categoria; conta e categoria ativas (RN10, RN37). |
| `trg_transferencia_ref_ativa_ins/_upd` | transferencias | Só entre contas ativas (RN33). |
| `trg_conta_exclusao` | contas | Não exclui com lançamentos, transferências ou recorrências ativos (RN16). |
| `trg_rotina_ref_ativa`, `trg_rotina_ref_ativa_ins` | rotinas | Rotina só em pasta ativa (RN33). |
| `trg_pasta_rotinas_exclusao` | pastas_rotinas | Excluir a pasta desagrupa as rotinas (RN22). |
| `trg_rotina_exercicio_ref_ativa_ins/_upd` | rotinas_exercicios | Não adiciona exercício excluído (RN33). |
| `trg_exercicio_exclusao` | exercicios | Não exclui exercício usado em rotina ativa (RN33). |
| `trg_tarefa_ref_ativa_ins/_upd` | tarefas | Tarefa ativa só em pasta ativa (RN33). |
| `trg_pasta_padrao_nao_exclui`, `trg_pasta_padrao_nao_delete` | pastas_tarefas | Pasta padrão não é excluída (RN27). |
| `trg_pasta_padrao_imutavel` | pastas_tarefas | Indicador `padrao` não muda depois de criado (RN27). |
| `trg_pasta_tarefas_exclusao` | pastas_tarefas | Não exclui pasta com tarefas (RN27). |

---

## 🔄 Mapa de mudanças

### v4 (parcelas, recorrência, forma de pagamento e cadastro)

| Antes | Agora | Motivo |
| :--- | :--- | :--- |
| — | Tabela `parcelamentos` + `transacoes.parcelamento_id` / `parcela_numero` | Despesa parcelada (RN36). |
| — | Tabela `recorrencias` + `transacoes.recorrencia_id` | Despesa recorrente (RN37). |
| — | `transacoes.forma_pagamento` (Débito, Crédito, Pix, Dinheiro) | "Pago no crédito" como marcação, sem fatura (RN38). |
| `usuarios.nome` + `data_nascimento` | `usuarios.nome` + `sobrenome`; sem data de nascimento | Cadastro do protótipo; dado não usado (ADR-07). |

### v3 (correções de integridade, fuso e exclusão de conta)

| Antes | Agora | Motivo |
| :--- | :--- | :--- |
| Um banco local com `usuario_id` em toda tabela | Um arquivo `kortex_<usuario_id>.db` por conta, sem `usuario_id` | Backup e exclusão isolados por usuário (ADR-13). |
| `exercicios.usuario_id` NULL = padrão | `exercicios.personalizado` 0/1 | Consequência do ADR-13. |
| Datas/horas "ISO-8601 em UTC" | Data local, hora local e instante UTC com milissegundos, validados por `CHECK` | O dia do treino/tarefa mudava com o fuso (ADR-12). |
| `sessoes_treino` sem data local | `data_local` | Agenda do dia (RN23). |
| `tarefas.data_prazo` data/hora | `data_prazo` (data local) + `hora_prazo` | Progresso do dia (RN29). |
| FKs RESTRICT ignoradas pelo soft delete | Triggers de exclusão e de referência ativa | RN16, RN27, RN33. |
| Trigger de subcategoria só no INSERT | Também no UPDATE, e trava de mudança de tipo | RN10, RN11. |
| Pasta padrão desmarcável | `padrao` imutável | RN27. |
| Várias contas principais | No máximo uma, não arquivada | Registro rápido. |
| Recordes de carga e volume | + recorde de repetições | Exercícios com peso corporal (RN24). |
| — | Finalidade `EXCLUIR_CONTA`; `notificacoes_sistema.admin_id` SET NULL | Exclusão de conta (RN34). |
| Tabelas no schema `public`, API conectando como `postgres` | Schema privado `kortex`, papel `kortex_api` só com DML, RLS com policy para esse papel | Privilégio mínimo (ADR-05). |
| — | `usuarios.falhas_login`, `usuarios.bloqueado_ate` | Proteção contra força bruta (RN35). |
| `sqlite_local.sql` | `001_inicial.sql` + `002_dados_padrao.sql` | Migrações numeradas (ADR-09) e dados padrão. |

### v2

| Antes | Agora | Motivo |
| :--- | :--- | :--- |
| `valor REAL` | `valor_centavos INTEGER` | Ponto flutuante gera erro de arredondamento em dinheiro (ADR-08). |
| Transação sem conta | `conta_id` obrigatório + tabela `contas` | RN10 e tela "Contas" do protótipo. |
| — | `transferencias` | RN14 e tela "Transferência". |
| — | `categoria_pai_id`, `tipo` em categorias | Subcategorias e abas Entradas/Despesas do protótipo. |
| — | `data_prevista` / `data_efetivacao` | Toggle "Recebido" e campo "Vencimento" do protótipo. |
| `treinos` | `rotinas` + `pastas_rotinas` + `rotinas_dias_semana` | Pastas (RN22) e agenda semanal (RF04, RN23). |
| `itens_exercicios` (histórico misturado com a meta) | `rotinas_exercicios` (meta) + `sessoes_treino` + `series_realizadas` (histórico) | O histórico se perdia a cada treino (RN19). |
| — | `registros_peso` | Tela "Estatísticas" → Evolução de Peso. |
| `categorias_tarefas` | `pastas_tarefas` | O protótipo trata como pastas, com pasta padrão. |
| `concluida BOOLEAN` | `concluida_em`, `arquivada_em` | Progresso do dia (RN29) e arquivamento (RF10). |
| — | `criado_em`, `atualizado_em`, `excluido_em` | Auditoria, soft delete e base para sincronização futura (ADR-09). |
| `uuid_generate_v4()` | `gen_random_uuid()` | Nativo no PostgreSQL 13+, sem extensão. |
| `TIMESTAMP` | `TIMESTAMPTZ` | Evita ambiguidade de fuso horário. |
| `respondido BOOLEAN` | `resposta` + `respondido_em` | Guarda a resposta e quando ela foi dada. |
| RLS desativado | RLS ativado sem policies + `REVOKE` | Bloqueia a API pública do Supabase (ADR-05). |
| — | `refresh_tokens`, `codigos_verificacao`, `chaves_backup` | Login offline (ADR-10), RN05 e backup cifrado (ADR-11). |
| Dicionário `notificacoes` × DDL `notificacoes_sistema` | `notificacoes_sistema` em tudo | Nome padronizado. |
