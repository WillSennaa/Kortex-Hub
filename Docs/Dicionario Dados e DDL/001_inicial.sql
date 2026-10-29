-- =====================================================================
-- KORTEX HUB — BANCO LOCAL (SQLite) — MIGRAÇÃO 001: schema inicial
-- Versão do schema: 1  (controlada via PRAGMA user_version — ADR-09)
-- =====================================================================
-- Convenções (ADR-04, ADR-08, ADR-09, ADR-12, ADR-13):
--   * UM ARQUIVO POR USUÁRIO: kortex_<usuario_id>.db (ADR-13). Por isso
--     nenhuma tabela tem coluna usuario_id: tudo que está no arquivo
--     pertence ao dono do arquivo. O UUID do dono fica gravado em
--     configuracoes (chave 'usuario_id') e é conferido ao restaurar.
--   * PK: UUID v4 gerado no app, armazenado como TEXT.
--   * DATA DE CALENDÁRIO: TEXT 'YYYY-MM-DD' na data LOCAL do usuário
--     (fuso do aparelho no momento do registro — ADR-12). É ela que
--     decide "a que dia pertence" um lançamento, treino ou tarefa.
--   * INSTANTE: TEXT ISO-8601 em UTC com milissegundos
--     ('YYYY-MM-DDTHH:MM:SS.sssZ'), exatamente o formato de
--     Date.prototype.toISOString(). Um formato só, para a comparação
--     textual (>=, ORDER BY) funcionar.
--   * HORA LOCAL: TEXT 'HH:MM' (24h).
--   * Os três formatos acima são validados por CHECK.
--   * Dinheiro: INTEGER em CENTAVOS (R$ 12,50 -> 1250). Nunca REAL.
--   * Peso/carga: INTEGER em GRAMAS (32,5 kg -> 32500).
--   * Booleanos: INTEGER 0/1 com CHECK.
--   * Auditoria em toda tabela "raiz": criado_em, atualizado_em,
--     excluido_em (soft delete — NULL = registro ativo).
--
-- SOFT DELETE x CHAVES ESTRANGEIRAS (RN33):
--   O app não executa DELETE nos registros dos módulos; ele preenche
--   excluido_em. Assim, ON DELETE RESTRICT/SET NULL nunca disparam no uso
--   normal. As regras equivalentes ficam nos triggers "trg_*_exclusao"
--   (bloqueiam a exclusão lógica) e "trg_*_ref_ativa" (impedem apontar
--   para um registro excluído logicamente). As FKs continuam valendo
--   para DELETE físico e para garantir que o registro referenciado existe.
--
-- IMPORTANTE: o SQLite só respeita FOREIGN KEY se cada conexão
-- executar "PRAGMA foreign_keys = ON;" ao abrir.
-- =====================================================================

PRAGMA foreign_keys = ON;
PRAGMA user_version = 1;

-- =====================================================================
-- CONFIGURAÇÕES GERAIS DO APP (chave/valor)
-- Ex.: usuario_id (dono do arquivo), modo_noturno (RNF05), notificacoes_ativas,
--      meta_peso_gramas, backup_google_email, backup_ultimo_em
-- Tokens OAuth do Google NÃO ficam aqui: vão para o armazenamento
-- seguro do sistema (expo-secure-store / Android Keystore).
-- =====================================================================
CREATE TABLE configuracoes (
    chave           TEXT PRIMARY KEY,
    valor           TEXT,
    atualizado_em   TEXT NOT NULL
);

-- =====================================================================
-- MÓDULO: FINANÇAS
-- =====================================================================
CREATE TABLE contas (
    id                      TEXT PRIMARY KEY,
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
    excluido_em             TEXT,
    CHECK (NOT (principal = 1 AND arquivada = 1))   -- conta arquivada não pode ser a principal
);

-- Só uma conta principal ativa por banco (= por usuário)
CREATE UNIQUE INDEX ux_contas_principal ON contas (principal)
    WHERE principal = 1 AND excluido_em IS NULL;

