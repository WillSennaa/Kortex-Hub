# 🗄️ Dicionário de Dados e Scripts DDL — Kortex Hub

O banco do Kortex Hub é dividido em duas partes (ADR-01):

| Parte | SGBD | O que guarda | Script |
| :--- | :--- | :--- | :--- |
| ☁️ Nuvem | Supabase (PostgreSQL) | Conta, autenticação, avisos globais, feedbacks e chave de backup | [`supabase_nuvem.sql`](supabase_nuvem.sql) |
| 📱 Local | SQLite (no dispositivo) | Todos os dados dos módulos (Finanças, Treinos, Tarefas) | [`sqlite_local.sql`](sqlite_local.sql) |

> Os arquivos `.sql` são a **fonte da verdade**. Este documento explica o significado de cada tabela e coluna.

### Convenções gerais

| Regra | Como é aplicada | Referência |
| :--- | :--- | :--- |
| Chave primária | UUID v4 (`UUID` no Postgres, `TEXT` no SQLite), gerado no dispositivo | ADR-04 |
| Dinheiro | `INTEGER` em **centavos** no SQLite (R$ 12,50 → `1250`) | ADR-08 |
| Peso e carga | `INTEGER` em **gramas** (32,5 kg → `32500`) | ADR-08 |
| Datas (SQLite) | `TEXT` no formato `YYYY-MM-DD`; data/hora em ISO-8601 UTC (`2026-10-21T13:00:00Z`) | ADR-09 |
| Booleanos (SQLite) | `INTEGER` 0/1 com `CHECK` | — |
| Auditoria | `criado_em`, `atualizado_em` e `excluido_em` (soft delete) nas tabelas principais | ADR-09 |
| Versão do schema local | `PRAGMA user_version`; cada mudança vira uma migração numerada | ADR-09 |
| Chaves estrangeiras (SQLite) | Cada conexão deve executar `PRAGMA foreign_keys = ON;` | — |
| `usuario_id` local | UUID do usuário no Supabase, sem FK física (a tabela `usuarios` não existe no SQLite) | ADR-01 |

---

## ☁️ PARTE 1 — Banco em Nuvem (Supabase / PostgreSQL)

**Acesso:** somente pela Web API em C#. O RLS fica **ativado e sem policies**, o que bloqueia a API pública do Supabase (ADR-05).

### `usuarios` — contas (Single Table Inheritance, ADR-07)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador do usuário. |
| nome | VARCHAR(100) | NOT NULL | Nome de exibição. |
| email | VARCHAR(150) | NOT NULL, UNIQUE (`lower(email)`) | Login; único sem diferenciar maiúsculas (RN01). |
| senha_hash | VARCHAR(255) | NOT NULL | Hash BCrypt/Argon2 gerado pela API (RN03). |
| email_verificado_em | TIMESTAMPTZ | NULL | Quando o e-mail foi confirmado. |
| status | VARCHAR(20) | NOT NULL, CHECK `ATIVO`/`INATIVO` | Conta ativa ou desativada. |
| tipo_usuario | VARCHAR(20) | NOT NULL, CHECK `COMUM`/`ADMIN` | Discriminador do STI. |
| data_nascimento | DATE | NULL | Só perfil Comum. |
| nivel_permissao | VARCHAR(50) | NULL | Obrigatório para ADMIN, proibido para COMUM (`ck_usuarios_sti`). |
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

### `codigos_verificacao` — códigos enviados por e-mail (RN05)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador. |
| usuario_id | UUID | FK → usuarios, CASCADE | Usuário que solicitou. |
| finalidade | VARCHAR(30) | CHECK | `CONFIRMAR_EMAIL`, `TROCAR_EMAIL`, `TROCAR_SENHA`, `RECUPERAR_SENHA`. |
| codigo_hash | VARCHAR(255) | NOT NULL | Hash do código numérico. |
| novo_email | VARCHAR(150) | Obrigatório só em `TROCAR_EMAIL` | E-mail que será aplicado após a confirmação. |
| tentativas | SMALLINT | 0 a 5 | Tentativas erradas; ao chegar em 5 o código é invalidado. |
| criado_em / expira_em | TIMESTAMPTZ | NOT NULL | Validade sugerida: 15 minutos. |
| usado_em | TIMESTAMPTZ | NULL | Uso único. |

### `chaves_backup` — chave de cifragem do backup (ADR-11)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| usuario_id | UUID | PK, FK → usuarios, CASCADE | Uma chave por usuário. |
| chave_cifrada | BYTEA | NOT NULL | Chave AES-256 do usuário, cifrada pela API com a chave-mestra do servidor. |
| versao | SMALLINT | NOT NULL | Permite rotação da chave. |
| criado_em / atualizado_em | TIMESTAMPTZ | NOT NULL | Auditoria. |

### `notificacoes_sistema` — avisos globais

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador. |
| admin_id | UUID | FK → usuarios, RESTRICT | ADM que emitiu o aviso. |
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

### Geral

