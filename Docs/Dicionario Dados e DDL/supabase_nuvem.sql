-- =====================================================================
-- KORTEX HUB — BANCO EM NUVEM (Supabase / PostgreSQL)
-- Escopo (ADR-01 / RN02): SOMENTE conta, autenticação, avisos globais,
-- feedbacks e a chave de backup. Nenhum dado dos módulos fica aqui.
-- Acesso: exclusivamente pela Web API em C# (ADR-02 / ADR-05).
-- =====================================================================

-- gen_random_uuid() é nativo no PostgreSQL 13+ (o Supabase já usa 15+)

-- ---------------------------------------------------------------------
-- 1. Usuários (Single Table Inheritance — ADR-07)
-- ---------------------------------------------------------------------
CREATE TABLE usuarios (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome                VARCHAR(100) NOT NULL,
    email               VARCHAR(150) NOT NULL,
    senha_hash          VARCHAR(255) NOT NULL,
    email_verificado_em TIMESTAMPTZ  NULL,
    status              VARCHAR(20)  NOT NULL DEFAULT 'ATIVO'
                        CHECK (status IN ('ATIVO','INATIVO')),
    tipo_usuario        VARCHAR(20)  NOT NULL DEFAULT 'COMUM'
                        CHECK (tipo_usuario IN ('COMUM','ADMIN')),
    data_nascimento     DATE         NULL,          -- só perfil COMUM
    nivel_permissao     VARCHAR(50)  NULL,          -- só perfil ADMIN
    criado_em           TIMESTAMPTZ  NOT NULL DEFAULT now(),
    atualizado_em       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    -- integridade do STI: campo de ADMIN só existe para ADMIN e vice-versa
    CONSTRAINT ck_usuarios_sti CHECK (
        (tipo_usuario = 'ADMIN' AND nivel_permissao IS NOT NULL AND data_nascimento IS NULL)
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
                    CHECK (finalidade IN ('CONFIRMAR_EMAIL','TROCAR_EMAIL','TROCAR_SENHA','RECUPERAR_SENHA')),
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
-- ---------------------------------------------------------------------
CREATE TABLE notificacoes_sistema (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id        UUID         NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
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
-- 7. SEGURANÇA (ADR-05)
--    No Supabase, tabelas do schema "public" ficam expostas pela API REST
--    automática para quem tiver a URL + chave "anon" (que é pública).
--    RLS ligado SEM nenhuma policy = acesso negado aos papéis anon e
--    authenticated. A API em C# conecta pela connection string com o
--    usuário "postgres" (dono das tabelas), que ignora o RLS.
-- ---------------------------------------------------------------------
ALTER TABLE usuarios             ENABLE ROW LEVEL SECURITY;
ALTER TABLE refresh_tokens       ENABLE ROW LEVEL SECURITY;
ALTER TABLE codigos_verificacao  ENABLE ROW LEVEL SECURITY;
ALTER TABLE chaves_backup        ENABLE ROW LEVEL SECURITY;
ALTER TABLE notificacoes_sistema ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedbacks            ENABLE ROW LEVEL SECURITY;

-- Defesa em profundidade: remove também os privilégios desses papéis.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM anon, authenticated;
        REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon, authenticated;
        REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM anon, authenticated;
    END IF;
END $$;