CREATE TABLE categorias_financeiras (
    id                  TEXT PRIMARY KEY,
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
    CHECK (categoria_pai_id IS NULL OR categoria_pai_id <> id),
    FOREIGN KEY (categoria_pai_id) REFERENCES categorias_financeiras(id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX ux_categorias_fin_nome
    ON categorias_financeiras (tipo, COALESCE(categoria_pai_id, ''), nome COLLATE NOCASE)
    WHERE excluido_em IS NULL;

CREATE INDEX ix_categorias_fin_pai ON categorias_financeiras (categoria_pai_id);

-- Compra parcelada (RN36): agrupa as N parcelas, que são lançamentos
-- comuns em transacoes_financeiras (parcelamento_id + parcela_numero).
CREATE TABLE parcelamentos (
    id                      TEXT PRIMARY KEY,
    descricao               TEXT NOT NULL,
    valor_total_centavos    INTEGER NOT NULL CHECK (valor_total_centavos > 0),
    quantidade_parcelas     INTEGER NOT NULL CHECK (quantidade_parcelas BETWEEN 2 AND 48),
    data_compra             TEXT NOT NULL CHECK (data_compra IS date(data_compra)),        -- data local
    forma_pagamento         TEXT CHECK (forma_pagamento IN ('DEBITO','CREDITO','PIX','DINHEIRO')),
    criado_em               TEXT NOT NULL,
    atualizado_em           TEXT NOT NULL,
    excluido_em             TEXT,
    CHECK (valor_total_centavos >= quantidade_parcelas)   -- cada parcela tem pelo menos 1 centavo
);

-- Despesa recorrente (RN37): a REGRA. Cada ocorrência vira um lançamento
-- em transacoes_financeiras (recorrencia_id), gerado pelo app quando a
-- data chega. Editar a regra não altera ocorrências efetivadas.
CREATE TABLE recorrencias (
    id                  TEXT PRIMARY KEY,
    tipo                TEXT NOT NULL DEFAULT 'DESPESA' CHECK (tipo = 'DESPESA'),
    conta_id            TEXT NOT NULL,
    categoria_id        TEXT NOT NULL,
    descricao           TEXT NOT NULL,
    valor_centavos      INTEGER NOT NULL CHECK (valor_centavos > 0),
    forma_pagamento     TEXT CHECK (forma_pagamento IN ('DEBITO','CREDITO','PIX','DINHEIRO')),
    frequencia          TEXT NOT NULL CHECK (frequencia IN ('SEMANAL','MENSAL','ANUAL')),
    data_inicio         TEXT NOT NULL CHECK (data_inicio IS date(data_inicio)),            -- 1ª ocorrência (data local)
    data_fim            TEXT CHECK (data_fim IS date(data_fim)),                           -- NULL = sem fim
    ultima_gerada_em    TEXT CHECK (ultima_gerada_em IS date(ultima_gerada_em)),          -- data da última ocorrência criada
    ativa               INTEGER NOT NULL DEFAULT 1 CHECK (ativa IN (0,1)),
    observacao          TEXT,
    criado_em           TEXT NOT NULL,
    atualizado_em       TEXT NOT NULL,
    excluido_em         TEXT,
    CHECK (data_fim IS NULL OR data_fim >= data_inicio),
    FOREIGN KEY (conta_id)     REFERENCES contas(id)                 ON DELETE RESTRICT,
    FOREIGN KEY (categoria_id) REFERENCES categorias_financeiras(id) ON DELETE RESTRICT
);

CREATE INDEX ix_recorrencias_conta ON recorrencias (conta_id);
CREATE INDEX ix_recorrencias_cat   ON recorrencias (categoria_id);

CREATE TABLE transacoes_financeiras (
    id                  TEXT PRIMARY KEY,
    conta_id            TEXT NOT NULL,
    categoria_id        TEXT NOT NULL,
    tipo                TEXT NOT NULL CHECK (tipo IN ('RECEITA','DESPESA')),
    descricao           TEXT NOT NULL,
    valor_centavos      INTEGER NOT NULL CHECK (valor_centavos > 0),
    data_prevista       TEXT NOT NULL CHECK (data_prevista IS date(data_prevista)),        -- data local
    data_efetivacao     TEXT CHECK (data_efetivacao IS date(data_efetivacao)),             -- data local; NULL = pendente
    forma_pagamento     TEXT CHECK (forma_pagamento IN ('DEBITO','CREDITO','PIX','DINHEIRO')), -- RN38; NULL = não informada
    parcelamento_id     TEXT,               -- RN36: parcela de uma compra parcelada
    parcela_numero      INTEGER CHECK (parcela_numero >= 1),
    recorrencia_id      TEXT,               -- RN37: ocorrência de uma despesa recorrente
    observacao          TEXT,
    criado_em           TEXT NOT NULL,
    atualizado_em       TEXT NOT NULL,
    excluido_em         TEXT,
    CHECK ((parcelamento_id IS NULL) = (parcela_numero IS NULL)),
    CHECK (parcelamento_id IS NULL OR recorrencia_id IS NULL),        -- ou parcela, ou recorrente
    CHECK (parcelamento_id IS NULL OR tipo = 'DESPESA'),              -- só despesa é parcelada
    FOREIGN KEY (conta_id)        REFERENCES contas(id)                 ON DELETE RESTRICT,
    FOREIGN KEY (categoria_id)    REFERENCES categorias_financeiras(id) ON DELETE RESTRICT,
    FOREIGN KEY (parcelamento_id) REFERENCES parcelamentos(id)          ON DELETE CASCADE,
    FOREIGN KEY (recorrencia_id)  REFERENCES recorrencias(id)           ON DELETE SET NULL
);

CREATE INDEX ix_transacoes_data  ON transacoes_financeiras (data_prevista);
CREATE INDEX ix_transacoes_conta ON transacoes_financeiras (conta_id);
CREATE INDEX ix_transacoes_cat   ON transacoes_financeiras (categoria_id);
CREATE INDEX ix_transacoes_forma ON transacoes_financeiras (forma_pagamento);

-- RN36: cada número de parcela aparece uma vez por compra
CREATE UNIQUE INDEX ux_transacoes_parcela
    ON transacoes_financeiras (parcelamento_id, parcela_numero)
    WHERE parcelamento_id IS NOT NULL;

-- RN37: uma ocorrência por data e regra. Inclui as excluídas, para que o
-- gerador (INSERT OR IGNORE) não recrie uma ocorrência que o usuário apagou.
CREATE UNIQUE INDEX ux_transacoes_recorrencia
    ON transacoes_financeiras (recorrencia_id, data_prevista)
    WHERE recorrencia_id IS NOT NULL;

-- RN36: o número da parcela não passa da quantidade de parcelas da compra
CREATE TRIGGER trg_parcela_numero_valido
BEFORE INSERT ON transacoes_financeiras
WHEN NEW.parcelamento_id IS NOT NULL
 AND NEW.parcela_numero > (SELECT quantidade_parcelas FROM parcelamentos WHERE id = NEW.parcelamento_id)
BEGIN
    SELECT RAISE(ABORT, 'Número da parcela maior que a quantidade de parcelas');
END;

-- RN36: excluir a compra parcelada exclui todas as parcelas
-- (desfazer a exclusão da compra não restaura as parcelas automaticamente)
CREATE TRIGGER trg_parcelamento_exclusao
AFTER UPDATE OF excluido_em ON parcelamentos
WHEN OLD.excluido_em IS NULL AND NEW.excluido_em IS NOT NULL
BEGIN
    UPDATE transacoes_financeiras
       SET excluido_em = NEW.excluido_em, atualizado_em = NEW.excluido_em
     WHERE parcelamento_id = OLD.id AND excluido_em IS NULL;
END;

-- RN10 / RN37: tipo da regra igual ao da categoria; conta e categoria ativas
CREATE TRIGGER trg_recorrencia_valida_ins
BEFORE INSERT ON recorrencias
WHEN NEW.tipo <> (SELECT tipo FROM categorias_financeiras WHERE id = NEW.categoria_id)
  OR (SELECT excluido_em FROM contas                 WHERE id = NEW.conta_id)     IS NOT NULL
  OR (SELECT excluido_em FROM categorias_financeiras WHERE id = NEW.categoria_id) IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'Recorrência inválida (tipo da categoria ou conta/categoria excluída)');
END;

CREATE TRIGGER trg_recorrencia_valida_upd
BEFORE UPDATE OF conta_id, categoria_id, excluido_em ON recorrencias
WHEN NEW.excluido_em IS NULL AND (
       NEW.tipo <> (SELECT tipo FROM categorias_financeiras WHERE id = NEW.categoria_id)
    OR (SELECT excluido_em FROM contas                 WHERE id = NEW.conta_id)     IS NOT NULL
    OR (SELECT excluido_em FROM categorias_financeiras WHERE id = NEW.categoria_id) IS NOT NULL)
BEGIN
    SELECT RAISE(ABORT, 'Recorrência inválida (tipo da categoria ou conta/categoria excluída)');
END;

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

-- RN16 / RN33: lançamento ativo só aponta para conta e categoria ativas
-- (vale também para "desfazer exclusão" de um lançamento)
CREATE TRIGGER trg_transacao_ref_ativa_ins
BEFORE INSERT ON transacoes_financeiras
WHEN NEW.excluido_em IS NULL AND (
       (SELECT excluido_em FROM contas                 WHERE id = NEW.conta_id)     IS NOT NULL
    OR (SELECT excluido_em FROM categorias_financeiras WHERE id = NEW.categoria_id) IS NOT NULL)
BEGIN
    SELECT RAISE(ABORT, 'Conta ou categoria excluída');
END;

CREATE TRIGGER trg_transacao_ref_ativa_upd
BEFORE UPDATE OF conta_id, categoria_id, excluido_em ON transacoes_financeiras
WHEN NEW.excluido_em IS NULL AND (
       (SELECT excluido_em FROM contas                 WHERE id = NEW.conta_id)     IS NOT NULL
    OR (SELECT excluido_em FROM categorias_financeiras WHERE id = NEW.categoria_id) IS NOT NULL)
BEGIN
    SELECT RAISE(ABORT, 'Conta ou categoria excluída');
END;

-- RN11: subcategoria tem o mesmo tipo da categoria-pai, pai ativo e só 1 nível
CREATE TRIGGER trg_subcategoria_valida_ins
BEFORE INSERT ON categorias_financeiras
WHEN NEW.categoria_pai_id IS NOT NULL AND (
       NEW.tipo <> (SELECT tipo FROM categorias_financeiras WHERE id = NEW.categoria_pai_id)
    OR (SELECT categoria_pai_id FROM categorias_financeiras WHERE id = NEW.categoria_pai_id) IS NOT NULL
    OR (SELECT excluido_em      FROM categorias_financeiras WHERE id = NEW.categoria_pai_id) IS NOT NULL)
BEGIN
    SELECT RAISE(ABORT, 'Subcategoria inválida (tipo diferente do pai, pai excluído ou mais de 1 nível)');
END;

-- RN11: mover uma categoria para baixo de outra segue as mesmas regras,
-- e uma categoria que já tem subcategorias não pode virar subcategoria
CREATE TRIGGER trg_subcategoria_valida_upd
BEFORE UPDATE OF categoria_pai_id ON categorias_financeiras
WHEN NEW.categoria_pai_id IS NOT NULL AND (
       NEW.tipo <> (SELECT tipo FROM categorias_financeiras WHERE id = NEW.categoria_pai_id)
    OR (SELECT categoria_pai_id FROM categorias_financeiras WHERE id = NEW.categoria_pai_id) IS NOT NULL
    OR (SELECT excluido_em      FROM categorias_financeiras WHERE id = NEW.categoria_pai_id) IS NOT NULL
    OR EXISTS (SELECT 1 FROM categorias_financeiras f
                WHERE f.categoria_pai_id = NEW.id AND f.excluido_em IS NULL))
BEGIN
    SELECT RAISE(ABORT, 'Subcategoria inválida (tipo diferente do pai, pai excluído ou mais de 1 nível)');
END;

-- RN10 / RN11: o tipo de uma categoria só muda se ela não tiver
-- subcategorias nem lançamentos (inclusive excluídos, que podem ser
-- restaurados) e, se for subcategoria, continuar igual ao do pai
CREATE TRIGGER trg_categoria_tipo_upd
BEFORE UPDATE OF tipo ON categorias_financeiras
WHEN NEW.tipo <> OLD.tipo AND (
       EXISTS (SELECT 1 FROM categorias_financeiras f WHERE f.categoria_pai_id = OLD.id)
    OR EXISTS (SELECT 1 FROM transacoes_financeiras t WHERE t.categoria_id = OLD.id)
    OR EXISTS (SELECT 1 FROM recorrencias r WHERE r.categoria_id = OLD.id)
    OR (NEW.categoria_pai_id IS NOT NULL
        AND NEW.tipo <> (SELECT tipo FROM categorias_financeiras WHERE id = NEW.categoria_pai_id)))
BEGIN
    SELECT RAISE(ABORT, 'Não é possível mudar o tipo: a categoria tem subcategorias ou lançamentos');
END;

-- RN16: categoria com lançamentos ou subcategorias ativas não pode ser
-- excluída (reatribua os lançamentos ou arquive a categoria)
CREATE TRIGGER trg_categoria_exclusao
BEFORE UPDATE OF excluido_em ON categorias_financeiras
WHEN OLD.excluido_em IS NULL AND NEW.excluido_em IS NOT NULL AND (
       EXISTS (SELECT 1 FROM transacoes_financeiras t
                WHERE t.categoria_id = OLD.id AND t.excluido_em IS NULL)
    OR EXISTS (SELECT 1 FROM categorias_financeiras f
                WHERE f.categoria_pai_id = OLD.id AND f.excluido_em IS NULL)
    OR EXISTS (SELECT 1 FROM recorrencias r
                WHERE r.categoria_id = OLD.id AND r.excluido_em IS NULL))
BEGIN
    SELECT RAISE(ABORT, 'Categoria com lançamentos, subcategorias ou recorrências: reatribua ou arquive');
END;

CREATE TABLE transferencias (
    id                  TEXT PRIMARY KEY,
    conta_origem_id     TEXT NOT NULL,
    conta_destino_id    TEXT NOT NULL,
    valor_centavos      INTEGER NOT NULL CHECK (valor_centavos > 0),
    data                TEXT NOT NULL CHECK (data IS date(data)),      -- data local
    descricao           TEXT,
    criado_em           TEXT NOT NULL,
    atualizado_em       TEXT NOT NULL,
    excluido_em         TEXT,
    CHECK (conta_origem_id <> conta_destino_id),
    FOREIGN KEY (conta_origem_id)  REFERENCES contas(id) ON DELETE RESTRICT,
    FOREIGN KEY (conta_destino_id) REFERENCES contas(id) ON DELETE RESTRICT
);

CREATE INDEX ix_transferencias_data    ON transferencias (data);
CREATE INDEX ix_transferencias_origem  ON transferencias (conta_origem_id);
CREATE INDEX ix_transferencias_destino ON transferencias (conta_destino_id);

-- RN14 / RN33: transferência ativa só entre contas ativas
CREATE TRIGGER trg_transferencia_ref_ativa_ins
BEFORE INSERT ON transferencias
WHEN NEW.excluido_em IS NULL AND (
       (SELECT excluido_em FROM contas WHERE id = NEW.conta_origem_id)  IS NOT NULL
    OR (SELECT excluido_em FROM contas WHERE id = NEW.conta_destino_id) IS NOT NULL)
BEGIN
    SELECT RAISE(ABORT, 'Conta de origem ou destino excluída');
END;

CREATE TRIGGER trg_transferencia_ref_ativa_upd
BEFORE UPDATE OF conta_origem_id, conta_destino_id, excluido_em ON transferencias
WHEN NEW.excluido_em IS NULL AND (
       (SELECT excluido_em FROM contas WHERE id = NEW.conta_origem_id)  IS NOT NULL
    OR (SELECT excluido_em FROM contas WHERE id = NEW.conta_destino_id) IS NOT NULL)
BEGIN
    SELECT RAISE(ABORT, 'Conta de origem ou destino excluída');
END;

-- RN16: conta com lançamentos ou transferências ativas não pode ser
-- excluída (reatribua os lançamentos ou arquive a conta)
CREATE TRIGGER trg_conta_exclusao
BEFORE UPDATE OF excluido_em ON contas
WHEN OLD.excluido_em IS NULL AND NEW.excluido_em IS NOT NULL AND (
       EXISTS (SELECT 1 FROM transacoes_financeiras t
                WHERE t.conta_id = OLD.id AND t.excluido_em IS NULL)
    OR EXISTS (SELECT 1 FROM transferencias tr
                WHERE (tr.conta_origem_id = OLD.id OR tr.conta_destino_id = OLD.id)
                  AND tr.excluido_em IS NULL)
    OR EXISTS (SELECT 1 FROM recorrencias r
                WHERE r.conta_id = OLD.id AND r.excluido_em IS NULL))
BEGIN
    SELECT RAISE(ABORT, 'Conta com lançamentos, transferências ou recorrências: reatribua ou arquive');
END;

CREATE TABLE tags (
    id              TEXT PRIMARY KEY,
    nome            TEXT NOT NULL,
    criado_em       TEXT NOT NULL,
    atualizado_em   TEXT NOT NULL,
    excluido_em     TEXT
);

CREATE UNIQUE INDEX ux_tags_nome ON tags (nome COLLATE NOCASE) WHERE excluido_em IS NULL;

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
-- Saldo global = SUM(saldo_centavos) WHERE arquivada = 0
CREATE VIEW vw_saldo_contas AS
SELECT
    c.id AS conta_id,
    c.nome,
    c.arquivada,
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
    nome            TEXT NOT NULL,          -- ex.: "Jan - Mar/2026"
    ordem           INTEGER NOT NULL DEFAULT 0,
    criado_em       TEXT NOT NULL,
    atualizado_em   TEXT NOT NULL,
    excluido_em     TEXT
);

