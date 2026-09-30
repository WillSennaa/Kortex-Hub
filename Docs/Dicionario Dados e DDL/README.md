# 🗄️ Dicionário de Dados e Scripts DDL — Kortex Hub

Este documento detalha a estrutura do banco de dados do Kortex Hub, dividido entre a infraestrutura em nuvem (Supabase) e o armazenamento local do aplicativo móvel (SQLite), conforme as Decisões de Arquitetura ADR-04 e ADR-05.

---

## ☁️ PARTE 1: Banco de Dados em Nuvem (Supabase / PostgreSQL)
**Objetivo:** Gerenciar autenticação, perfis de acesso, notificações globais e feedbacks.
**SGBD:** PostgreSQL.

### 1.1 Dicionário de Dados (Nuvem)

| Tabela | Coluna | Tipo (Postgres) | Restrições | Descrição |
| :--- | :--- | :--- | :--- | :--- |
| **usuarios** | id | UUID | PK | Identificador único do usuário. |
| | nome | VARCHAR(100) | NOT NULL | Nome completo ou de exibição. |
| | email | VARCHAR(150) | NOT NULL, UNIQUE | E-mail para login. |
| | senha_hash | VARCHAR(255) | NOT NULL | Senha criptografada (gerida pela API C#). |
| | data_cadastro | TIMESTAMP | NOT NULL | Data de criação da conta. |
| | status | VARCHAR(20) | NOT NULL | Ex: 'ATIVO', 'INATIVO'. |
| | tipo_usuario | VARCHAR(20) | NOT NULL | Discriminador: 'COMUM' ou 'ADMIN'. |
| | data_nascimento | DATE | NULL | Data de nascimento (Perfil Comum). |
| | nivel_permissao | VARCHAR(50) | NULL | Nível de acesso (Perfil Admin). |
| **feedbacks** | id | UUID | PK | Identificador do feedback. |
| | usuario_id | UUID | FK, NOT NULL | Usuário que enviou o relato. |
| | admin_id | UUID | FK, NULL | Admin que respondeu ao relato. |
| | tipo | VARCHAR(20) | NOT NULL | Ex: 'BUG', 'SUGESTAO'. |
| | mensagem | TEXT | NOT NULL | Conteúdo do feedback. |
| | data_envio | TIMESTAMP | NOT NULL | Data/hora do envio. |
| | respondido | BOOLEAN | NOT NULL | Status de resposta. |
| **notificacoes** | id | UUID | PK | Identificador do aviso global. |
| | admin_id | UUID | FK, NOT NULL | Admin que criou o aviso. |
| | titulo | VARCHAR(100) | NOT NULL | Título da notificação. |
| | conteudo | TEXT | NOT NULL | Mensagem completa. |
| | data_criacao | TIMESTAMP | NOT NULL | Data de emissão. |
| | data_expiracao| TIMESTAMP | NULL | Validade do aviso na tela. |

### 1.2 Script DDL (PostgreSQL - Executar no Supabase)

```sql
-- Habilita extensão para UUID no PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Tabela de Usuários (Autenticação Nuvem)
CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    senha_hash VARCHAR(255) NOT NULL,
    data_cadastro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'ATIVO',
    tipo_usuario VARCHAR(20) NOT NULL DEFAULT 'COMUM',
    data_nascimento DATE NULL,
    nivel_permissao VARCHAR(50) NULL
);

-- 2. Tabela de Notificações Globais do Sistema
CREATE TABLE notificacoes_sistema (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID NOT NULL,
    titulo VARCHAR(100) NOT NULL,
    conteudo TEXT NOT NULL,
    data_criacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_expiracao TIMESTAMP NULL,
    CONSTRAINT fk_notificacao_admin FOREIGN KEY (admin_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- 3. Tabela de Feedbacks e Suporte
CREATE TABLE feedbacks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL,
    admin_id UUID NULL,
    tipo VARCHAR(20) NOT NULL,
    mensagem TEXT NOT NULL,
    data_envio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    respondido BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_feedback_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT fk_feedback_admin FOREIGN KEY (admin_id) REFERENCES usuarios(id) ON DELETE SET NULL
);

### 2.1 Script DDL (SQLite - Executar no App Mobile)

-- ==========================================
-- MÓDULO: FINANÇAS
-- ==========================================
CREATE TABLE categorias_financeiras (
    id TEXT PRIMARY KEY, -- UUID
    nome TEXT NOT NULL,
    cor_hex TEXT NOT NULL,
    icone_codigo TEXT NOT NULL
);

CREATE TABLE transacoes_financeiras (
    id TEXT PRIMARY KEY, -- UUID
    usuario_id TEXT NOT NULL, -- UUID lógico da nuvem
    categoria_financeira_id TEXT NOT NULL,
    descricao TEXT NOT NULL,
    valor REAL NOT NULL,
    data DATE NOT NULL,
    tipo TEXT NOT NULL,
    FOREIGN KEY (categoria_financeira_id) REFERENCES categorias_financeiras(id) ON DELETE RESTRICT
);

CREATE TABLE tags (
    id TEXT PRIMARY KEY, -- UUID
    nome TEXT NOT NULL UNIQUE
);

CREATE TABLE transacoes_tags (
    transacao_id TEXT NOT NULL,
    tag_id TEXT NOT NULL,
    PRIMARY KEY (transacao_id, tag_id),
    FOREIGN KEY (transacao_id) REFERENCES transacoes_financeiras(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

-- ==========================================
-- MÓDULO: TAREFAS / ATIVIDADES
-- ==========================================
CREATE TABLE categorias_tarefas (
    id TEXT PRIMARY KEY, -- UUID
    nome TEXT NOT NULL,
    cor_hex TEXT NOT NULL,
    icone_codigo TEXT NOT NULL
);

CREATE TABLE tarefas (
    id TEXT PRIMARY KEY, -- UUID
    usuario_id TEXT NOT NULL, -- UUID lógico da nuvem
    categoria_tarefa_id TEXT NOT NULL,
    titulo TEXT NOT NULL,
    descricao TEXT,
    data_vencimento DATETIME,
    prioridade TEXT NOT NULL,
    concluida INTEGER NOT NULL DEFAULT 0, -- 0 = False, 1 = True
    FOREIGN KEY (categoria_tarefa_id) REFERENCES categorias_tarefas(id) ON DELETE RESTRICT
);

-- ==========================================
-- MÓDULO: TREINOS E FITNESS
-- ==========================================
CREATE TABLE exercicios (
    id TEXT PRIMARY KEY, -- UUID (Catálogo Global Local)
    nome TEXT NOT NULL,
    grupo_muscular TEXT NOT NULL,
    video_execucao_url TEXT
);

CREATE TABLE treinos (
    id TEXT PRIMARY KEY, -- UUID
    usuario_id TEXT NOT NULL, -- UUID lógico da nuvem
    nome TEXT NOT NULL,
    data_criacao DATETIME NOT NULL,
    ativo INTEGER NOT NULL DEFAULT 1 -- 0 = False, 1 = True
);

CREATE TABLE itens_exercicios (
    id TEXT PRIMARY KEY, -- UUID
    treino_id TEXT NOT NULL,
    exercicio_id TEXT NOT NULL,
    series INTEGER NOT NULL,
    repeticoes INTEGER NOT NULL,
    carga REAL, -- Permite nulo/zero
    tempo_descanso INTEGER NOT NULL,
    FOREIGN KEY (treino_id) REFERENCES treinos(id) ON DELETE CASCADE,
    FOREIGN KEY (exercicio_id) REFERENCES exercicios(id) ON DELETE RESTRICT
);