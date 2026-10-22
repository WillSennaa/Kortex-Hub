-- =====================================================================
-- KORTEX HUB — BANCO LOCAL (SQLite, no dispositivo do usuário)
-- Versão do schema: 1  (controlada via PRAGMA user_version — ADR-09)
-- =====================================================================
-- Convenções (ADR-04, ADR-08, ADR-09):
--   * PK: UUID v4 gerado no app, armazenado como TEXT.
--   * Datas: TEXT 'YYYY-MM-DD'. Data/hora: TEXT ISO-8601 em UTC
--     ('YYYY-MM-DDTHH:MM:SSZ').
--   * Dinheiro: INTEGER em CENTAVOS (R$ 12,50 -> 1250). Nunca REAL.
--   * Peso/carga: INTEGER em GRAMAS (32,5 kg -> 32500).
--   * Booleanos: INTEGER 0/1 com CHECK.
--   * Auditoria em toda tabela "raiz": criado_em, atualizado_em,
--     excluido_em (soft delete — NULL = registro ativo).
--   * usuario_id: UUID do usuário vindo do Supabase (sem FK física,
--     pois a tabela usuarios não existe no banco local).
--
-- IMPORTANTE: o SQLite só respeita FOREIGN KEY se cada conexão
-- executar "PRAGMA foreign_keys = ON;" ao abrir.
-- =====================================================================

PRAGMA foreign_keys = ON;
PRAGMA user_version = 1;

-- =====================================================================
-- CONFIGURAÇÕES GERAIS DO APP (chave/valor por usuário)
-- Ex.: modo_noturno, notificacoes_ativas, meta_peso_gramas,
--      backup_google_email, backup_ultimo_em
-- Tokens OAuth do Google NÃO ficam aqui: vão para o armazenamento
-- seguro do sistema (expo-secure-store / Android Keystore).
-- =====================================================================
CREATE TABLE configuracoes (
    usuario_id      TEXT NOT NULL,
    chave           TEXT NOT NULL,
    valor           TEXT,
    atualizado_em   TEXT NOT NULL,
    PRIMARY KEY (usuario_id, chave)
);

-- =====================================================================
-- MÓDULO: FINANÇAS
-- =====================================================================
CREATE TABLE contas (
    id                      TEXT PRIMARY KEY,
    usuario_id              TEXT NOT NULL,
    nome                    TEXT NOT NULL,
    tipo                    TEXT NOT NULL
                            CHECK (tipo IN ('CORRENTE','CARTEIRA','POUPANCA','INVESTIMENTO')),
    saldo_inicial_centavos  INTEGER NOT NULL DEFAULT 0,
    cor_hex                 TEXT NOT NULL CHECK (cor_hex GLOB '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'),
    icone_codigo            TEXT NOT NULL,
    principal               INTEGER NOT NULL DEFAULT 0 CHECK (principal IN (0,1)),
    arquivada               INTEGER NOT NULL DEFAULT 0 CHECK (arquivada IN (0,1)),
    criado_em               TEXT NOT NULL,
    atualizado_em           TEXT NOT NULL,
    excluido_em             TEXT
);