-- Catálogo: personalizado = 0 → exercício padrão (seed do app);
--           personalizado = 1 → criado pelo usuário.
CREATE TABLE exercicios (
    id                  TEXT PRIMARY KEY,
    nome                TEXT NOT NULL,
    grupo_muscular      TEXT NOT NULL,
    equipamento         TEXT,               -- ex.: 'HALTER','BARRA','POLIA','MAQUINA','PESO_CORPORAL'
    video_execucao_url  TEXT,
    personalizado       INTEGER NOT NULL DEFAULT 1 CHECK (personalizado IN (0,1)),
    criado_em           TEXT NOT NULL,
    atualizado_em       TEXT NOT NULL,
    excluido_em         TEXT
);

CREATE INDEX ix_exercicios_nome ON exercicios (nome COLLATE NOCASE);

-- Rotina = a "ficha" planejada (antiga tabela treinos)
CREATE TABLE rotinas (
    id              TEXT PRIMARY KEY,
    pasta_id        TEXT,
    nome            TEXT NOT NULL,          -- ex.: "Peito/Tríceps"
    local           TEXT,                   -- ex.: "Panobianco"
    ativa           INTEGER NOT NULL DEFAULT 1 CHECK (ativa IN (0,1)),
    criado_em       TEXT NOT NULL,
    atualizado_em   TEXT NOT NULL,
    excluido_em     TEXT,
    FOREIGN KEY (pasta_id) REFERENCES pastas_rotinas(id) ON DELETE SET NULL
);

