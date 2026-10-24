# Peculium

**Gestão financeira v2** — finanças pessoais compartilhadas para casais e famílias.

> O nome vem do latim *peculium*: o pecúlio que o chefe da família confiava a outro membro para administrar.

> **Status:** em planejamento. As decisões de arquitetura e o modelo de dados estão fechados; a implementação ainda não começou.

## Ideia

Um espaço único para a casa toda: cada pessoa lança e acompanha os próprios gastos, divide compras com quem consumiu junto e, no fim do período, o sistema mostra quem deve quanto a quem. O foco do produto é **controlar os gastos do próximo mês**.

## O que o sistema vai fazer

- **Contas a pagar e a receber** em um título único, com baixa parcial, juros, multa, desconto e estorno.
- **Cartões de crédito e faturas**, com compras parceladas, limite disponível e comparação entre realizado e previsto.
- **Rateio entre participantes** (em reais ou percentual), separando quem pagou, quem comprou e quem consumiu.
- **Acerto entre participantes**, gerado como título a receber a partir do relatório.
- **Importação de extratos** (OFX e CSV) idempotente, com sugestão de categoria, responsável e rateio, e conciliação sempre confirmada pelo usuário.
- **Recorrências e salário**, gerando títulos previstos dentro de um horizonte configurável.
- **Papéis e privacidade**: dono, editor, colaborador e leitor. Cada pessoa vê o que lançou ou o que a envolve, e pode liberar a visão total para outro membro.
- **Auditoria** de toda operação, somente inserção.
- **Relatórios**: fluxo de caixa, gastos por categoria, gastos por participante, acerto entre participantes, meus gastos e visão total.

## Princípios do modelo

- Valores sempre em **centavos (inteiro) e positivos**; o sinal vem do tipo ou da direção. Moeda única: BRL.
- Ciclo do dinheiro: **Título → Baixa → Movimento da conta → Conciliação**.
- O movimento da conta é a única coisa que altera saldo.
- Toda tabela pertence a um espaço (`espaco_id`) e toda consulta filtra por ele.
- Relatórios usam o mês de vencimento; para compras no cartão, o vencimento da fatura.

## Stack prevista

| Camada | Tecnologia |
| --- | --- |
| Front-end | React, TypeScript |
| Back-end | Node.js, Fastify, TypeScript |
| Banco de dados | PostgreSQL no Supabase (plano gratuito) |
| Autenticação | Supabase Auth |

## Documentação

- [Decisões e modelo de dados](docs/decisoes-e-modelo-de-dados.md): histórico consolidado das decisões, regras de negócio e o script SQL completo do banco.

## Próximos passos

- [ ] Executar o script SQL num projeto de teste do Supabase.
- [ ] Estruturar o monorepo (`backend` e `frontend`).
- [ ] Cadastro, espaço, convites e papéis.
- [ ] Títulos, baixas e movimentos de conta.
- [ ] Importação de extratos e conciliação.
- [ ] Cartões, faturas e parcelamentos.
- [ ] Relatórios.

## Autor

Feito por [Humberto Queiroz](https://github.com/HumbertoQueiroz).