#### `configuracoes` — preferências chave/valor

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| usuario_id | TEXT | PK (composta) | Usuário. |
| chave | TEXT | PK (composta) | Ex.: `modo_noturno`, `notificacoes_ativas`, `meta_peso_gramas`, `backup_google_email`, `backup_ultimo_em`. |
| valor | TEXT | NULL | Valor serializado. |
| atualizado_em | TEXT | NOT NULL | Última alteração. |

> Tokens OAuth do Google e o refresh token da API **não** ficam no SQLite: ficam no armazenamento seguro do Android (`expo-secure-store` / Keystore).

### Módulo Finanças

#### `contas` — contas e carteiras

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| usuario_id | TEXT | NOT NULL | Dono. |
| nome | TEXT | NOT NULL | Ex.: "Conta Corrente (Nubank)". |
| tipo | TEXT | CHECK | `CORRENTE`, `CARTEIRA`, `POUPANCA`, `INVESTIMENTO`. |
| saldo_inicial_centavos | INTEGER | NOT NULL, padrão 0 | Saldo no momento do cadastro. |
| cor_hex | TEXT | `#RRGGBB` | Cor na interface (RN15). |
| icone_codigo | TEXT | NOT NULL | Ícone (RN15). |
| principal | INTEGER | 0/1 | Conta sugerida por padrão no registro rápido. |
| arquivada | INTEGER | 0/1 | Some das listas mas mantém o histórico (RN16). |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria e soft delete. |

#### `categorias_financeiras` — categorias e subcategorias

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| usuario_id | TEXT | NOT NULL | Dono. |
| categoria_pai_id | TEXT | FK → categorias_financeiras, NULL | Preenchido = subcategoria (1 nível, mesmo tipo do pai — RN11). |
| nome | TEXT | NOT NULL, único por usuário/tipo/pai | Ex.: "Alimentação" › "Delivery". |
| tipo | TEXT | CHECK `RECEITA`/`DESPESA` | Separa as abas Entradas/Despesas. |
| cor_hex / icone_codigo | TEXT | NOT NULL | Identificação visual (RN15). |
| padrao | INTEGER | 0/1 | 1 = criada pelo seed inicial do app. |
| arquivada | INTEGER | 0/1 | Alternativa à exclusão quando há lançamentos (RN16). |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria e soft delete. |

#### `transacoes_financeiras` — receitas e despesas

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| usuario_id | TEXT | NOT NULL | Dono. |
| conta_id | TEXT | FK → contas, RESTRICT | Conta movimentada (RN10). |
| categoria_id | TEXT | FK → categorias_financeiras, RESTRICT | Categoria ou subcategoria (RN10). |
| tipo | TEXT | CHECK; igual ao da categoria (trigger) | `RECEITA` ou `DESPESA` (RN10). |
| descricao | TEXT | NOT NULL | Ex.: "Supermercado Carrefour". |
| valor_centavos | INTEGER | > 0 | Valor sempre positivo; o sinal vem do `tipo`. |
| data_prevista | TEXT | NOT NULL | Vencimento ou data esperada. |
| data_efetivacao | TEXT | NULL | Quando foi paga/recebida. NULL = pendente (RN12). |
| observacao | TEXT | NULL | Nota livre. |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria e soft delete. |

#### `transferencias` — movimentação entre contas (RN14)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| usuario_id | TEXT | NOT NULL | Dono. |
| conta_origem_id | TEXT | FK → contas, RESTRICT | Conta debitada. |
| conta_destino_id | TEXT | FK → contas, RESTRICT, ≠ origem | Conta creditada. |
| valor_centavos | INTEGER | > 0 | Valor transferido. |
| data | TEXT | NOT NULL | Data da transferência. |
| descricao | TEXT | NULL | Nota livre. |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria e soft delete. |

#### `tags` e `transacoes_tags`

| Tabela | Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- | :--- |
| tags | id | TEXT | PK | UUID. |
| | usuario_id | TEXT | NOT NULL | Dono. |
| | nome | TEXT | único por usuário | Ex.: "viagem-2026". |
| | criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria. |
| transacoes_tags | transacao_id | TEXT | PK, FK CASCADE | Transação. |
| | tag_id | TEXT | PK, FK CASCADE | Tag. |

#### Visão `vw_saldo_contas`

Saldo de cada conta = `saldo_inicial` + receitas efetivadas − despesas efetivadas + transferências recebidas − transferências enviadas (RN13). O saldo global é a soma das contas não arquivadas.

### Módulo Treinos

#### `pastas_rotinas` (RN22)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| usuario_id | TEXT | NOT NULL | Dono. |
| nome | TEXT | NOT NULL | Ex.: "Jan - Mar/2026". |
| ordem | INTEGER | NOT NULL | Ordem de exibição. |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria. |

#### `exercicios` — catálogo

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| usuario_id | TEXT | NULL | NULL = exercício padrão do app; preenchido = criado pelo usuário. |
| nome | TEXT | NOT NULL | Ex.: "Supino Reto (Halter)". |
| grupo_muscular | TEXT | NOT NULL | Filtro "Todos os Músculos". |
| equipamento | TEXT | NULL | Filtro "Todo o Equipamento" (`HALTER`, `BARRA`, `POLIA`, `MAQUINA`, `PESO_CORPORAL`…). |
| video_execucao_url | TEXT | NULL | Link de demonstração. |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria. |

