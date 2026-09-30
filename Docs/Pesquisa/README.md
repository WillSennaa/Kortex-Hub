# 📊 Pesquisa de Campo e Validação de Mercado

**🔗 Link para o formulário original:** [[Clique Aqui](https://forms.gle/j2Dr5jEJ1Dv2zK517)]

## 1. Objetivo da Pesquisa
Antes de iniciar o desenvolvimento do **Kortex Hub**, foi realizada uma pesquisa quantitativa e qualitativa via Google Forms para validar a existência do problema (a fragmentação da rotina em múltiplos aplicativos) e mapear as reais necessidades do público-alvo. O questionário obteve um total de **13 respostas**.

---

## 2. Perguntas Estruturadas e Resultados Quantitativos

Abaixo estão as métricas coletadas que guiaram a construção do escopo do aplicativo:

**Q1. Qual a sua faixa etária?**
* **18 a 25 anos:** 46,2%
* **26 a 30 anos:** 23,1%
* *Insight:* O público-alvo principal é jovem adulto, exigindo uma interface moderna e ágil.

**Q2. Qual a sua ocupação principal?**
* **Trabalhador CLT:** 61,5%
* **Autônomo:** 23,1%
* **Estudante:** 15,4%

**Q3. Quantos aplicativos de produtividade/organização você utiliza atualmente?**
* **Resultado:** 61,6% dos entrevistados utilizam 2 ou mais aplicativos simultâneos para gerenciar a rotina.
  * *2 aplicativos:* 30,8%
  * *3 aplicativos:* 23,1%
  * *4 ou mais:* 7,7%

**Q4. Em uma escala de 1 a 5, qual o seu nível de incômodo por ter que alternar entre vários aplicativos no dia a dia?**
* **Resultado:** 53,9% declararam incômodo elevado (marcaram notas 4 e 5 na escala).

**Q5. Você utilizaria um aplicativo único que centralizasse suas finanças, treinos e tarefas?**
* **Resultado:** 84,6% afirmaram categoricamente que adotariam a solução centralizada.

**Q6. Quais desses módulos seriam prioridade para você? (Múltipla escolha)**
* **Finanças:** 84,6%
* **Treinos:** 53,8%
* **Tarefas Diárias:** 46,2%

---

## 3. Respostas Abertas e Insights Qualitativos (O que moldou o MVP)

Além dos números, as respostas abertas e sugestões dos usuários definiram funcionalidades cruciais que foram diretamente implementadas nos Requisitos do Sistema:

* **Visor Central Unificado (Dashboard):** Houve pedidos recorrentes para a criação de um "calendário com barras para as tarefas diárias" e "abas/sessões por dia, mês e ano". Isso motivou a criação do Dashboard em formato de linha do tempo com carrossel dinâmico.
* **Módulo Fitness Avançado:** Forte demanda por acompanhamento de evolução, resultando na inclusão obrigatória do registro do histórico de cargas para os exercícios no banco de dados.
* **Velocidade de Inserção:** Feedbacks apontaram a necessidade de "rapidez para adicionar um gasto sem ter que clicar muito". Isso justificou o Requisito Não-Funcional de Desempenho de Interface (RNF01), guiando o design a ter botões de atalho flutuantes na Home.