CREATE INDEX ix_rotinas_pasta ON rotinas (pasta_id);

-- RN22 / RN33: rotina só entra em pasta ativa
CREATE TRIGGER trg_rotina_ref_ativa
BEFORE UPDATE OF pasta_id ON rotinas
WHEN NEW.pasta_id IS NOT NULL
 AND (SELECT excluido_em FROM pastas_rotinas WHERE id = NEW.pasta_id) IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'Pasta de rotinas excluída');
END;

CREATE TRIGGER trg_rotina_ref_ativa_ins
BEFORE INSERT ON rotinas
WHEN NEW.pasta_id IS NOT NULL
 AND (SELECT excluido_em FROM pastas_rotinas WHERE id = NEW.pasta_id) IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'Pasta de rotinas excluída');
END;

-- RN22: excluir uma pasta de rotinas desagrupa as rotinas (equivale ao
-- ON DELETE SET NULL). Desfazer a exclusão da pasta não as reagrupa.
CREATE TRIGGER trg_pasta_rotinas_exclusao
AFTER UPDATE OF excluido_em ON pastas_rotinas
WHEN OLD.excluido_em IS NULL AND NEW.excluido_em IS NOT NULL
BEGIN
    UPDATE rotinas SET pasta_id = NULL, atualizado_em = NEW.excluido_em
     WHERE pasta_id = OLD.id;
