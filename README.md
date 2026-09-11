# 📊 Projeto 3 — Análise de Clientes

---

Análise de clientes de uma empresa fictícia de varejo/e-commerce brasileira, com foco em **recorrência, retenção, reativação e valor dos clientes**.

O projeto utiliza dados de 2023 a 2025 para transformar comportamento de compra em indicadores e oportunidades de negócio.

## ⭐ Principais resultados

- **R$ 8,69 mi de receita em 2025**, contra R$ 4,02 mi em 2024 e R$ 1,92 mi em 2023.
- A **margem permaneceu próxima de 38%** durante o período, mesmo com o crescimento da receita.
- **75,23% dos compradores fizeram no máximo 3 compras**, mostrando espaço para trabalhar a recorrência.
- **44,42% da base está inativa há mais de 180 dias**, além de 680 clientes que ainda não possuem uma compra concluída.
- Os **10% principais compradores concentram 38,33% da receita**; os 20% principais chegam a 57,44%.
- **Eletrônicos representa 52% da receita**, enquanto o **Sudeste concentra 45,32%**.
- Na segmentação RFM, os **Campeões representam 17,73% dos compradores e 41,87% da receita**.

## 1. 📌 Contexto

Este projeto simula uma empresa brasileira de varejo/e-commerce que busca entender melhor o comportamento dos seus clientes e identificar oportunidades de crescimento, retenção e aumento de valor.

A análise foi feita a partir de dados cadastrais e transacionais, com foco em aquisição, recorrência, retenção, reativação e segmentação.

## 2. 🎯 Objetivo

Analisar o comportamento da base de clientes entre 2023 e 2025 e identificar os principais pontos relacionados à recorrência, valor gerado e retenção.

Além disso, transformar os resultados em indicadores que possam apoiar decisões comerciais.

## 3. 💡 Perguntas de negócio

- Como receita, lucro, margem e pedidos evoluíram entre 2023 e 2025?
- Como a base de clientes evoluiu?
- Qual é o nível de recorrência e frequência de compra?
- Quantos clientes estão ativos, em atenção ou inativos?
- Quais segmentos geram mais valor?
- Quais clientes apresentam maior potencial de retenção ou reativação?
- Como os clientes se distribuem na segmentação RFM?
- Existem diferenças relevantes entre regiões, canais e categorias?

## 4. 🗂️ Dataset

A base é fictícia e representa uma operação de varejo/e-commerce brasileira entre 2023 e 2025.

- **5.000 clientes**
- **13.553 pedidos**
- **13.019 pedidos concluídos**
- **120 produtos**
- **4.320 clientes compradores**
- **2.847 clientes recorrentes**
- **1.473 clientes com apenas uma compra**
- **680 clientes sem compra concluída**

Para as análises financeiras e de comportamento, foram considerados apenas pedidos concluídos.

## 5. 🛠️ Ferramentas utilizadas

- **SQL / SQLite:** exploração, tratamento, validação e análises;
- **Power BI:** modelagem, medidas DAX e dashboard;
- **Excel / CSV:** armazenamento e disponibilização das bases;
- **Visual Studio Code:** organização dos arquivos e consultas SQL.

## 6. 🧹 Tratamento e regras de análise

Antes das análises, foram verificadas a estrutura das tabelas, os relacionamentos, datas, status dos pedidos e valores financeiros.

Principais regras:

- Receita = quantidade × preço unitário × (1 - desconto)
- Custo = quantidade × custo unitário
- Lucro = receita - custo
- Ticket médio = receita / pedidos concluídos
- Cliente recorrente = dois ou mais pedidos concluídos
- Ativo = última compra há até 90 dias
- Em atenção = última compra entre 91 e 180 dias
- Inativo = última compra há mais de 180 dias
- RFM = recência, frequência e valor monetário

A classificação de churn é **analítica**, baseada na recência de compra. Não foi desenvolvido um modelo preditivo.

## 7. 📈 Análises realizadas

- Evolução de receita, lucro, margem, pedidos e ticket médio
- Aquisição e recorrência de clientes
- Frequência e intervalo entre compras
- Recência e status de atividade
- Retenção e clientes em risco
- Segmentação RFM
- Receita e comportamento por segmento
- Distribuição por região
- Desempenho por canal e categoria
- Concentração de receita entre clientes de maior valor

## 8. 🔎 Principais insights

### 🔹 Crescimento com margem estável

A receita passou de **R$ 1,92 mi em 2023 para R$ 8,69 mi em 2025**, enquanto a margem permaneceu próxima de 38%.

### 🔹 Recorrência é um ponto de atenção

Entre os 4.320 compradores, **1.473 fizeram apenas uma compra**. No total, 75,23% possuem no máximo três pedidos concluídos.

### 🔹 Existe uma janela para estimular a recompra

**62,43% dos intervalos entre compras acontecem em até 90 dias**, indicando uma oportunidade para ações de pós-venda e segunda compra.

### 🔹 Clientes de maior valor concentram receita

Os **10% principais compradores representam 38,33% da receita**. Na segmentação RFM, os Campeões concentram 41,87% da receita.

### 🔹 Há espaço para reativação

**2.221 clientes estão inativos há mais de 180 dias** e outros 654 estão em atenção. O grupo RFM Alto Valor também merece atenção, pois representa 21,27% da receita e possui recência média de 305 dias.

### 🔹 Eletrônicos concentra a operação

Eletrônicos responde por **52% da receita** e possui ticket médio de R$ 2.034,14. Esportes apresentou a maior margem, enquanto Livros teve baixa participação na receita e a menor margem observada.

### 🔹 Site lidera em volume

O Site concentra **51,92% da receita e 6.792 pedidos**. O App possui ticket médio um pouco maior, mas as margens são muito próximas.

## 9. 🚀 Recomendações

1. **Trabalhar a ativação dos clientes sem compra**, buscando converter os 680 clientes ainda não compradores e medir receita e margem incremental.

2. **Criar uma jornada de pós-compra**, principalmente para clientes de compra única, com ações nos primeiros 30, 60 e 90 dias.

3. **Priorizar a reativação de clientes em risco**, começando por grupos como Alto Valor e Em Risco e avaliando o retorno pela margem incremental.

4. **Proteger clientes Premium e Campeões**, priorizando relacionamento e benefícios em vez de descontos generalizados.

5. **Aumentar a recorrência do segmento Intermediário**, testando cross-sell e benefícios para a segunda ou terceira compra.

6. **Reduzir a dependência de Eletrônicos**, explorando vendas cruzadas com categorias de maior margem.

## 10. 📊 Dashboard

O dashboard em **Power BI** consolida os principais indicadores e permite explorar a base por diferentes períodos e características dos clientes.

Principais indicadores e análises:

- Receita
- Lucro
- Margem
- Pedidos
- Ticket médio
- Clientes compradores
- Recorrência
- Status de atividade
- Segmentação RFM
- Receita por região, categoria e canal

> 🖼️ **Dashboard:** adicione aqui uma imagem do dashboard (`images/dashboard.png`) para facilitar a visualização do projeto no GitHub.

## 11. ✅ Conclusão

A análise mostrou uma base com forte crescimento de receita, mas também com oportunidades importantes em **recorrência, retenção e reativação**.

Os principais pontos de atenção estão na quantidade de clientes inativos ou sem compra, na concentração da receita em clientes de maior valor e na dependência de Eletrônicos.

O projeto conecta **SQL, análise de dados e Power BI** para transformar dados de clientes em indicadores e recomendações de negócio.
