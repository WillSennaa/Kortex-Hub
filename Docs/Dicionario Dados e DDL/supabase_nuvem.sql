-- =====================================================================
-- KORTEX HUB — BANCO EM NUVEM (Supabase / PostgreSQL)
-- Escopo (ADR-01 / RN02): SOMENTE conta, autenticação, avisos globais,
-- feedbacks e a chave de backup. Nenhum dado dos módulos fica aqui.
-- Acesso: exclusivamente pela Web API em C#, com o papel kortex_api
-- (ADR-02 / ADR-05).
-- Exclusão de conta (RN34): DELETE em usuarios apaga em cascata tokens,
-- códigos, chave de backup e feedbacks do usuário.
--
-- Executar como "postgres" (SQL Editor do Supabase ou psql).
-- =====================================================================

-- gen_random_uuid() é nativo no PostgreSQL 13+ (o Supabase já usa 15+)

-- ---------------------------------------------------------------------
-- 0. Schema privado e papel da API (ADR-05)
--    O schema "kortex" NÃO deve ser adicionado aos "Exposed schemas" da
--    API do Supabase. O papel kortex_api só lê e grava dados; quem cria
--    e altera tabelas é o "postgres", nas migrações.
-- ---------------------------------------------------------------------
CREATE SCHEMA kortex;

-- A senha NÃO fica no script nem no Git. Depois de rodar este arquivo:
--   ALTER ROLE kortex_api PASSWORD '<senha forte>';
-- e guarde a connection string só nas variáveis de ambiente da API
-- (com Search Path=kortex).
CREATE ROLE kortex_api LOGIN NOINHERIT;

SET search_path TO kortex;

-- ---------------------------------------------------------------------
-- 1. Usuários (Single Table Inheritance — ADR-07)
-- ---------------------------------------------------------------------
CREATE TABLE usuarios (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome                VARCHAR(100) NOT NULL,
    sobrenome           VARCHAR(100) NOT NULL,
    email               VARCHAR(150) NOT NULL,
    senha_hash          VARCHAR(255) NOT NULL,
    email_verificado_em TIMESTAMPTZ  NULL,
    status              VARCHAR(20)  NOT NULL DEFAULT 'ATIVO'
                        CHECK (status IN ('ATIVO','INATIVO')),
    tipo_usuario        VARCHAR(20)  NOT NULL DEFAULT 'COMUM'
                        CHECK (tipo_usuario IN ('COMUM','ADMIN')),
    nivel_permissao     VARCHAR(50)  NULL,          -- só perfil ADMIN
    -- RN35: senhas erradas seguidas e bloqueio temporário do login
    falhas_login        SMALLINT     NOT NULL DEFAULT 0 CHECK (falhas_login >= 0),
    bloqueado_ate       TIMESTAMPTZ  NULL,
    criado_em           TIMESTAMPTZ  NOT NULL DEFAULT now(),
    atualizado_em       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    -- integridade do STI: nivel_permissao existe só (e sempre) para ADMIN
    CONSTRAINT ck_usuarios_sti CHECK (
        (tipo_usuario = 'ADMIN' AND nivel_permissao IS NOT NULL)
     OR (tipo_usuario = 'COMUM' AND nivel_permissao IS NULL)
    )
);

-- RN01: e-mail único sem diferenciar maiúsculas/minúsculas
CREATE UNIQUE INDEX ux_usuarios_email ON usuarios (lower(email));

-- ---------------------------------------------------------------------
-- 2. Refresh tokens — sessão longa e login offline (ADR-10 / RN04)
--    Guarda só o HASH do token; o token em si fica no SecureStore do app.
-- ---------------------------------------------------------------------
CREATE TABLE refresh_tokens (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID         NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    token_hash      VARCHAR(255) NOT NULL UNIQUE,
    dispositivo     VARCHAR(100) NULL,              -- ex.: "Android - Galaxy A54"
    criado_em       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    expira_em       TIMESTAMPTZ  NOT NULL,
    revogado_em     TIMESTAMPTZ  NULL,
    substituido_por UUID         NULL REFERENCES refresh_tokens(id) ON DELETE SET NULL
);

CREATE INDEX ix_refresh_tokens_usuario ON refresh_tokens (usuario_id);