#### `rotinas` — a ficha planejada (antiga `treinos`)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| usuario_id | TEXT | NOT NULL | Dono. |
| pasta_id | TEXT | FK → pastas_rotinas, SET NULL | Pasta da rotina. |
| nome | TEXT | NOT NULL | Ex.: "Peito/Tríceps". |
| local | TEXT | NULL | Ex.: "Panobianco". |
| ativa | INTEGER | 0/1 | Rotinas inativas não aparecem na agenda. |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria. |

#### `rotinas_dias_semana` — agenda (RN23)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| rotina_id | TEXT | PK, FK CASCADE | Rotina. |
| dia_semana | INTEGER | PK, 0–6 | 0 = domingo … 6 = sábado. Ex.: "Ter/Sex" → linhas 2 e 5. |

#### `rotinas_exercicios` — metas da ficha (antiga `itens_exercicios`)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| rotina_id | TEXT | FK → rotinas, CASCADE | Rotina. |
| exercicio_id | TEXT | FK → exercicios, RESTRICT | Exercício. |
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
| usuario_id | TEXT | NOT NULL | Dono. |
| rotina_id | TEXT | FK → rotinas, SET NULL | Rotina de origem (NULL = treino livre ou rotina excluída). |
| nome_rotina | TEXT | NOT NULL | Cópia do nome na data do treino, para o histórico não mudar. |
| iniciada_em | TEXT | NOT NULL | Início. |
| finalizada_em | TEXT | NULL, ≥ início | NULL = treino em andamento. Duração = fim − início. |
| observacao | TEXT | NULL | Nota livre. |
| criado_em / atualizado_em / excluido_em | TEXT | — | "Descartar treino" = excluir a sessão. |

#### `series_realizadas` — histórico de execução (RN19, RN24)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| sessao_id | TEXT | FK → sessoes_treino, CASCADE | Sessão. |
| exercicio_id | TEXT | FK → exercicios, RESTRICT | Exercício executado. |
| ordem_exercicio | INTEGER | NOT NULL | Posição do exercício na sessão. |
| numero_serie | INTEGER | > 0; único por sessão/exercício | Coluna "SÉRIE". |
| carga_gramas | INTEGER | NULL ou ≥ 0 | Coluna "KG". |
| repeticoes | INTEGER | ≥ 0 | Coluna "REPS". |
| concluida | INTEGER | 0/1 | Checkbox da série. |
| criado_em / atualizado_em | TEXT | — | Auditoria. |

#### `registros_peso` — evolução do peso corporal (RN25)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| usuario_id | TEXT | NOT NULL | Dono. |
| data | TEXT | NOT NULL | Data da pesagem. |
| peso_gramas | INTEGER | > 0 | Peso. A meta fica em `configuracoes.meta_peso_gramas`. |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria. |

#### Visão `vw_recordes_exercicios`

Por exercício: **recorde de carga** (maior carga em uma série concluída) e **recorde de volume** (maior soma de carga × repetições do exercício numa única sessão). A coluna "ANTERIOR" da tela de treino vem da última sessão finalizada com o mesmo exercício e número de série.

### Módulo Tarefas / Atividades

#### `pastas_tarefas` (antiga `categorias_tarefas`)

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| usuario_id | TEXT | NOT NULL | Dono. |
| nome | TEXT | único por usuário | Ex.: "Faculdade". |
| icone | TEXT | NOT NULL | Emoji ou código do ícone (ex.: 🎓). |
| cor_hex | TEXT | NULL ou `#RRGGBB` | Cor opcional. |
| padrao | INTEGER | 0/1; só uma por usuário | 1 = "Tarefas Pessoais"; não pode ser excluída (RN27, trigger). |
| ordem | INTEGER | NOT NULL | Ordem de exibição. |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria. |

#### `tarefas`

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| id | TEXT | PK | UUID. |
| usuario_id | TEXT | NOT NULL | Dono. |
| pasta_id | TEXT | FK → pastas_tarefas, RESTRICT | Pasta (padrão: "Tarefas Pessoais"). |
| titulo | TEXT | NOT NULL | Título. |
| descricao | TEXT | NULL | Descrição / notas. |
| data_prazo | TEXT | NULL | Data/hora limite. |
| prioridade | TEXT | CHECK `BAIXA`/`MEDIA`/`ALTA` | Padrão `MEDIA` (RN28). |
| concluida_em | TEXT | NULL | NULL = pendente; desmarcar volta para NULL (RN26). |
| arquivada_em | TEXT | NULL | Tarefas arquivadas saem das listas (RF10). |
| criado_em / atualizado_em / excluido_em | TEXT | — | Auditoria e soft delete. |

---

## 🔄 Mapa de mudanças em relação à versão anterior

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
