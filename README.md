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
| **RF01** | Gerir Utilizadores | Cadastrar, consultar, atualizar e desativar contas de usuários. |
| **RF02** | Autenticar Acesso | Validar a entrada de utilizadores via e-mail e senha com suporte a recuperação de credenciais. |
| **RF03** | Visualizar Central | Apresentar uma tela inicial (Dashboard) com visualização em formato de calendário ou linha do tempo. |
| **RF04** | Centralizar Dados | Exibir de forma unificada no Dashboard as tarefas do dia, treinos agendados e o resumo financeiro atual. |
| **RF05** | Gerir Finanças | Registrar entradas (receitas) e saídas (despesas) com valor, data e descrição. |
| **RF06** | Categorizar Transações | Permitir a vinculação de despesas e receitas a categorias específicas para melhor organização. |
| **RF07** | Gerir Rotinas de Treino | Estruturar rotinas de treino organizadas por divisões customizáveis (Ex: Treino A, Treino B). |
| **RF08** | Registar Exercícios | Adicionar exercícios dentro de cada treino, contendo histórico de cargas, séries e repetições. |
| **RF09** | Gerir Tarefas (To-Do) | Criar listas de tarefas com título, descrição e prazo de conclusão para atividades fora da rotina. |
| **RF10** | Concluir Atividades | Permitir a marcação visual e o arquivamento de tarefas que foram concluídas pelo utilizador. |

### Requisitos Não-Funcionais

| ID | Requisito | Descrição |
| :--- | :--- | :--- |
| **RNF01** | Desempenho de Interface | O aplicativo deve apresentar uma navegação fluida, com transições de tela rápidas e sem engasgos (UI/UX ágil). |
| **RNF02** | Segurança de Dados | O sistema deve criptografar as senhas dos utilizadores e garantir que dados sensíveis não sejam expostos publicamente (LGPD). |
| **RNF03** | Arquitetura de Software | O código deve seguir padrões bem definidos (MVC ou Clean Architecture) para facilitar manutenções e o uso no portfólio de ADS. |
| **RNF04** | Persistência Local | O app deve armazenar os dados localmente no dispositivo para garantir consultas e funcionamento estável mesmo offline. |

---

## 🛡️ Controle de Qualidade (DoR / DoD)

Para garantir a qualidade das entregas no desenvolvimento solo, o projeto segue regras estritas de prontidão e conclusão:

> **Definition of Ready (DoR):** Uma tarefa só entra em desenvolvimento se o requisito estiver claro, o mapeamento de dados estruturado, o esboço da interface definido e a tarefa fragmentada para poucos dias de código.

> **Definition of Done (DoD):** Uma tarefa só é considerada concluída se o código estiver limpo/refatorado, testado manualmente no dispositivo/emulador, sem senhas ou chaves expostas e com a persistência no banco de dados validada.

---

## 📋 Backlog de Atividades

| ID | Atividade | Prioridade | Fase | Situação |
| :---: | :--- | :---: | :---: | :---: |
| **1** | Definir público-alvo e rodar pesquisa de validação | ALTA | 01 | CONCLUÍDO |
| **2** | Levantar requisitos funcionais e não funcionais | ALTA | 01 | CONCLUÍDO |
| **3** | Estruturar definições de qualidade (DoR e DoD) | ALTA | 01 | CONCLUÍDO |
| **4** | Criar repositório no GitHub | ALTA | 01 | CONCLUÍDO |
| **5** | Modelar Diagramas de Caso de Uso | ALTA | 02 | A FAZER |
| **6** | Modelar Diagrama de Classes Geral | ALTA | 02 | A FAZER |
| **7** | Modelar Diagramas de Classes por Caso de Uso | MÉDIA | 02 | A FAZER |
| **8** | Modelar Diagramas de Sequência por Caso de Uso | MÉDIA | 02 | A FAZER |
| **9** | Desenhar a Modelagem de Dados e DER (Modelo Entidade-Relacionamento) | ALTA | 02 | A FAZER |
| **10** | Desenvolver Prototipagem (Foco em UI/UX e Responsividade) | ALTA | 03 | A FAZER |
| **11** | Configurar ambientes e iniciar desenvolvimento do Backend em C# / .NET | ALTA | 04 | A FAZER |
| **12** | Desenvolver Front-end do Aplicativo Mobile integrado às APIs do Backend | ALTA | 04 | A FAZER |
| **13** | Realizar testes de integração, persistência e homologação do MVP | MÉDIA | 05 | A FAZER |

---

## 🛠️ Stack Tecnológica

* **Backend:** C# / .NET (ASP.NET Core)
* **Mobile (Android/iOS):** *[A definir]*
* **Modelagem e Design:** StarUML / Figma

---

## 📈 Padronização de Commits

Este repositório segue estritamente as especificações do **Conventional Commits** para manter o histórico de evolução legível e profissional:
* `feat`: Novas funcionalidades.
* `fix`: Correções de bugs.
* `docs`: Alterações em documentações (como este README).
* `style`: Mudanças visuais ou de formatação que não alteram a lógica.
* `chore`: Atualizações de build, pacotes ou configurações gerais.