-- ---------------------------------------------------------------------
-- 3. Códigos de verificação por e-mail (RN05)
-- ---------------------------------------------------------------------
CREATE TABLE codigos_verificacao (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID         NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    finalidade      VARCHAR(30)  NOT NULL
                    CHECK (finalidade IN ('CONFIRMAR_EMAIL','TROCAR_EMAIL','TROCAR_SENHA','RECUPERAR_SENHA','EXCLUIR_CONTA')),
    codigo_hash     VARCHAR(255) NOT NULL,          -- nunca o código em texto puro
    novo_email      VARCHAR(150) NULL,              -- só para TROCAR_EMAIL
    tentativas      SMALLINT     NOT NULL DEFAULT 0 CHECK (tentativas BETWEEN 0 AND 5),
    criado_em       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    expira_em       TIMESTAMPTZ  NOT NULL,
    usado_em        TIMESTAMPTZ  NULL,
    CONSTRAINT ck_codigo_novo_email CHECK ((finalidade = 'TROCAR_EMAIL') = (novo_email IS NOT NULL))
);

CREATE INDEX ix_codigos_usuario ON codigos_verificacao (usuario_id, finalidade);

-- ---------------------------------------------------------------------
-- 4. Chave de backup (ADR-11 / RN32)
--    Chave AES aleatória do usuário, cifrada pela API com uma chave-mestra
--    que fica só em variável de ambiente do servidor. O arquivo de backup
--    fica no Google Drive; a chave fica aqui. Um sem o outro é inútil.
-- ---------------------------------------------------------------------
CREATE TABLE chaves_backup (
    usuario_id      UUID        PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
    chave_cifrada   BYTEA       NOT NULL,
    versao          SMALLINT    NOT NULL DEFAULT 1,
    criado_em       TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 5. Avisos globais emitidos por ADMs
--    admin_id vira NULL se a conta do ADM for excluída (RN34): o aviso
--    continua valendo, só perde o autor.
-- ---------------------------------------------------------------------
CREATE TABLE notificacoes_sistema (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id        UUID         NULL     REFERENCES usuarios(id) ON DELETE SET NULL,
    titulo          VARCHAR(100) NOT NULL,
    conteudo        TEXT         NOT NULL,
    criado_em       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    expira_em       TIMESTAMPTZ  NULL,
    CONSTRAINT ck_notificacao_validade CHECK (expira_em IS NULL OR expira_em > criado_em)
);

-- ---------------------------------------------------------------------
-- 6. Feedbacks / relatos de problema
-- ---------------------------------------------------------------------
CREATE TABLE feedbacks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID        NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    admin_id        UUID        NULL     REFERENCES usuarios(id) ON DELETE SET NULL,
    tipo            VARCHAR(20) NOT NULL CHECK (tipo IN ('BUG','SUGESTAO','OUTRO')),
    mensagem        TEXT        NOT NULL,
    resposta        TEXT        NULL,
    enviado_em      TIMESTAMPTZ NOT NULL DEFAULT now(),
    respondido_em   TIMESTAMPTZ NULL,
    CONSTRAINT ck_feedback_resposta CHECK ((resposta IS NULL) = (respondido_em IS NULL))
);

CREATE INDEX ix_feedbacks_pendentes ON feedbacks (enviado_em) WHERE respondido_em IS NULL;

-- ---------------------------------------------------------------------
-- 7. SEGURANÇA (ADR-05) — três camadas:
--    a) schema "kortex" fora dos "Exposed schemas" da API REST;
--    b) RLS em todas as tabelas, com policy só para kortex_api;
--    c) kortex_api só com SELECT/INSERT/UPDATE/DELETE (sem DDL).
--    O "postgres" é dono das tabelas e não é afetado pelo RLS; ele é
--    usado só nas migrações, nunca pela API.
--    DoD de toda tabela nova: ENABLE RLS + policy api_acesso_total + GRANT.
-- ---------------------------------------------------------------------

-- a) ninguém além da API usa o schema
REVOKE ALL ON SCHEMA kortex FROM PUBLIC;
GRANT USAGE ON SCHEMA kortex TO kortex_api;

-- b) RLS + policy exclusiva do papel da API
DO $$
DECLARE t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['usuarios','refresh_tokens','codigos_verificacao',
                             'chaves_backup','notificacoes_sistema','feedbacks']
    LOOP
        EXECUTE format('ALTER TABLE kortex.%I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('CREATE POLICY api_acesso_total ON kortex.%I
                            FOR ALL TO kortex_api USING (true) WITH CHECK (true)', t);
    END LOOP;
END $$;

-- c) privilégio mínimo: só dados, sem criar/alterar/apagar tabelas
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA kortex TO kortex_api;

-- Defesa em profundidade: os papéis públicos do Supabase não alcançam nada
-- no schema, mesmo que ele seja exposto por engano.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE ALL ON SCHEMA kortex FROM anon, authenticated;
        REVOKE ALL ON ALL TABLES    IN SCHEMA kortex FROM anon, authenticated;
        REVOKE ALL ON ALL SEQUENCES IN SCHEMA kortex FROM anon, authenticated;
        REVOKE ALL ON ALL FUNCTIONS IN SCHEMA kortex FROM anon, authenticated;
    END IF;
END $$;