END;

-- Agenda semanal da rotina (RN23). 0 = domingo ... 6 = sábado
-- (mesma numeração de Date.prototype.getDay(), no fuso local)
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

CREATE INDEX ix_rotinas_exercicios_exercicio ON rotinas_exercicios (exercicio_id);

-- RN33: não se adiciona à rotina um exercício excluído do catálogo
CREATE TRIGGER trg_rotina_exercicio_ref_ativa_ins
BEFORE INSERT ON rotinas_exercicios
WHEN (SELECT excluido_em FROM exercicios WHERE id = NEW.exercicio_id) IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'Exercício excluído do catálogo');
END;

CREATE TRIGGER trg_rotina_exercicio_ref_ativa_upd
BEFORE UPDATE OF exercicio_id ON rotinas_exercicios
WHEN (SELECT excluido_em FROM exercicios WHERE id = NEW.exercicio_id) IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'Exercício excluído do catálogo');
END;

-- RN33: exercício usado em uma rotina ativa não pode ser excluído do
-- catálogo. O histórico (series_realizadas) não bloqueia: ele continua
-- apontando para o exercício excluído, que segue existindo no banco.
CREATE TRIGGER trg_exercicio_exclusao
BEFORE UPDATE OF excluido_em ON exercicios
WHEN OLD.excluido_em IS NULL AND NEW.excluido_em IS NOT NULL
 AND EXISTS (SELECT 1 FROM rotinas_exercicios re
               JOIN rotinas r ON r.id = re.rotina_id
              WHERE re.exercicio_id = OLD.id AND r.excluido_em IS NULL)
