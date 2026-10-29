# 🧠 Kortex Hub

> O Sistema Operacional integrado para a sua rotina pessoal.

O **Kortex Hub** é um aplicativo desenvolvido para centralizar as principais vertentes da organização diária em um único lugar: **Finanças, Treinos e Tarefas**. A ideia nasceu da necessidade de combater a fragmentação de dados gerada pelo uso de múltiplos aplicativos de produtividade.

---

## 📊 Pesquisa com o Público-Alvo

Antes do desenvolvimento, foi aplicada uma pesquisa exploratória com **13 pessoas**, a maioria trabalhadores CLT (8 de 13) entre 18 e 30 anos (9 de 13). Com essa amostra, os resultados indicam tendências, mas não têm valor estatístico ([detalhes, limitações e respostas abertas](Docs/Pesquisa/README.md)).

* **Áreas que já organizam com apps:** Finanças (11 de 13), Treinos (7), Tarefas diárias (6), Alimentação (4) e Estudos (3). Esses números orientaram a escolha dos três módulos do MVP.
* **Uso de vários apps:** 8 de 13 usam 2 ou mais aplicativos para gerenciar a rotina.
* **Interesse em um app centralizado:** 11 de 13 responderam "Sim", 2 "Talvez" e ninguém "Não". A pergunta apresentava a solução, o que tende a inflar as respostas positivas.
* **Incômodo:** 7 de 13 deram nota 4 ou 5 ao incômodo de usar vários apps. Porém, quem usa um app só se incomodou tanto ou mais do que quem usa vários (3 de 4 contra 4 de 8), então a fragmentação não aparece como causa clara.
* **Pedidos na pergunta aberta:** calendário ou visão por dia (3), que virou o Dashboard; registro rápido (2), que virou os atalhos da Home; integração com Google Agenda (3) e alimentação (3), que ficaram fora do MVP.

---

## 🎯 Requisitos do Sistema

O escopo do projeto foi desenhado focando em um MVP (Mínimo Produto Viável) robusto, refinado com base nos feedbacks qualitativos da pesquisa (como a necessidade de um calendário e atalhos rápidos de inserção).

### Requisitos Funcionais

| ID | Requisito | Descrição |
| :--- | :--- | :--- |
| **RF01** | Gerir Usuários | Cadastrar, consultar, atualizar, desativar e excluir contas de usuários (exclusão pelo app ou por link web). |
| **RF02** | Autenticar Acesso | Validar a entrada de usuários somente via e-mail e senha, com suporte a recuperação de credenciais e uso offline após o primeiro login. |
| **RF03** | Visualizar Central | Apresentar uma tela inicial (Dashboard) com visualização em formato de calendário ou linha do tempo. |
| **RF04** | Centralizar Dados | Exibir de forma unificada no Dashboard as tarefas do dia, treinos agendados e o resumo financeiro atual. |
| **RF05** | Gerir Finanças | Cadastrar contas/carteiras, registrar receitas e despesas (pendentes ou efetivadas) com valor, data, descrição e forma de pagamento, parcelar despesas, repetir despesas periodicamente e transferir valores entre contas. |
| **RF06** | Categorizar Transações | Vincular despesas e receitas a categorias e subcategorias, com ícone e cor, e a tags livres, para melhor organização. |
| **RF07** | Gerir Rotinas de Treino | Estruturar rotinas por divisões customizáveis (Ex: Treino A, Treino B), agendadas por dia da semana e agrupadas em pastas. |
| **RF08** | Registrar Treinos e Exercícios | Executar treinos registrando cada série (carga e repetições), com histórico, recordes e evolução do peso corporal. |
| **RF09** | Gerir Tarefas (To-Do) | Criar tarefas com título, descrição, prazo e prioridade, organizadas em pastas. |
| **RF10** | Concluir Atividades | Permitir a marcação visual e o arquivamento de tarefas concluídas pelo usuário, com progresso diário. |
| **RF11** | Backup na Conta Google | Conectar uma conta Google para salvar e restaurar um backup cifrado dos dados de todos os módulos no Google Drive. |
| **RF12** | Comunicar com a Plataforma | Enviar feedbacks e visualizar avisos globais; ADMs respondem feedbacks, emitem avisos e gerenciam ADMs numa área de administração do próprio app, visível só para eles. |
| **RF13** | Compartilhar Rotina | Compartilhar uma rotina de treino com amigos como texto ou imagem, pelo menu de compartilhamento do Android, com link para baixar o app. |

