# 📐 Diagramas — Kortex Hub

Diagramas em [Mermaid](https://mermaid.js.org/), renderizados pelo próprio GitHub. São a versão oficial e acompanham os scripts em [`Docs/Dicionario Dados e DDL`](../Docs/Dicionario%20Dados%20e%20DDL/README.md); os arquivos `.drawio` e `.png` desta pasta ficam como histórico da v2.

**Sumário:** [Casos de uso](#1-casos-de-uso) · [Classes](#2-diagrama-de-classes) · [DER](#3-der--modelo-entidade-relacionamento)

**Documentos relacionados:** [Descrição dos Atores e Casos de Uso](Descricao_Casos_de_Uso.md) · [Diagrama de Rede (CPM)](Diagrama_de_Rede.md)

---

## 1. Casos de Uso

> O Mermaid não tem diagrama de casos de uso UML. A representação abaixo usa um fluxograma: atores são retângulos, casos de uso são elipses dentro da fronteira do sistema, e a herança entre atores aparece como seta tracejada `herda`.

```mermaid
flowchart LR
    Base["👤 Usuário Base"]
    Comum["👤 Usuário Comum"]
    ADM["👤 ADM"]
    Comum -. herda .-> Base
    ADM -. herda .-> Base

    subgraph SIS["Sistema Kortex Hub"]
        UC01(["Realizar Cadastro"])
        UC02(["Realizar Login"])
        UC03(["Recuperar Senha"])
        UC04(["Editar Dados da Conta"])
        UC05(["Excluir Conta"])
        UC06(["Visualizar Dashboard"])
        UC07(["Gerir Finanças"])
        UC08(["Gerir Treinos"])
        UC09(["Gerir Tarefas"])
        UC10(["Configurar"])
        UC11(["Fazer Backup na Conta Google"])
        UC12(["Relatar Problema ou Feedback"])
        UC13(["Visualizar Avisos"])
        UC14(["Responder Feedback"])
        UC15(["Emitir Avisos Globais"])
        UC16(["Gerenciar ADMs"])
        UC17(["Compartilhar Rotina"])
        INC1(["Validar Credenciais"])
        INC2(["Confirmar Código por E-mail"])
        INC3(["Acompanhar Progresso Diário"])
        INC4(["Verificar Perfil de ADM"])
    end

    Comum --- UC01
    Base --- UC02 & UC03 & UC04 & UC05 & UC06 & UC07 & UC08 & UC09 & UC10 & UC11 & UC12 & UC13 & UC17
    ADM --- UC14 & UC15 & UC16

    UC02 -. "«include»" .-> INC1
    UC14 -. "«include»" .-> INC4
    UC15 -. "«include»" .-> INC4
    UC16 -. "«include»" .-> INC4
    UC01 -. "«include»" .-> INC2
    UC03 -. "«include»" .-> INC2
    UC04 -. "«include»" .-> INC2
    UC05 -. "«include»" .-> INC2
    UC06 -. "«include»" .-> INC3
```

A descrição completa de cada ator e caso de uso (resumo, pré-condição, fluxo principal, fluxos alternativos, regras e pós-condição) está em [Descrição dos Atores e Casos de Uso](Descricao_Casos_de_Uso.md).

| Caso de uso | Requisito | Regras |
| :--- | :--- | :--- |
| Realizar Cadastro, Editar Dados da Conta, Excluir Conta | RF01 | RN01, RN05, RN34 |
| Realizar Login, Recuperar Senha, Validar Credenciais | RF02 | RN03, RN04, RN05, RN07 |
| Visualizar Dashboard, Acompanhar Progresso Diário | RF03, RF04 | RN08, RN09, RN29 |
| Gerir Finanças | RF05, RF06 | RN10–RN18, RN36–RN38 |
| Gerir Treinos | RF07, RF08 | RN19–RN25 |
| Compartilhar Rotina | RF13 | RN39 |
| Gerir Tarefas | RF09, RF10 | RN26–RN29 |
| Fazer Backup na Conta Google | RF11 | RN31, RN32 |
| Relatar Problema ou Feedback, Visualizar Avisos | RF12 | RN30 |
| Responder Feedback, Emitir Avisos Globais, Gerenciar ADMs, Verificar Perfil de ADM | RF01, RF12 | RN06, RN41 (Área de Administração no próprio app) |
| Configurar | RNF05 | RN40 (tema claro/escuro) e preferências do app (`configuracoes`) |

---

## 2. Diagrama de Classes

Classes da nuvem ficam na Web API (C#). Classes dos módulos ficam no app; cada usuário tem o próprio banco local (ADR-13), então elas não têm `usuarioId`. Valores em centavos (`long`) e gramas (`int`) — ADR-08. `Date` = data local, `DateTime` = instante UTC, `Time` = hora local — ADR-12.

### 2.1 Nuvem — Web API C#

```mermaid
classDiagram
    direction LR
    class Usuario {
        <<abstract>>
        +UUID id
        +String nome
        +String sobrenome
        +String email
        +String senhaHash
        +DateTime? emailVerificadoEm
        +StatusUsuario status
        +int falhasLogin
        +DateTime? bloqueadoAte
        +DateTime criadoEm
        +estaBloqueado() Boolean
        +login()
        +logout()
        +atualizarDados()
        +alterarSenha()
        +excluirConta()
    }
    class UsuarioComum {
        +enviarFeedback()
    }
    class Administrador {
        +String nivelPermissao
        +promoverAdm(email: String)
        +removerAdm(email: String)
        +emitirAvisoGlobal()
        +encerrarAviso(aviso: NotificacaoSistema)
        +responderFeedback()
    }
    class RefreshToken {
        +UUID id
        +String tokenHash
        +String dispositivo
        +DateTime expiraEm
        +DateTime? revogadoEm
        +estaValido() Boolean
        +rotacionar() RefreshToken
    }
    class CodigoVerificacao {
        +UUID id
        +FinalidadeCodigo finalidade
        +String codigoHash
        +String? novoEmail
        +int tentativas
        +DateTime expiraEm
        +validar(codigo: String) Boolean
    }
    class ChaveBackup {
        +byte[] chaveCifrada
        +int versao
        +rotacionar()
    }
    class Feedback {
        +UUID id
        +TipoFeedback tipo
        +String mensagem
        +String? resposta
        +DateTime enviadoEm
        +DateTime? respondidoEm
        +responder(texto: String)
    }
    class NotificacaoSistema {
        +UUID id
        +String titulo
        +String conteudo
        +DateTime criadoEm
        +DateTime? expiraEm
        +estaAtiva() Boolean
    }

    Usuario <|-- UsuarioComum
    Usuario <|-- Administrador
    Usuario "1" *-- "0..*" RefreshToken
    Usuario "1" *-- "0..*" CodigoVerificacao
    Usuario "1" *-- "0..1" ChaveBackup
    Usuario "1" --> "0..*" Feedback : envia
    Administrador "0..1" --> "0..*" Feedback : responde
    Administrador "0..1" --> "0..*" NotificacaoSistema : emite
```

### 2.2 App — Finanças

```mermaid
classDiagram
    direction LR
    class CategoriaFinanceira {
        +UUID id
        +String nome
        +TipoTransacao tipo
        +String corHex
        +String iconeCodigo
        +Boolean arquivada
        +ehSubcategoria() Boolean
        +arquivar()
    }
    class TransacaoFinanceira {
        +UUID id
        +TipoTransacao tipo
        +String descricao
        +long valorCentavos
        +Date dataPrevista
        +Date? dataEfetivacao
        +FormaPagamento? formaPagamento
        +int? parcelaNumero
        +efetivar(data: Date)
        +estaPendente() Boolean
    }
    class Parcelamento {
        +UUID id
        +String descricao
        +long valorTotalCentavos
        +int quantidadeParcelas
        +Date dataCompra
        +FormaPagamento? formaPagamento
        +gerarParcelas() List~TransacaoFinanceira~
    }
    class Recorrencia {
        +UUID id
        +String descricao
        +long valorCentavos
        +FormaPagamento? formaPagamento
        +Frequencia frequencia
        +Date dataInicio
        +Date? dataFim
        +Date? ultimaGeradaEm
        +Boolean ativa
        +gerarOcorrenciasAte(data: Date) List~TransacaoFinanceira~
    }
    class Conta {
        +UUID id
        +String nome
        +TipoConta tipo
        +long saldoInicialCentavos
        +String corHex
        +String iconeCodigo
        +Boolean principal
        +Boolean arquivada
        +calcularSaldo() long
    }
    class Transferencia {
        +UUID id
        +long valorCentavos
        +Date data
        +String? descricao
    }
    class Tag {
        +UUID id
        +String nome
    }

    CategoriaFinanceira "0..1" o-- "0..*" CategoriaFinanceira : subcategorias
    CategoriaFinanceira "1" <-- "0..*" TransacaoFinanceira
    Conta "1" <-- "0..*" TransacaoFinanceira
    TransacaoFinanceira "0..*" -- "0..*" Tag
    Conta "1" <-- "0..*" Transferencia : origem
    Conta "1" <-- "0..*" Transferencia : destino
    Parcelamento "0..1" *-- "2..48" TransacaoFinanceira : parcelas
    Recorrencia "0..1" o-- "0..*" TransacaoFinanceira : ocorrências
    Conta "1" <-- "0..*" Recorrencia
    CategoriaFinanceira "1" <-- "0..*" Recorrencia
```

### 2.3 App — Treinos

```mermaid
classDiagram
    direction LR
    class PastaRotina {
        +UUID id
        +String nome
        +int ordem
    }
    class Rotina {
        +UUID id
        +String nome
        +String? local
        +Boolean ativa
        +List~DiaSemana~ diasSemana
        +estaAgendadaPara(data: Date) Boolean
        +iniciarSessao() SessaoTreino
        +gerarTextoCompartilhamento() String
    }
    class ItemRotina {
        +int ordem
        +int seriesAlvo
        +int repeticoesAlvo
        +int? cargaAlvoGramas
        +int descansoSegundos
    }
    class Exercicio {
        +UUID id
        +String nome
        +String grupoMuscular
        +String? equipamento
        +String? videoExecucaoUrl
        +Boolean personalizado
    }
    class SessaoTreino {
        +UUID id
        +String nomeRotina
        +Date dataLocal
        +DateTime iniciadaEm
        +DateTime? finalizadaEm
        +finalizar()
        +duracao() TimeSpan
        +volumeTotalGramas() long
    }
    class SerieRealizada {
        +int ordemExercicio
        +int numeroSerie
        +int? cargaGramas
        +int repeticoes
        +Boolean concluida
        +volumeGramas() long
    }
    class RegistroPeso {
        +UUID id
        +Date data
        +int pesoGramas
    }

    PastaRotina "0..1" o-- "0..*" Rotina
    Rotina "1" *-- "1..*" ItemRotina
    ItemRotina "0..*" --> "1" Exercicio
    Rotina "0..1" <-- "0..*" SessaoTreino : origina
    SessaoTreino "1" *-- "1..*" SerieRealizada
    SerieRealizada "0..*" --> "1" Exercicio
```

### 2.4 App — Tarefas

```mermaid
classDiagram
    direction LR
    class PastaTarefa {
        +UUID id
        +String nome
        +String icone
        +String? corHex
        +Boolean padrao
        +contarPendentes() int
    }
    class Tarefa {
        +UUID id
        +String titulo
        +String? descricao
        +Date? dataPrazo
        +Time? horaPrazo
        +Prioridade prioridade
        +DateTime? concluidaEm
        +DateTime? arquivadaEm
        +concluir()
        +reabrir()
        +arquivar()
    }
    PastaTarefa "1" o-- "0..*" Tarefa
```

### 2.5 Enumerações

```mermaid
classDiagram
    direction LR
    class TipoTransacao {
        <<enumeration>>
        RECEITA
        DESPESA
    }
    class TipoConta {
        <<enumeration>>
        CORRENTE
        CARTEIRA
        POUPANCA
        INVESTIMENTO
    }
    class FormaPagamento {
        <<enumeration>>
        DEBITO
        CREDITO
        PIX
        DINHEIRO
    }
    class Frequencia {
        <<enumeration>>
        SEMANAL
        MENSAL
        ANUAL
    }
    class Prioridade {
        <<enumeration>>
        BAIXA
        MEDIA
        ALTA
    }
    class DiaSemana {
        <<enumeration>>
        DOMINGO_0
        SEGUNDA_1
        TERCA_2
        QUARTA_3
        QUINTA_4
        SEXTA_5
        SABADO_6
    }
    class TipoFeedback {
        <<enumeration>>
        BUG
        SUGESTAO
        OUTRO
    }
    class StatusUsuario {
        <<enumeration>>
        ATIVO
        INATIVO
    }
    class FinalidadeCodigo {
        <<enumeration>>
        CONFIRMAR_EMAIL
        TROCAR_EMAIL
        TROCAR_SENHA
        RECUPERAR_SENHA
        EXCLUIR_CONTA
    }
```

---

## 3. DER — Modelo Entidade-Relacionamento

Convenções: PK = UUID v4 (ADR-04) · dinheiro em centavos e peso em gramas (ADR-08) · data local, hora local e instante UTC (ADR-12) · `criado_em` / `atualizado_em` / `excluido_em` = auditoria e soft delete (ADR-09) · um arquivo SQLite por usuário, sem `usuario_id` nas tabelas locais (ADR-13). Os comentários entre aspas resumem as restrições; o detalhe está no dicionário de dados.

### 3.1 Nuvem — Supabase (PostgreSQL) · schema privado `kortex`, acesso só pelo papel `kortex_api` (ADR-05)

```mermaid
erDiagram
    usuarios ||--o{ refresh_tokens : "possui"
    usuarios ||--o{ codigos_verificacao : "solicita"
    usuarios ||--o| chaves_backup : "possui"
    usuarios ||--o{ feedbacks : "envia"
    usuarios |o--o{ feedbacks : "responde (admin)"
    usuarios |o--o{ notificacoes_sistema : "emite (admin)"
    refresh_tokens |o--o| refresh_tokens : "substituido_por"

    usuarios {
        uuid id PK
        varchar nome "100"
        varchar sobrenome "100"
        varchar email UK "150, unico por lower(email)"
        varchar senha_hash "BCrypt ou Argon2"
        timestamptz email_verificado_em "NULL"
        varchar status "ATIVO ou INATIVO"
        varchar tipo_usuario "COMUM ou ADMIN"
        varchar nivel_permissao "so ADMIN"
        smallint falhas_login "RN35"
        timestamptz bloqueado_ate "NULL, RN35"
        timestamptz criado_em
        timestamptz atualizado_em
    }
    refresh_tokens {
        uuid id PK
        uuid usuario_id FK "CASCADE"
        varchar token_hash UK
        varchar dispositivo "NULL"
        timestamptz criado_em
        timestamptz expira_em
        timestamptz revogado_em "NULL"
        uuid substituido_por FK "NULL"
    }
    codigos_verificacao {
        uuid id PK
        uuid usuario_id FK "CASCADE"
        varchar finalidade "inclui EXCLUIR_CONTA"
        varchar codigo_hash
        varchar novo_email "so TROCAR_EMAIL"
        smallint tentativas "0 a 5"
        timestamptz criado_em
        timestamptz expira_em
        timestamptz usado_em "NULL"
    }
    chaves_backup {
        uuid usuario_id PK, FK "CASCADE"
        bytea chave_cifrada
        smallint versao
        timestamptz criado_em
        timestamptz atualizado_em
    }
    feedbacks {
        uuid id PK
        uuid usuario_id FK "CASCADE"
        uuid admin_id FK "SET NULL"
        varchar tipo "BUG, SUGESTAO, OUTRO"
        text mensagem
        text resposta "NULL"
        timestamptz enviado_em
        timestamptz respondido_em "junto com resposta"
    }
    notificacoes_sistema {
        uuid id PK
        uuid admin_id FK "SET NULL"
        varchar titulo "100"
        text conteudo
        timestamptz criado_em
        timestamptz expira_em "NULL, maior que criado_em"
    }
```

### 3.2 Local — Finanças (SQLite)

```mermaid
erDiagram
    contas ||--o{ transacoes_financeiras : "movimenta"
    categorias_financeiras ||--o{ transacoes_financeiras : "classifica"
    categorias_financeiras |o--o{ categorias_financeiras : "subcategoria"
    contas ||--o{ transferencias : "origem"
    contas ||--o{ transferencias : "destino"
    transacoes_financeiras ||--o{ transacoes_tags : "tem"
    tags ||--o{ transacoes_tags : "marca"
    parcelamentos |o--o{ transacoes_financeiras : "parcelas"
    recorrencias |o--o{ transacoes_financeiras : "ocorrencias"
    contas ||--o{ recorrencias : "debita"
    categorias_financeiras ||--o{ recorrencias : "classifica"

    parcelamentos {
        text id PK
        text descricao
        integer valor_total_centavos
        integer quantidade_parcelas "2 a 48"
        text data_compra "data local"
        text forma_pagamento "DEBITO, CREDITO, PIX, DINHEIRO"
        text criado_em
        text atualizado_em
        text excluido_em
    }
    recorrencias {
        text id PK
        text tipo "DESPESA"
        text conta_id FK "RESTRICT"
        text categoria_id FK "RESTRICT"
        text descricao
        integer valor_centavos
        text forma_pagamento
        text frequencia "SEMANAL, MENSAL, ANUAL"
        text data_inicio "data local"
        text data_fim "NULL = sem fim"
        text ultima_gerada_em
        integer ativa "0 ou 1"
        text observacao
        text criado_em
        text atualizado_em
        text excluido_em
    }

    contas {
        text id PK
        text nome
        text tipo "CORRENTE, CARTEIRA, POUPANCA, INVESTIMENTO"
        integer saldo_inicial_centavos
        text cor_hex "#RRGGBB"
        text icone_codigo
        integer principal "0 ou 1, no maximo uma"
        integer arquivada "0 ou 1"
        text criado_em
        text atualizado_em
        text excluido_em
    }
    categorias_financeiras {
        text id PK
        text categoria_pai_id FK "1 nivel, mesmo tipo"
        text nome
        text tipo "RECEITA ou DESPESA"
        text cor_hex
        text icone_codigo
        integer padrao "0 ou 1"
        integer arquivada "0 ou 1"
        text criado_em
        text atualizado_em
        text excluido_em
    }
    transacoes_financeiras {
        text id PK
        text conta_id FK "RESTRICT"
        text categoria_id FK "RESTRICT"
        text tipo "igual ao da categoria"
        text descricao
        integer valor_centavos "maior que 0"
        text data_prevista "data local"
        text data_efetivacao "data local, NULL = pendente"
        text forma_pagamento "NULL ou DEBITO, CREDITO, PIX, DINHEIRO"
        text parcelamento_id FK "CASCADE, so despesa"
        integer parcela_numero "unico por compra"
        text recorrencia_id FK "SET NULL, unico por data"
        text observacao
        text criado_em
        text atualizado_em
        text excluido_em
    }
    transferencias {
        text id PK
        text conta_origem_id FK
        text conta_destino_id FK "diferente da origem"
        integer valor_centavos "maior que 0"
        text data "data local"
        text descricao
        text criado_em
        text atualizado_em
        text excluido_em
    }
    tags {
        text id PK
        text nome UK
        text criado_em
        text atualizado_em
        text excluido_em
    }
    transacoes_tags {
        text transacao_id PK, FK
        text tag_id PK, FK
    }
```

**Visão `vw_saldo_contas`:** saldo = saldo inicial + receitas efetivadas − despesas efetivadas + transferências recebidas − enviadas (RN13).

### 3.3 Local — Treinos (SQLite)

```mermaid
erDiagram
    pastas_rotinas |o--o{ rotinas : "agrupa"
    rotinas ||--o{ rotinas_dias_semana : "agendada em"
    rotinas ||--o{ rotinas_exercicios : "planeja"
    exercicios ||--o{ rotinas_exercicios : "usado em"
    rotinas |o--o{ sessoes_treino : "origina"
    sessoes_treino ||--o{ series_realizadas : "registra"
    exercicios ||--o{ series_realizadas : "executado em"

    pastas_rotinas {
        text id PK
        text nome
        integer ordem
        text criado_em
        text atualizado_em
        text excluido_em
    }
    exercicios {
        text id PK
        text nome
        text grupo_muscular
        text equipamento
        text video_execucao_url
        integer personalizado "0 = padrao do app"
        text criado_em
        text atualizado_em
        text excluido_em
    }
    rotinas {
        text id PK
        text pasta_id FK "SET NULL"
        text nome
        text local
        integer ativa "0 ou 1"
        text criado_em
        text atualizado_em
        text excluido_em
    }
    rotinas_dias_semana {
        text rotina_id PK, FK
        integer dia_semana PK "0 dom a 6 sab"
    }
    rotinas_exercicios {
        text id PK
        text rotina_id FK "CASCADE"
        text exercicio_id FK "RESTRICT"
        integer ordem "unico na rotina"
        integer series_alvo
        integer repeticoes_alvo
        integer carga_alvo_gramas "NULL = peso corporal"
        integer descanso_segundos
        text criado_em
        text atualizado_em
    }
    sessoes_treino {
        text id PK
        text rotina_id FK "SET NULL"
        text nome_rotina
        text data_local "dia do treino"
        text iniciada_em "UTC"
        text finalizada_em "UTC, NULL = em andamento"
        text observacao
        text criado_em
        text atualizado_em
        text excluido_em
    }
    series_realizadas {
        text id PK
        text sessao_id FK "CASCADE"
        text exercicio_id FK "RESTRICT"
        integer ordem_exercicio
        integer numero_serie
        integer carga_gramas "NULL = peso corporal"
        integer repeticoes
        integer concluida "0 ou 1"
        text criado_em
        text atualizado_em
    }
    registros_peso {
        text id PK
        text data "data local"
        integer peso_gramas
        text criado_em
        text atualizado_em
        text excluido_em
    }
```

**Visão `vw_recordes_exercicios`:** recordes de carga, volume e repetições por exercício (RN24).

### 3.4 Local — Tarefas e Geral (SQLite)

```mermaid
erDiagram
    pastas_tarefas ||--o{ tarefas : "contém"

    pastas_tarefas {
        text id PK
        text nome UK
        text icone
        text cor_hex "NULL"
        integer padrao "1 = Tarefas Pessoais, imutavel"
        integer ordem
        text criado_em
        text atualizado_em
        text excluido_em
    }
    tarefas {
        text id PK
        text pasta_id FK "RESTRICT"
        text titulo
        text descricao
        text data_prazo "data local"
        text hora_prazo "HH:MM local"
        text prioridade "BAIXA, MEDIA, ALTA"
        text concluida_em "UTC, NULL = pendente"
        text arquivada_em "UTC"
        text criado_em
        text atualizado_em
        text excluido_em
    }
    configuracoes {
        text chave PK "inclui usuario_id do dono"
        text valor
        text atualizado_em
    }
```

> Tokens (API e Google OAuth) ficam no SecureStore do Android, não no banco.