BEGIN
    SELECT RAISE(ABORT, 'Exercício usado em rotina ativa: remova-o da rotina antes');
END;

-- Execução real de um treino (RN19). finalizada_em NULL = em andamento
CREATE TABLE sessoes_treino (
    id                  TEXT PRIMARY KEY,
    rotina_id           TEXT,               -- NULL = treino livre ou rotina excluída
    nome_rotina         TEXT NOT NULL,      -- cópia do nome no momento do treino (histórico estável)
    data_local          TEXT NOT NULL CHECK (data_local IS date(data_local)),  -- dia do treino no fuso do aparelho (RN23, ADR-12)
    iniciada_em         TEXT NOT NULL CHECK (iniciada_em   IS strftime('%Y-%m-%dT%H:%M:%fZ', iniciada_em)),
    finalizada_em       TEXT          CHECK (finalizada_em IS strftime('%Y-%m-%dT%H:%M:%fZ', finalizada_em)),
    observacao          TEXT,
    criado_em           TEXT NOT NULL,
    atualizado_em       TEXT NOT NULL,
    excluido_em         TEXT,
    CHECK (finalizada_em IS NULL OR finalizada_em >= iniciada_em),
    FOREIGN KEY (rotina_id) REFERENCES rotinas(id) ON DELETE SET NULL
);