CREATE TABLE categorias_financeiras (
    id                  TEXT PRIMARY KEY,
    usuario_id          TEXT NOT NULL,
    categoria_pai_id    TEXT,               -- NULL = categoria; preenchido = subcategoria (1 nível)
    nome                TEXT NOT NULL,
    tipo                TEXT NOT NULL CHECK (tipo IN ('RECEITA','DESPESA')),
    cor_hex             TEXT NOT NULL CHECK (cor_hex GLOB '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'),
    icone_codigo        TEXT NOT NULL,
    padrao              INTEGER NOT NULL DEFAULT 0 CHECK (padrao IN (0,1)),   -- 1 = criada pelo seed do app
    arquivada           INTEGER NOT NULL DEFAULT 0 CHECK (arquivada IN (0,1)),
    criado_em           TEXT NOT NULL,
    atualizado_em       TEXT NOT NULL,
    excluido_em         TEXT,
    FOREIGN KEY (categoria_pai_id) REFERENCES categorias_financeiras(id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX ux_categorias_fin_nome
    ON categorias_financeiras (usuario_id, tipo, COALESCE(categoria_pai_id, ''), nome COLLATE NOCASE)
    WHERE excluido_em IS NULL;

CREATE TABLE transacoes_financeiras (
    id                  TEXT PRIMARY KEY,
    usuario_id          TEXT NOT NULL,
    conta_id            TEXT NOT NULL,
    categoria_id        TEXT NOT NULL,
    tipo                TEXT NOT NULL CHECK (tipo IN ('RECEITA','DESPESA')),
    descricao           TEXT NOT NULL,
    valor_centavos      INTEGER NOT NULL CHECK (valor_centavos > 0),
    data_prevista       TEXT NOT NULL,      -- vencimento / data esperada
    data_efetivacao     TEXT,               -- NULL = pendente; preenchida = paga/recebida
    observacao          TEXT,
    criado_em           TEXT NOT NULL,
    atualizado_em       TEXT NOT NULL,
    excluido_em         TEXT,
    FOREIGN KEY (conta_id)     REFERENCES contas(id)                 ON DELETE RESTRICT,
    FOREIGN KEY (categoria_id) REFERENCES categorias_financeiras(id) ON DELETE RESTRICT
);

CREATE INDEX ix_transacoes_data  ON transacoes_financeiras (usuario_id, data_prevista);
CREATE INDEX ix_transacoes_conta ON transacoes_financeiras (conta_id);
CREATE INDEX ix_transacoes_cat   ON transacoes_financeiras (categoria_id);

-- RN10: o tipo da transação deve ser igual ao tipo da categoria
CREATE TRIGGER trg_transacao_tipo_categoria_ins
BEFORE INSERT ON transacoes_financeiras
WHEN NEW.tipo <> (SELECT tipo FROM categorias_financeiras WHERE id = NEW.categoria_id)
BEGIN
    SELECT RAISE(ABORT, 'Tipo da transação difere do tipo da categoria');
END;

CREATE TRIGGER trg_transacao_tipo_categoria_upd
BEFORE UPDATE OF tipo, categoria_id ON transacoes_financeiras
WHEN NEW.tipo <> (SELECT tipo FROM categorias_financeiras WHERE id = NEW.categoria_id)
BEGIN
    SELECT RAISE(ABORT, 'Tipo da transação difere do tipo da categoria');
END;

-- RN11: subcategoria tem o mesmo tipo da categoria-pai e só 1 nível
CREATE TRIGGER trg_subcategoria_valida
BEFORE INSERT ON categorias_financeiras
WHEN NEW.categoria_pai_id IS NOT NULL AND (
       NEW.tipo <> (SELECT tipo FROM categorias_financeiras WHERE id = NEW.categoria_pai_id)
    OR (SELECT categoria_pai_id FROM categorias_financeiras WHERE id = NEW.categoria_pai_id) IS NOT NULL)
BEGIN
    SELECT RAISE(ABORT, 'Subcategoria inválida (tipo diferente do pai ou mais de 1 nível)');
END;

CREATE TABLE transferencias (
    id                  TEXT PRIMARY KEY,
    usuario_id          TEXT NOT NULL,
    conta_origem_id     TEXT NOT NULL,
    conta_destino_id    TEXT NOT NULL,
    valor_centavos      INTEGER NOT NULL CHECK (valor_centavos > 0),
    data                TEXT NOT NULL,
    descricao           TEXT,
    criado_em           TEXT NOT NULL,
    atualizado_em       TEXT NOT NULL,
    excluido_em         TEXT,
    CHECK (conta_origem_id <> conta_destino_id),
    FOREIGN KEY (conta_origem_id)  REFERENCES contas(id) ON DELETE RESTRICT,
    FOREIGN KEY (conta_destino_id) REFERENCES contas(id) ON DELETE RESTRICT
);

CREATE INDEX ix_transferencias_data ON transferencias (usuario_id, data);

CREATE TABLE tags (
    id              TEXT PRIMARY KEY,
    usuario_id      TEXT NOT NULL,
    nome            TEXT NOT NULL,
    criado_em       TEXT NOT NULL,
    atualizado_em   TEXT NOT NULL,
    excluido_em     TEXT
);

CREATE UNIQUE INDEX ux_tags_nome ON tags (usuario_id, nome COLLATE NOCASE) WHERE excluido_em IS NULL;

CREATE TABLE transacoes_tags (
    transacao_id    TEXT NOT NULL,
    tag_id          TEXT NOT NULL,
    PRIMARY KEY (transacao_id, tag_id),
    FOREIGN KEY (transacao_id) REFERENCES transacoes_financeiras(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id)       REFERENCES tags(id)                   ON DELETE CASCADE
);

-- RN13 / RN14: saldo de cada conta = saldo inicial
--   + receitas efetivadas − despesas efetivadas
--   + transferências recebidas − transferências enviadas
CREATE VIEW vw_saldo_contas AS
SELECT
    c.id AS conta_id,
    c.usuario_id,
    c.nome,
    c.saldo_inicial_centavos
    + COALESCE((SELECT SUM(CASE t.tipo WHEN 'RECEITA' THEN t.valor_centavos ELSE -t.valor_centavos END)
                  FROM transacoes_financeiras t
                 WHERE t.conta_id = c.id AND t.data_efetivacao IS NOT NULL AND t.excluido_em IS NULL), 0)
    + COALESCE((SELECT SUM(tr.valor_centavos) FROM transferencias tr
                 WHERE tr.conta_destino_id = c.id AND tr.excluido_em IS NULL), 0)
    - COALESCE((SELECT SUM(tr.valor_centavos) FROM transferencias tr
                 WHERE tr.conta_origem_id = c.id AND tr.excluido_em IS NULL), 0)
    AS saldo_centavos
FROM contas c
WHERE c.excluido_em IS NULL;

-- =====================================================================
-- MÓDULO: TREINOS
-- =====================================================================
CREATE TABLE pastas_rotinas (
    id              TEXT PRIMARY KEY,
    usuario_id      TEXT NOT NULL,
    nome            TEXT NOT NULL,          -- ex.: "Jan - Mar/2026"
    ordem           INTEGER NOT NULL DEFAULT 0,
    criado_em       TEXT NOT NULL,
    atualizado_em   TEXT NOT NULL,
    excluido_em     TEXT
);

-- Catálogo: usuario_id NULL = exercício padrão (seed do app);
-- preenchido = exercício personalizado criado pelo usuário.
CREATE TABLE exercicios (
    id                  TEXT PRIMARY KEY,
    usuario_id          TEXT,
    nome                TEXT NOT NULL,
    grupo_muscular      TEXT NOT NULL,
    equipamento         TEXT,               -- ex.: 'HALTER','BARRA','POLIA','MAQUINA','PESO_CORPORAL'
    video_execucao_url  TEXT,
    criado_em           TEXT NOT NULL,
    atualizado_em       TEXT NOT NULL,
    excluido_em         TEXT
);

CREATE INDEX ix_exercicios_nome ON exercicios (nome COLLATE NOCASE);

-- Rotina = a "ficha" planejada (antiga tabela treinos)
CREATE TABLE rotinas (
    id              TEXT PRIMARY KEY,
    usuario_id      TEXT NOT NULL,
    pasta_id        TEXT,
    nome            TEXT NOT NULL,          -- ex.: "Peito/Tríceps"
    local           TEXT,                   -- ex.: "Panobianco"
    ativa           INTEGER NOT NULL DEFAULT 1 CHECK (ativa IN (0,1)),
    criado_em       TEXT NOT NULL,
    atualizado_em   TEXT NOT NULL,
    excluido_em     TEXT,
    FOREIGN KEY (pasta_id) REFERENCES pastas_rotinas(id) ON DELETE SET NULL
);

-- Agenda semanal da rotina (RN23). 0 = domingo ... 6 = sábado
CREATE TABLE rotinas_dias_semana (
    rotina_id       TEXT NOT NULL,
    dia_semana      INTEGER NOT NULL CHECK (dia_semana BETWEEN 0 AND 6),
    PRIMARY KEY (rotina_id, dia_semana),
    FOREIGN KEY (rotina_id) REFERENCES rotinas(id) ON DELETE CASCADE
);

-- Exercícios planejados da rotina (antiga itens_exercicios) — METAS, não histórico
CREATE TABLE rotinas_exercicios (
    id                  TEXT PRIMARY KEY,
    rotina_id           TEXT NOT NULL,
    exercicio_id        TEXT NOT NULL,
    ordem               INTEGER NOT NULL,
    series_alvo         INTEGER NOT NULL CHECK (series_alvo > 0),
    repeticoes_alvo     INTEGER NOT NULL CHECK (repeticoes_alvo > 0),
    carga_alvo_gramas   INTEGER CHECK (carga_alvo_gramas IS NULL OR carga_alvo_gramas >= 0),  -- RN21
    descanso_segundos   INTEGER NOT NULL DEFAULT 60 CHECK (descanso_segundos >= 0),
    criado_em           TEXT NOT NULL,
    atualizado_em       TEXT NOT NULL,
    UNIQUE (rotina_id, ordem),
    FOREIGN KEY (rotina_id)    REFERENCES rotinas(id)    ON DELETE CASCADE,
    FOREIGN KEY (exercicio_id) REFERENCES exercicios(id) ON DELETE RESTRICT
);

-- Execução real de um treino (RN19). finalizada_em NULL = em andamento
CREATE TABLE sessoes_treino (
    id                  TEXT PRIMARY KEY,
    usuario_id          TEXT NOT NULL,
    rotina_id           TEXT,               -- NULL = treino livre ou rotina excluída
    nome_rotina         TEXT NOT NULL,      -- cópia do nome no momento do treino (histórico estável)
    iniciada_em         TEXT NOT NULL,
    finalizada_em       TEXT,
    observacao          TEXT,
    criado_em           TEXT NOT NULL,
    atualizado_em       TEXT NOT NULL,
    excluido_em         TEXT,
    CHECK (finalizada_em IS NULL OR finalizada_em >= iniciada_em),
    FOREIGN KEY (rotina_id) REFERENCES rotinas(id) ON DELETE SET NULL
);

CREATE INDEX ix_sessoes_data ON sessoes_treino (usuario_id, iniciada_em);

-- Cada série efetivamente feita: base de histórico, "ANTERIOR", volume e recordes
CREATE TABLE series_realizadas (
    id                  TEXT PRIMARY KEY,
    sessao_id           TEXT NOT NULL,
    exercicio_id        TEXT NOT NULL,
    ordem_exercicio     INTEGER NOT NULL,
    numero_serie        INTEGER NOT NULL CHECK (numero_serie > 0),
    carga_gramas        INTEGER CHECK (carga_gramas IS NULL OR carga_gramas >= 0),
    repeticoes          INTEGER NOT NULL CHECK (repeticoes >= 0),
    concluida           INTEGER NOT NULL DEFAULT 0 CHECK (concluida IN (0,1)),
    criado_em           TEXT NOT NULL,
    atualizado_em       TEXT NOT NULL,
    UNIQUE (sessao_id, ordem_exercicio, numero_serie),
    FOREIGN KEY (sessao_id)    REFERENCES sessoes_treino(id) ON DELETE CASCADE,
    FOREIGN KEY (exercicio_id) REFERENCES exercicios(id)     ON DELETE RESTRICT
);

CREATE INDEX ix_series_exercicio ON series_realizadas (exercicio_id);

CREATE TABLE registros_peso (
    id              TEXT PRIMARY KEY,
    usuario_id      TEXT NOT NULL,
    data            TEXT NOT NULL,
    peso_gramas     INTEGER NOT NULL CHECK (peso_gramas > 0),
    criado_em       TEXT NOT NULL,
    atualizado_em   TEXT NOT NULL,
    excluido_em     TEXT
);

CREATE INDEX ix_registros_peso_data ON registros_peso (usuario_id, data);

-- Recordes por exercício (RN24):
--   recorde de carga  = maior carga em uma série concluída
--   recorde de volume = maior soma (carga × reps) do exercício em uma única sessão
CREATE VIEW vw_recordes_exercicios AS
WITH volume_por_sessao AS (
    SELECT s.usuario_id, sr.exercicio_id, sr.sessao_id,
           MAX(sr.carga_gramas)                 AS maior_carga_gramas,
           SUM(sr.carga_gramas * sr.repeticoes) AS volume_gramas
      FROM series_realizadas sr
      JOIN sessoes_treino s ON s.id = sr.sessao_id
     WHERE sr.concluida = 1 AND s.finalizada_em IS NOT NULL AND s.excluido_em IS NULL
     GROUP BY s.usuario_id, sr.exercicio_id, sr.sessao_id
)
SELECT usuario_id, exercicio_id,
       MAX(maior_carga_gramas) AS recorde_carga_gramas,
       MAX(volume_gramas)      AS recorde_volume_gramas
  FROM volume_por_sessao
 GROUP BY usuario_id, exercicio_id;

-- =====================================================================
-- MÓDULO: TAREFAS / ATIVIDADES
-- =====================================================================
CREATE TABLE pastas_tarefas (
    id              TEXT PRIMARY KEY,
    usuario_id      TEXT NOT NULL,
    nome            TEXT NOT NULL,          -- ex.: "Faculdade", "Trabalho"
    icone           TEXT NOT NULL,          -- emoji ou código do ícone
    cor_hex         TEXT CHECK (cor_hex IS NULL OR cor_hex GLOB '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'),
    padrao          INTEGER NOT NULL DEFAULT 0 CHECK (padrao IN (0,1)),  -- 1 = "Tarefas Pessoais" (RN27)
    ordem           INTEGER NOT NULL DEFAULT 0,
    criado_em       TEXT NOT NULL,
    atualizado_em   TEXT NOT NULL,
    excluido_em     TEXT
);

CREATE UNIQUE INDEX ux_pastas_tarefas_nome ON pastas_tarefas (usuario_id, nome COLLATE NOCASE) WHERE excluido_em IS NULL;
CREATE UNIQUE INDEX ux_pastas_tarefas_padrao ON pastas_tarefas (usuario_id) WHERE padrao = 1;

CREATE TABLE tarefas (
    id              TEXT PRIMARY KEY,
    usuario_id      TEXT NOT NULL,
    pasta_id        TEXT NOT NULL,
    titulo          TEXT NOT NULL,
    descricao       TEXT,
    data_prazo      TEXT,                   -- data/hora limite (NULL = sem prazo)
    prioridade      TEXT NOT NULL DEFAULT 'MEDIA' CHECK (prioridade IN ('BAIXA','MEDIA','ALTA')),
    concluida_em    TEXT,                   -- NULL = pendente (RN26)
    arquivada_em    TEXT,                   -- NULL = visível na lista
    criado_em       TEXT NOT NULL,
    atualizado_em   TEXT NOT NULL,
    excluido_em     TEXT,
    FOREIGN KEY (pasta_id) REFERENCES pastas_tarefas(id) ON DELETE RESTRICT
);

CREATE INDEX ix_tarefas_prazo ON tarefas (usuario_id, data_prazo);
CREATE INDEX ix_tarefas_pasta ON tarefas (pasta_id);

-- RN27: a pasta padrão não pode ser excluída
CREATE TRIGGER trg_pasta_padrao_nao_exclui
BEFORE UPDATE OF excluido_em ON pastas_tarefas
WHEN OLD.padrao = 1 AND NEW.excluido_em IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'A pasta padrão não pode ser excluída');
END;

CREATE TRIGGER trg_pasta_padrao_nao_delete
BEFORE DELETE ON pastas_tarefas
WHEN OLD.padrao = 1
BEGIN
    SELECT RAISE(ABORT, 'A pasta padrão não pode ser excluída');
END;
