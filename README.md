# 🧠 Kortex Hub

> O Sistema Operacional integrado para a sua rotina pessoal.

O **Kortex Hub** é um aplicativo desenvolvido para centralizar as principais vertentes da organização diária em um único lugar: **Finanças, Treinos e Tarefas**. A ideia nasceu da necessidade de combater a fragmentação de dados gerada pelo uso de múltiplos aplicativos de produtividade.

---

## 📊 Validação de Mercado (Baseado em Dados Reais)

O escopo do Kortex Hub foi validado estatisticamente através de uma pesquisa quantitativa e qualitativa com o público-alvo (majoritariamente trabalhadores CLT de 18 a 30 anos). Os dados coletados justificam e validam a existência do produto:

* **Centralização Necessária:** 61,6% dos entrevistados usam 2 ou mais aplicativos simultâneos para tentar gerenciar a sua rotina.
* **Dor de Mercado Clara:** 53,9% relatam incômodo elevado (Notas 4 e 5 de 5) com a fragmentação de ter que abrir múltiplos apps no dia a dia.
* **Aderência do MVP:** **84,6%** afirmaram categoricamente que utilizariam uma solução centralizada como o Kortex Hub.
* **Áreas de Maior Interesse:** Finanças lidera com **84,6%** de necessidade de controle, seguida por Treinos com **53,8%** e Tarefas Diárias com **46,2%**.

---

## 🎯 Requisitos do Sistema

O escopo do projeto foi desenhado focando em um MVP (Mínimo Produto Viável) robusto, refinado com base nos feedbacks qualitativos da pesquisa (como a necessidade de um calendário e atalhos rápidos de inserção).

### Requisitos Funcionais

| ID | Requisito | Descrição |
| :--- | :--- | :--- |
| **RF01** | Gerir Usuários | Cadastrar, consultar, atualizar e desativar contas de usuários. |
| **RF02** | Autenticar Acesso | Validar a entrada de usuários somente via e-mail e senha, com suporte a recuperação de credenciais e uso offline após o primeiro login. |
| **RF03** | Visualizar Central | Apresentar uma tela inicial (Dashboard) com visualização em formato de calendário ou linha do tempo. |
| **RF04** | Centralizar Dados | Exibir de forma unificada no Dashboard as tarefas do dia, treinos agendados e o resumo financeiro atual. |
| **RF05** | Gerir Finanças | Cadastrar contas/carteiras, registrar receitas e despesas (pendentes ou efetivadas) com valor, data e descrição e transferir valores entre contas. |
| **RF06** | Categorizar Transações | Vincular despesas e receitas a categorias e subcategorias, com ícone e cor, para melhor organização. |
| **RF07** | Gerir Rotinas de Treino | Estruturar rotinas por divisões customizáveis (Ex: Treino A, Treino B), agendadas por dia da semana e agrupadas em pastas. |
| **RF08** | Registrar Treinos e Exercícios | Executar treinos registrando cada série (carga e repetições), com histórico, recordes e evolução do peso corporal. |
| **RF09** | Gerir Tarefas (To-Do) | Criar tarefas com título, descrição, prazo e prioridade, organizadas em pastas. |
| **RF10** | Concluir Atividades | Permitir a marcação visual e o arquivamento de tarefas concluídas pelo usuário, com progresso diário. |
| **RF11** | Backup na Conta Google | Conectar uma conta Google para salvar e restaurar um backup cifrado dos dados de todos os módulos no Google Drive. |
| **RF12** | Comunicar com a Plataforma | Enviar feedbacks e visualizar avisos globais; ADMs respondem feedbacks e emitem avisos. |

### Requisitos Não-Funcionais

| ID | Requisito | Descrição |
| :--- | :--- | :--- |
| **RNF01** | Desempenho de Interface | O aplicativo deve apresentar uma navegação fluida, com transições de tela rápidas e sem engasgos (UI/UX ágil). |
| **RNF02** | Segurança de Dados | O sistema deve aplicar hash às senhas dos usuários, bloquear o acesso público ao banco em nuvem (RLS) e cifrar os backups, garantindo que dados sensíveis não sejam expostos (LGPD). |
| **RNF03** | Arquitetura de Software | O código deve seguir padrões bem definidos (MVC ou Clean Architecture) para facilitar manutenções e o uso no portfólio de ADS. |
| **RNF04** | Persistência Local | O app deve armazenar os dados dos módulos localmente (SQLite) para garantir consultas e funcionamento estável mesmo offline. |

---

## 🛡️ Controle de Qualidade (DoR / DoD)