CREATE INDEX ix_sessoes_data_local ON sessoes_treino (data_local);
CREATE INDEX ix_sessoes_rotina     ON sessoes_treino (rotina_id);

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
    data            TEXT NOT NULL CHECK (data IS date(data)),          -- data local
    peso_gramas     INTEGER NOT NULL CHECK (peso_gramas > 0),
    criado_em       TEXT NOT NULL,
    atualizado_em   TEXT NOT NULL,
    excluido_em     TEXT
);

CREATE INDEX ix_registros_peso_data ON registros_peso (data);

-- Recordes por exercício (RN24), só com séries concluídas de sessões
-- finalizadas e não excluídas:
--   recorde de carga       = maior carga em uma série
--   recorde de volume      = maior soma (carga × reps) do exercício em uma única sessão
--   recorde de repetições  = maior número de reps em uma série; é o recorde
--                            exibido para exercícios sem carga (peso corporal, RN21)
CREATE VIEW vw_recordes_exercicios AS
WITH por_sessao AS (
    SELECT sr.exercicio_id, sr.sessao_id,
           MAX(sr.carga_gramas)                 AS maior_carga_gramas,
           SUM(sr.carga_gramas * sr.repeticoes) AS volume_gramas,
           MAX(sr.repeticoes)                   AS maior_repeticoes
      FROM series_realizadas sr
      JOIN sessoes_treino s ON s.id = sr.sessao_id
     WHERE sr.concluida = 1 AND s.finalizada_em IS NOT NULL AND s.excluido_em IS NULL
     GROUP BY sr.exercicio_id, sr.sessao_id
)
SELECT exercicio_id,
       MAX(maior_carga_gramas) AS recorde_carga_gramas,
       MAX(volume_gramas)      AS recorde_volume_gramas,
       MAX(maior_repeticoes)   AS recorde_repeticoes
  FROM por_sessao
 GROUP BY exercicio_id;

