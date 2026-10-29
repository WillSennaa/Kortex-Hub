-- =====================================================================
-- KORTEX HUB — BANCO LOCAL (SQLite) — MIGRAÇÃO 002: dados padrão
-- Executada uma vez em cada arquivo kortex_<usuario_id>.db (ADR-09, ADR-13),
-- logo após a 001, dentro da mesma transação do executor de migrações.
--
-- * Os UUIDs são fixos: são iguais em todos os aparelhos, o que facilita
--   identificar os registros padrão (e um backup restaurado não duplica nada).
-- * padrao = 1 / personalizado = 0 marcam o que veio daqui.
-- * Nomes, subcategorias e exercícios seguem o protótipo no Figma; cores
--   seguem o guia de estilos (chart/* e selection/palette-*).
-- * Contas NÃO são criadas aqui: o usuário cadastra a primeira conta no
--   primeiro acesso ao módulo de Finanças.
-- * A chave configuracoes.usuario_id é gravada pelo app ao criar o arquivo,
--   não por esta migração.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Tarefas: pasta padrão (RN27)
-- ---------------------------------------------------------------------
INSERT INTO pastas_tarefas (id, nome, icone, cor_hex, padrao, ordem, criado_em, atualizado_em)
VALUES ('d112e5c0-3240-4d5d-938f-02494d117bb2', 'Tarefas Pessoais', '📁', NULL, 1, 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));

-- ---------------------------------------------------------------------
-- Finanças: categorias e subcategorias padrão (RN11, RN15)
-- ---------------------------------------------------------------------
INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('694f9915-dcfd-4ed0-a23d-07e0dc26e5de', NULL, 'Alimentação', 'DESPESA', '#B45309', '🍽️', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));
INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('96ca6fff-35a2-445b-96b2-c95c1ad1c773', '694f9915-dcfd-4ed0-a23d-07e0dc26e5de', 'Supermercado', 'DESPESA', '#B45309', '🛒', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));
INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('7da79056-baa6-4344-850f-2f6c103fe7f2', '694f9915-dcfd-4ed0-a23d-07e0dc26e5de', 'Restaurantes', 'DESPESA', '#B45309', '🍴', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));
INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('94377f56-c7be-490f-ae4b-03a906591682', '694f9915-dcfd-4ed0-a23d-07e0dc26e5de', 'Delivery', 'DESPESA', '#B45309', '🛵', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));

INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('a7b418b3-85c1-479c-b30e-0ef32ad39823', NULL, 'Moradia', 'DESPESA', '#10B981', '🏠', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));
INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('570edfd7-2592-4a05-a347-76014efe9787', 'a7b418b3-85c1-479c-b30e-0ef32ad39823', 'Aluguel', 'DESPESA', '#10B981', '🔑', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));
INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('0716306f-c99d-489d-af0c-affdc1340b55', 'a7b418b3-85c1-479c-b30e-0ef32ad39823', 'Energia & Água', 'DESPESA', '#10B981', '💡', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));
INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('290aa6f2-d7f3-407a-b3a1-53131d923363', 'a7b418b3-85c1-479c-b30e-0ef32ad39823', 'Internet', 'DESPESA', '#10B981', '🌐', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));

INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('cfdd378f-7963-4c39-a3c7-46feda363a93', NULL, 'Transporte', 'DESPESA', '#0E7490', '🚗', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));
INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('d343c1e7-9450-429d-8295-5893dec76a0b', 'cfdd378f-7963-4c39-a3c7-46feda363a93', 'Combustível', 'DESPESA', '#0E7490', '⛽', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));
INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('65c35f54-50e3-4b7e-802e-227b08d24012', 'cfdd378f-7963-4c39-a3c7-46feda363a93', 'Uber / Táxi', 'DESPESA', '#0E7490', '🚕', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));
INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('da5d43b1-b1aa-4d6b-869f-ca9a635b63e2', 'cfdd378f-7963-4c39-a3c7-46feda363a93', 'Manutenção', 'DESPESA', '#0E7490', '🔧', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));

INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('9b8b4467-c3e6-41b2-8e69-dd42cb836a6e', NULL, 'Lazer', 'DESPESA', '#3451D1', '🎉', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));
INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('9c1b3c77-7e33-455f-87cf-2079de322ed1', '9b8b4467-c3e6-41b2-8e69-dd42cb836a6e', 'Cinema', 'DESPESA', '#3451D1', '🎬', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));
INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('44e48aa7-9a0e-4551-b814-8f6b651377b0', '9b8b4467-c3e6-41b2-8e69-dd42cb836a6e', 'Viagens', 'DESPESA', '#3451D1', '✈️', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));

INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('02faac3d-8da8-42bb-9d46-f835662c6c61', NULL, 'Outros', 'DESPESA', '#7E22CE', '📦', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));

INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('58f10003-f33a-486e-8c78-d5627642fbeb', NULL, 'Salário', 'RECEITA', '#15803D', '💰', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));

INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('19dd73a1-3275-406f-8922-48f5b320d15f', NULL, 'Investimento', 'RECEITA', '#6366F1', '📈', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));

INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('7b487f44-665f-43ce-b671-3794c7b765e5', NULL, 'Presente', 'RECEITA', '#EC4899', '🎁', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));

INSERT INTO categorias_financeiras (id, categoria_pai_id, nome, tipo, cor_hex, icone_codigo, padrao, criado_em, atualizado_em)
VALUES ('512dec82-dc4b-4510-8db5-ca63c99272a0', NULL, 'Outros', 'RECEITA', '#6B7280', '📦', 1, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));

-- ---------------------------------------------------------------------
-- Treinos: catálogo de exercícios padrão (personalizado = 0)
-- ---------------------------------------------------------------------
INSERT INTO exercicios (id, nome, grupo_muscular, equipamento, personalizado, criado_em, atualizado_em) VALUES
    ('6960bfb3-4952-4ea0-8622-0385b633ddc6', 'Supino Reto (Barra)', 'Peito', 'BARRA', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('2986adeb-774c-49a9-a443-a3073408fae0', 'Supino (Halter)', 'Peito', 'HALTER', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('1c3b79c2-1675-4e94-bd2f-541e3b963980', 'Supino Inclinado (Halter)', 'Peito', 'HALTER', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('dcfaef70-bde9-44b7-a9fd-d262ef18e9e0', 'Crucifixo na Polia', 'Peito', 'POLIA', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('58a87067-4ccc-4864-8e40-36b6ba29d0b2', 'Flexão', 'Peito', 'PESO_CORPORAL', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('d3279bb3-e121-441f-818d-844a7e392332', 'Puxada Frontal', 'Costas', 'POLIA', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('50a4f01d-d70f-44b7-9131-d8c00ac23884', 'Remada Curvada (Barra)', 'Costas', 'BARRA', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('5884b417-63c9-4d77-9d89-b95e2e4f47e1', 'Remada Baixa', 'Costas', 'POLIA', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('18110e71-d3e7-44ac-99f7-49087a64add2', 'Barra Fixa', 'Costas', 'PESO_CORPORAL', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('b0503779-57c6-481c-80de-9d1200ad7b3b', 'Desenvolvimento (Halter)', 'Ombros', 'HALTER', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('6c6dd468-b80e-42fe-b9c3-be706d39825d', 'Elevação Lateral (Halter)', 'Ombros', 'HALTER', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('6b8a61e2-e5f5-4bd2-a440-77ea380f47b7', 'Rosca Direta (Barra)', 'Bíceps', 'BARRA', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('3aaefe96-fe3d-4f7e-80c0-e9db8106db4d', 'Rosca Alternada (Halter)', 'Bíceps', 'HALTER', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('0125c778-450d-48e0-8eea-aff1ae6904de', 'Tríceps na Polia com Corda', 'Tríceps', 'POLIA', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('3a08a5e8-7eff-4e4b-8a0e-a9edfa04be03', 'Tríceps Testa (Barra)', 'Tríceps', 'BARRA', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('d7e2991a-209f-4f11-b82a-a27f2412a432', 'Mergulho', 'Tríceps', 'PESO_CORPORAL', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('388580ee-d6c9-4916-8afa-3d523bd24e99', 'Agachamento Livre (Barra)', 'Quadríceps', 'BARRA', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('93337ba2-4f65-4a48-bc6d-31ee222508ba', 'Leg Press 45°', 'Quadríceps', 'MAQUINA', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('f3a0c69a-3239-46fb-a681-c6c024a3e8d0', 'Cadeira Extensora', 'Quadríceps', 'MAQUINA', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('f2f2a93f-7c62-4364-af08-e2244def2877', 'Mesa Flexora', 'Posterior de Coxa', 'MAQUINA', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('4efed66e-3001-472f-b59c-fbf62420a979', 'Stiff (Barra)', 'Posterior de Coxa', 'BARRA', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('28916c2d-1e95-423e-8fd0-cccf1b3aaf3c', 'Elevação Pélvica (Barra)', 'Glúteos', 'BARRA', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('6ebe470b-9151-4a33-a058-af70a6e8b83b', 'Panturrilha em Pé', 'Panturrilha', 'MAQUINA', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('3234f4bb-573c-46c3-ba7a-39c7746672e3', 'Abdominal Crunch', 'Abdômen', 'PESO_CORPORAL', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    ('fcf1f370-17c9-4245-94e9-716778d8d3f8', 'Prancha', 'Abdômen', 'PESO_CORPORAL', 0, strftime('%Y-%m-%dT%H:%M:%fZ','now'), strftime('%Y-%m-%dT%H:%M:%fZ','now'));

PRAGMA user_version = 2;