Para garantir a qualidade das entregas no desenvolvimento solo, o projeto segue regras estritas de prontidão e conclusão:

> **Definition of Ready (DoR):** Uma tarefa só entra em desenvolvimento se o requisito estiver claro, o mapeamento de dados estruturado, o esboço da interface definido e a tarefa fragmentada para poucos dias de código.

> **Definition of Done (DoD):** Uma tarefa só é considerada concluída se o código estiver limpo/refatorado, testado manualmente no dispositivo/emulador, sem senhas ou chaves expostas e com a persistência no banco de dados validada.

---

#### 📋 Backlog de Atividades
| ID | Atividade | Prioridade | Fase | Situação |
| :--- | :--- | :--- | :--- | :--- |
| **1** | Definir público-alvo e rodar pesquisa de validação | ALTA | 01 | CONCLUÍDO |
| **2** | Levantar requisitos funcionais e não funcionais | ALTA | 01 | CONCLUÍDO |
| **3** | Estruturar definições de qualidade (DoR e DoD) | ALTA | 01 | CONCLUÍDO |
| **4** | Criar repositório no GitHub | ALTA | 01 | CONCLUÍDO |
| **5** | Modelar Diagramas de Caso de Uso | ALTA | 02 | CONCLUÍDO |
| **6** | Modelar Diagrama de Classes Geral | ALTA | 02 | CONCLUÍDO |
| **7** | Desenhar a Modelagem de Dados e DER (Modelo Entidade-Relacionamento em 3FN) | ALTA | 02 | CONCLUÍDO |
| **8** | Desenvolver Prototipagem de Telas e Guia de Estilos no Figma (UI/UX) | ALTA | 03 | CONCLUÍDO |
| **9** | Realizar testes de usabilidade do protótipo | ALTA | 03 | EM ANDAMENTO |
| **10** | Configurar o banco no Supabase | ALTA | 04 | A FAZER |
| **11** | Configurar ambientes e iniciar desenvolvimento do Backend em C# / .NET | ALTA | 04 | A FAZER |
| **12** | Desenvolver e executar Testes Unitários no Backend em C# / .NET (xUnit/NUnit) | ALTA | 04 | A FAZER |
| **13** | Desenvolver Front-end Mobile em React Native (Focado em Android) | ALTA | 04 | A FAZER |
| **14** | Desenvolver e executar Testes Unitários no Front-end React Native (Jest/RTL) | ALTA | 04 | A FAZER |
| **15** | Implementar persistência local (SQLite + migrações) e backup cifrado na conta Google do usuário | ALTA | 04 | A FAZER |
| **16** | Realizar testes de integração, persistência offline e homologação do MVP | MÉDIA | 05 | A FAZER |

---

#### 📚 Documentação

* [Requisitos detalhados](Docs/README.md)
* [Regras de Negócio e ADRs](Docs/REGRAS_DE_NEGOCIO_E_ADR.md)
* [Dicionário de Dados e DDL](Docs/Dicionario%20Dados%20e%20DDL/README.md)
* Diagramas: [fonte .drawio](Diagramas/Diagramas_Kortex.drawio) · [Casos de Uso](Diagramas/Casos_de_Uso.png) · [Classes](Diagramas/Classes.png) · [DER](Diagramas/DER.png)
* [Protótipo e Guia de Estilos](Prototipo/)

---

#### 🛠️ Stack Tecnológica
*   **Backend:** C# / .NET (ASP.NET Core)
*   **Banco de Dados (Nuvem — somente conta e autenticação):** Supabase (PostgreSQL)
*   **Banco de Dados (Local — dados dos módulos):** SQLite no dispositivo
*   **Backup:** Google Drive do usuário (OAuth)
*   **Mobile (Apenas Android no MVP):** React Native (JavaScript / TypeScript)
*   **Modelagem e Design:** Draw.io / Figma

⚠️ **Nota de Desenvolvimento (Git):** Os arquivos de modelagem `.drawio` estão configurados como **binários** no `.gitattributes` para evitar quebras e conflitos de merge no XML. Em caso de conflito, escolha a versão correta (`ours` ou `theirs`) diretamente via Git e reabra o arquivo no editor visual.

---

## 📈 Padronização de Commits

Este repositório segue estritamente as especificações do **Conventional Commits** para manter o histórico de evolução legível e profissional:
* `feat`: Novas funcionalidades.
* `fix`: Correções de bugs.
* `docs`: Alterações em documentações (como este README).
* `style`: Mudanças visuais ou de formatação que não alteram a lógica.
* `chore`: Atualizações de build, pacotes ou configurações gerais.