-- =====================================================================
-- MÓDULO: TAREFAS / ATIVIDADES
-- =====================================================================
CREATE TABLE pastas_tarefas (
    id              TEXT PRIMARY KEY,
    nome            TEXT NOT NULL,          -- ex.: "Faculdade", "Trabalho"
    icone           TEXT NOT NULL,          -- emoji ou código do ícone
    cor_hex         TEXT CHECK (cor_hex IS NULL OR cor_hex GLOB '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'),
    padrao          INTEGER NOT NULL DEFAULT 0 CHECK (padrao IN (0,1)),  -- 1 = "Tarefas Pessoais" (RN27)
    ordem           INTEGER NOT NULL DEFAULT 0,
    criado_em       TEXT NOT NULL,
    atualizado_em   TEXT NOT NULL,
    excluido_em     TEXT
);

CREATE UNIQUE INDEX ux_pastas_tarefas_nome   ON pastas_tarefas (nome COLLATE NOCASE) WHERE excluido_em IS NULL;
CREATE UNIQUE INDEX ux_pastas_tarefas_padrao ON pastas_tarefas (padrao) WHERE padrao = 1;

CREATE TABLE tarefas (
    id              TEXT PRIMARY KEY,
    pasta_id        TEXT NOT NULL,
    titulo          TEXT NOT NULL,
    descricao       TEXT,
    data_prazo      TEXT CHECK (data_prazo IS date(data_prazo)),                          -- data local; NULL = sem prazo
    hora_prazo      TEXT CHECK (hora_prazo IS strftime('%H:%M', '2000-01-01 ' || hora_prazo)), -- 'HH:MM' local; opcional
    prioridade      TEXT NOT NULL DEFAULT 'MEDIA' CHECK (prioridade IN ('BAIXA','MEDIA','ALTA')),
    concluida_em    TEXT CHECK (concluida_em IS strftime('%Y-%m-%dT%H:%M:%fZ', concluida_em)),  -- NULL = pendente (RN26)
    arquivada_em    TEXT CHECK (arquivada_em IS strftime('%Y-%m-%dT%H:%M:%fZ', arquivada_em)),  -- NULL = visível na lista
    criado_em       TEXT NOT NULL,
    atualizado_em   TEXT NOT NULL,
    excluido_em     TEXT,
    CHECK (hora_prazo IS NULL OR data_prazo IS NOT NULL),   -- hora só faz sentido com data
    FOREIGN KEY (pasta_id) REFERENCES pastas_tarefas(id) ON DELETE RESTRICT
);

CREATE INDEX ix_tarefas_prazo ON tarefas (data_prazo);
CREATE INDEX ix_tarefas_pasta ON tarefas (pasta_id);

-- RN27 / RN33: tarefa ativa só entra em pasta ativa
CREATE TRIGGER trg_tarefa_ref_ativa_ins
BEFORE INSERT ON tarefas
WHEN NEW.excluido_em IS NULL
 AND (SELECT excluido_em FROM pastas_tarefas WHERE id = NEW.pasta_id) IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'Pasta de tarefas excluída');
END;

CREATE TRIGGER trg_tarefa_ref_ativa_upd
BEFORE UPDATE OF pasta_id, excluido_em ON tarefas
WHEN NEW.excluido_em IS NULL
 AND (SELECT excluido_em FROM pastas_tarefas WHERE id = NEW.pasta_id) IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'Pasta de tarefas excluída');
END;

-- RN27: a pasta padrão não pode ser excluída (lógica ou fisicamente)
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

-- RN27: o indicador de pasta padrão é definido na criação e não muda
-- (senão bastaria desmarcá-lo para conseguir excluir a pasta)
CREATE TRIGGER trg_pasta_padrao_imutavel
BEFORE UPDATE OF padrao ON pastas_tarefas
WHEN NEW.padrao <> OLD.padrao
BEGIN
    SELECT RAISE(ABORT, 'O indicador de pasta padrão não pode ser alterado');
END;

-- RN27: pasta com tarefas (inclusive arquivadas) não pode ser excluída;
-- mova as tarefas antes
CREATE TRIGGER trg_pasta_tarefas_exclusao
BEFORE UPDATE OF excluido_em ON pastas_tarefas
WHEN OLD.excluido_em IS NULL AND NEW.excluido_em IS NOT NULL
 AND EXISTS (SELECT 1 FROM tarefas t WHERE t.pasta_id = OLD.id AND t.excluido_em IS NULL)
BEGIN
    SELECT RAISE(ABORT, 'Pasta com tarefas: mova as tarefas antes de excluir');
END;