### Requisitos Não-Funcionais

| ID | Requisito | Descrição |
| :--- | :--- | :--- |
| **RNF01** | Desempenho de Interface | Registro rápido em sequência curta (conta principal e data de hoje já preenchidas; o usuário informa valor e categoria e salva); abrir o app em até 2 segundos; trocar de tela em até 300 ms, num Android intermediário. |
| **RNF02** | Segurança de Dados | O sistema deve aplicar hash às senhas dos usuários, limitar tentativas de login, bloquear o acesso público ao banco em nuvem e cifrar os backups, garantindo que dados sensíveis não sejam expostos (LGPD). |
| **RNF03** | Arquitetura de Software | API em C# com Clean Architecture (camadas Domain, Application, Infrastructure e Api) e Programação Orientada a Objetos; app organizado por módulo (Finanças, Treinos, Tarefas, Conta), com as regras de negócio separadas das telas. |
| **RNF04** | Persistência Local | O app deve armazenar os dados dos módulos localmente (SQLite) para garantir consultas e funcionamento estável mesmo offline. |
| **RNF05** | Temas Claro e Escuro | O app oferece tema claro e escuro; na primeira abertura segue o tema do sistema e depois respeita a escolha do usuário em Configurações. |

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
| **13** | Desenvolver Front-end Mobile em React Native com Expo (Focado em Android) | ALTA | 04 | A FAZER |
| **14** | Desenvolver e executar Testes Unitários no Front-end React Native (Jest/RTL) | ALTA | 04 | A FAZER |
| **15** | Implementar persistência local (SQLite + migrações) e backup cifrado na conta Google do usuário | ALTA | 04 | A FAZER |
| **16** | Realizar testes de integração, persistência offline e homologação do MVP | MÉDIA | 05 | A FAZER |

---

#### 📚 Documentação

* [Requisitos detalhados](Docs/README.md)
* [Regras de Negócio e ADRs](Docs/REGRAS_DE_NEGOCIO_E_ADR.md)
* [Dicionário de Dados e DDL](Docs/Dicionario%20Dados%20e%20DDL/README.md)
* [Diagramas (Mermaid)](Diagramas/README.md): [Casos de Uso](Diagramas/README.md#1-casos-de-uso) · [Classes](Diagramas/README.md#2-diagrama-de-classes) · [DER](Diagramas/README.md#3-der--modelo-entidade-relacionamento)
* [Protótipo e Guia de Estilos](Prototipo/)

---

#### 🛠️ Stack Tecnológica
*   **Backend:** C# / .NET (ASP.NET Core), Clean Architecture
*   **Banco de Dados (Nuvem — somente conta e autenticação):** Supabase (PostgreSQL)
*   **Banco de Dados (Local — dados dos módulos):** SQLite no dispositivo
*   **Backup:** Google Drive do usuário (OAuth)
*   **Mobile (Apenas Android no MVP):** React Native com Expo (JavaScript / TypeScript), builds pelo EAS
*   **Modelagem e Design:** Mermaid (diagramas no GitHub) / Figma

⚠️ **Nota de Desenvolvimento (Git):** Os arquivos de modelagem `.drawio` estão configurados como **binários** no `.gitattributes` para evitar quebras e conflitos de merge no XML. Em caso de conflito, escolha a versão correta (`ours` ou `theirs`) diretamente via Git e reabra o arquivo no editor visual.

---

## 📈 Padronização de Commits

Este repositório segue estritamente as especificações do **Conventional Commits** para manter o histórico de evolução legível e profissional:
* `feat`: Novas funcionalidades.
* `fix`: Correções de bugs.
* `docs`: Alterações em documentações (como este README).
* `style`: Mudanças visuais ou de formatação que não alteram a lógica.
* `chore`: Atualizações de build, pacotes ou configurações gerais.
