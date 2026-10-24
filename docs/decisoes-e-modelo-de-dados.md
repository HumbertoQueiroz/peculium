# Sistema Financeiro Familiar — Decisões e Modelo de Dados

Documento de contexto com o histórico consolidado das decisões de arquitetura e o modelo do banco (PostgreSQL no Supabase). Stack prevista: React, TypeScript, Node.js, Fastify, PostgreSQL hospedado no Supabase (plano gratuito). As decisões aparecem no estado final; quando uma decisão substituiu outra, isso é indicado.

## 1. Visão geral

- Sistema de **finanças pessoais compartilhado** (casal/família no mesmo espaço).
- Escopo: contas a pagar e a receber, categorias, centros de custo, relatórios, cartões, parcelamentos, recorrências, fluxo de caixa e conciliação bancária.
- **Uma moeda por espaço** (padrão BRL), sem câmbio. Valores sempre **inteiros na unidade menor da moeda** (centavos, no real) e **positivos**; o sinal vem do tipo/direção. Detalhes em [convenções](convencoes.md).
- Foco do produto: **controlar os gastos do próximo mês**.
- Ciclo do dinheiro: **Título → Baixa → MovimentoConta → Conciliação**, com auditoria em tudo.

## 2. Espaço, usuários, participantes

- **Espaço**: a "casa" no sistema. Toda tabela tem `espacoId` e toda consulta filtra por ele (equivalente à filial no Protheus).
- **Usuário**: quem tem login. **Membro**: usuário dentro de um espaço, com papel. Relação usuário–espaço N:N.
- **Participante**: quem gasta, com ou sem login (ex.: Filho 1). Cada membro tem um participante vinculado.
- Ao se cadastrar e confirmar o e-mail, o sistema cria um espaço com o usuário como dono e participante.
- **Convite**: pela lista de participantes (vincula o login a um participante existente, preservando o histórico) ou pelo botão "convidar novo" (cria o participante e envia o convite).
- Configurações do espaço: dia de fechamento (padrão 5), fuso horário, moeda, notificações por e-mail (nascem ligadas).

## 3. Papéis e privacidade

**Papéis** (o que cada um pode fazer):

- **Dono**: tudo; único que gerencia membros, convites e configurações. O espaço tem sempre pelo menos um dono.
- **Editor**: lança, edita, importa, concilia, rateia e gera acertos.
- **Colaborador**: vê e **solicita alterações** (ex.: "não fui eu, foi fulano"). Quem lançou o título ou qualquer dono aprova ou recusa. Ao aprovar, a alteração é aplicada com auditoria.
- **Leitor**: só visualiza.

**Privacidade** (o que cada um vê):

- O espaço nasce **privado**: cada usuário vê os lançamentos que fez.
- Também vê os lançamentos em que é **responsável ou participa do rateio**, com o valor total e a sua parte.
- Cada usuário pode **liberar a visão total** dos seus lançamentos para outro membro, nas configurações pessoais. Só ele libera; pode desfazer a qualquer momento. Não há liberação parcial.
- O papel define o que pode fazer; a privacidade define o que vê. Ninguém edita o que não vê, nem o dono.
- Notificações dentro do sistema e por e-mail; e-mail pode ser desligado nas configurações do espaço. Tela de Solicitações com contador e selo de "alteração pendente" no título.

## 4. Título financeiro

- **Tabela única `Titulo`** para pagar e receber, com `natureza` (PAGAR/RECEBER). Separação estilo SE1/SE2 do Protheus não se justifica aqui, pois os campos e regras são iguais.
- Duas datas: `dataCompetencia` (quando ocorreu) e `dataVencimento` (quando o dinheiro sai/entra).
- `valorOriginal`, `valorPrevisto` (estimado, ex.: luz), `saldo` e `totalDesconto` armazenados e atualizados na transação.
- Status derivado do saldo: ABERTO, PARCIAL, QUITADO, CANCELADO.
- Categoria com no máximo 2 níveis; um centro de custo (projeto) por título.
- Soft delete (`excluidoEm`).

## 5. Baixa

- Título e Baixa separados (1:N): permite pagamento parcial, juros, multa, desconto e estorno.
- `valorMovimentado = valorAmortizado + juros + multa − desconto`.
- Amortizado nunca maior que o saldo.
- Estorno sem apagar: marca `estornadaEm`, devolve o saldo e gera movimento inverso.
- Motivos: PAGAMENTO (gera movimento), PERDA e ABATIMENTO (não movimentam conta).
- **Juros e multa** vão para categorias de sistema próprias (pagos e recebidos).
- **Desconto reduz a categoria do título** (boleto de R$ 100 com R$ 5 de desconto = Educação R$ 95).
- Editar o valor de um pagamento é feito na baixa; movimento e saldo são recalculados.

## 6. MovimentoConta

- Extrato interno de cada conta e **única coisa que altera saldo**.
- Origens: BAIXA, TRANSFERENCIA (sempre em par), AJUSTE (fora dos relatórios), SALDO\_INICIAL, ESTORNO.
- Saldo inicial é um movimento (não coluna da conta). `saldoAtual` armazenado, com rotina periódica de verificação.
- **Editável até ser conciliado**; edição propaga ao saldo na mesma transação. Movimento de baixa é editado pela baixa; transferência é editada como par; estornos não são editáveis.
- Lição da SE5 do Protheus: não misturar baixa, movimento bancário e valores acessórios na mesma tabela.

## 7. Auditoria

- Tabela genérica, **uma linha por operação**, alterações em JSONB (`{campo: {de, para}}`).
- Ações semânticas (CRIAR, ALTERAR, EXCLUIR, ESTORNAR, CONCILIAR, DESCONCILIAR, APROVAR\_SOLICITACAO).
- Origem: USUARIO, SISTEMA, IMPORTACAO. `correlacaoId` agrupa as linhas de uma mesma ação.
- Campos derivados (saldo, totais) não são auditados. Exclusão registra o estado completo.
- Somente inserção (revogar UPDATE/DELETE no PostgreSQL).
- **Capturada na aplicação**, dentro do `$transaction` (transação única no banco), por um ponto de entrada único (`executarOperacao(contexto, acao, fn)`); services recebem só o cliente transacional; teste de integração por operação.

## 8. Conciliação e importação

- Tabelas: ImportacaoExtrato, LinhaExtrato, Conciliacao (agrupamento N:M, soma das linhas = soma dos movimentos).
- Formatos: **OFX preferencial e CSV** com layouts por banco.
- A mesma fatura/extrato é importada **várias vezes**: importação idempotente.
  - Chave por ocorrência: FITID quando estável, senão `hash(data + valor + descrição normalizada) + nº da ocorrência`. Estratégia definida por layout.
  - Linhas ausentes numa nova importação ficam AUSENTE para revisão; linha alterada pelo banco é sugerida como substituta.
- Conciliação **sempre confirmada pelo usuário** (sugestões calculadas na hora; confirmação em lote permitida).
- Linha sem movimento: criar compra/título, transferência, ajuste ou ignorar.
- Linhas de extrato são imutáveis; conciliado bloqueia edição do movimento.
- Contas do tipo CARTEIRA não passam por conciliação.

## 9. Sugestões na importação

- Para cada linha, o usuário confirma **categoria, responsável e rateio**, todos sugeridos.
- Ordem da categoria: regra manual (prioridade, depois texto mais longo) → histórico (última categoria usada para a descrição normalizada) → sem sugestão.
- Ordem do responsável: regra manual → final do cartão adicional → histórico → titular da conta.
- Descrição normalizada: maiúsculas, sem acentos, sem sufixo de parcela, sem espaços duplicados.
- Histórico aprende categoria, responsável e rateio (em percentual) na confirmação.
- Ações em lote na revisão; confirmação gera título, baixa, movimento e rateios numa transação, conciliando a linha.
- Sugestão de criar regra quando o usuário corrige o histórico repetidamente.

## 10. Cartão de crédito e fatura

- **Cartão é uma Conta** (CARTAO\_CREDITO), com limite, dia de fechamento e vencimento.
- **Compra é um título baixado na conta cartão** (mesmo modelo para Pix, débito, dinheiro).
- **Pagamento da fatura é uma transferência** da conta para o cartão, ligada à fatura.
- Fatura criada sob demanda, chave (contaId, mesReferencia); faturas futuras com status FUTURA. Status: FUTURA, ABERTA, FECHADA, PAGA, PAGA\_PARCIAL.
- Compra pode ser movida para a fatura seguinte enquanto não paga. Rotativo vira saldo anterior da fatura seguinte.
- **Cartões físicos** (titular, adicional, virtual) ligados a participantes.
- Em contas a pagar e no fluxo de caixa, a fatura aparece como **uma linha**; as compras ficam no detalhe. Títulos com `faturaId` não aparecem soltos.
- **Realizado x previsto**: em toda tela de fatura e limite são exibidos os dois valores.
  - **Realizado**: compras importadas/lançadas e **todas as parcelas** (inclusive de faturas futuras).
  - **Previsto**: recorrências do cartão (ex.: Netflix) até aparecerem na fatura importada.
- **Limite disponível = limite − saldo devedor − parcelas futuras**. Recorrências previstas não consomem limite.
- Painel por participante segue o **consumo, respeitando o rateio** (calculado por view, não armazenado).

### Primeira importação

- Fluxo simples: cadastrar cartão → importar fatura → revisar → confirmar.
- Aceita fatura aberta (caso comum), fechada ou as duas, em qualquer ordem.
- Fatura fechada na implantação pergunta só "já foi paga?".
- Parcelas em andamento ("LOJA 03/10") criam o grupo automaticamente da parcela atual em diante; o grupo se estende para trás se uma fatura anterior for importada depois.
- Linhas de saldo anterior/pagamento da primeira fatura viram saldo inicial automaticamente.
- Entre fechamento e vencimento, se só a fatura aberta for importada, o sistema mostra aviso (não bloqueio) para importar a fechada.
- Se o OFX trouxer o limite do banco, divergência gera aviso.

### Apelido dos lançamentos

- A descrição importada fica gravada como `descricao_original` e nunca é alterada.
- Dono, editor e colaborador podem dar um **apelido** ao lançamento (exceção: o colaborador edita o apelido direto, sem solicitação). O leitor não pode. Só é possível editar o que o usuário consegue ver.
- Na tela, aparece o apelido em destaque e, logo abaixo, em fonte menor, a descrição original. Sem apelido, aparece só a descrição original.
- Em um parcelamento, o apelido fica no grupo e vale para todas as parcelas, inclusive as futuras.
- Toda mudança de apelido é registrada na auditoria.

O apelido funciona como **nome do fornecedor**. Ao dar um apelido, o sistema grava a relação descrição normalizada → apelido para o espaço. Exemplo: "DISTRIBUIDORA" passa a aparecer como "Distribuidora Amarelinha".

- Nas próximas importações, toda linha com essa descrição normalizada já chega com o apelido.
- O apelido vale também para os lançamentos antigos com a mesma descrição normalizada. Mudar o apelido muda a exibição de todos, passados e futuros. A descrição original de cada um continua intacta.

## 11. Participantes, rateio e acerto

- Três papéis numa compra: **pagador** (titular da conta; nulo = conta conjunta), **comprador** (`responsavelId`) e **consumidor** (rateio; sem rateio = 100% do responsável).
- Rateio na tela em **reais ou percentual**; título grava centavos e o modo; histórico grava só percentual (4 casas, diferença para o responsável). Desconto aplicado proporcionalmente.
- Saldo entre participantes = o que cada um pagou pelo consumo do outro, menos o que o outro pagou pelo seu, menos acertos.
- **Acerto é um título a receber** (categoria de sistema "Acerto entre participantes", fora dos relatórios de gasto), **gerado manualmente** pelo botão no relatório. Pagamento por baixa; parcial vira pendente.

## 12. Parcelamento

- `GrupoParcelamento` + títulos com `numeroParcela`. Todas as parcelas criadas de uma vez. O mesmo grupo atende a recorrência e o salário (seção 13).
- Parcelamento de título (IPVA, carnê) e parcelamento no cartão (cada parcela em uma fatura).
- No cartão, a parcela atual é baixada; as demais ficam abertas e realizadas para limite e fatura.
- Importação de "LOJA 02/10" baixa a parcela existente sem nova revisão.
- Arredondamento na primeira parcela. Rateio, categoria e responsável ficam em cada parcela; alteração no grupo propaga para parcelas abertas não editadas manualmente.
- Cada parcela entra nos relatórios no mês de vencimento da sua fatura.

## 13. Recorrência e salário

A recorrência é um **parcelamento com repetição**. Ao cadastrar, o usuário informa **obrigatoriamente a quantidade de vezes** e o sistema gera **a lista completa na hora**. Não existe geração diária, agendador nem horizonte configurável.

- Usa o mesmo grupo do parcelamento, com o tipo `INSTALLMENT`, `RECURRING` ou `SALARY`, frequência (semanal, mensal, anual), intervalo, dia de vencimento (dia 31 vira último dia) e ajuste de dia útil (manter, antecipar, postergar).
- Teto de 120 ocorrências por série.
- Valor variável: todas as ocorrências nascem com o valor estimado e marcadas como estimadas; o usuário corrige cada uma quando o valor real chega. Não há ajuste automático pelo último valor pago.
- No cartão, gera os títulos **previstos** ligados às faturas futuras (criadas como FUTURA); a importação baixa o título e ajusta o valor real.
- Editar a série afeta só títulos abertos não editados manualmente; encerrar exclui os abertos futuros.
- **Estender** é uma ação manual que gera mais ocorrências a partir da última.
- **Rotina de salário**: cada participante cadastra o seu (valor, dia, conta, quantidade de vezes). É uma série a receber do tipo `SALARY`.

## 14. Datas e navegação

- **Todos os relatórios usam o mês de vencimento**, inclusive o vencimento da fatura para compras no cartão.
- Títulos atrasados aparecem no fluxo de caixa na data de hoje, destacados.
- Na fatura, a tela abre na próxima fatura a vencer em aberto (após o fechamento do cartão, mostra a do mês seguinte).
- Em títulos e relatórios, vale o dia de fechamento do espaço (padrão 5): até o dia 5 inclusive, mostra o mês atual; depois, o seguinte. Sempre é possível navegar para meses anteriores e futuros.

## 15. Relatórios

1. **Fluxo de caixa**: realizado e previsto, saldo projetado das contas (corrente, poupança, carteira). Cartão entra pela fatura no vencimento.
2. **Gastos por categoria**: mês selecionado, subcategorias, detalhe ao clicar. Sem comparativo de meses.
3. **Gastos por participante**: consumo de cada pessoa respeitando o rateio.
4. **Relatório entre participantes** (acerto): período do dia de fechamento anterior ao atual, consultável a qualquer momento, sem bloqueio de edição. Lado a receber/a pagar definido por pagador x consumidor (contas conjuntas ficam fora). Cada fatura é um bloco com o total, a parte do outro e as compras. Fecha com: **período atual**, **pendente de períodos anteriores** e **total geral**.
5. **Meus gastos** (padrão: mês seguinte), só a minha parte:
   - Nível 1: salário − minha parte da fatura realizada (com parcelas, inclusive no cartão de outros) − minha parte dos títulos a pagar.
   - Nível 2: − minha parte do previsto no cartão.
   - Nível 3: + outros recebimentos previstos.
6. **Visão total** (dinheiro real nas minhas contas):
   - Nível 1: fatura inteira dos meus cartões (minha parte e parte de cada participante separadas) − títulos que pago + salário + a receber dos participantes.
   - Nível 2: − previsto inteiro dos meus cartões + parte prevista dos outros como a receber.
   - Nível 3: + outros recebimentos previstos.
   - Os dois relatórios fecham no mesmo resultado.

Removido: relatório de previsto x realizado.

## 16. Modelo de dados (SQL — Supabase/PostgreSQL)

> **Histórico.** O SQL abaixo é a versão original, em português, e **não é mais mantido**. O modelo vigente, com nomes em inglês, está em [`backend/prisma/schema.prisma`](../backend/prisma/schema.prisma) e nas migrations SQL ao lado dele. Mudanças desde esta versão: recorrência virou parcelamento com repetição (a tabela `regra_recorrencia` deixou de existir), `horizonte_recorrencia_meses` saiu, e o espaço ganhou `timezone` e `currency`.

Script para o SQL Editor do Supabase. Valores em centavos (`integer`), nomes em snake\_case. O login usa o `auth.users` do Supabase; a tabela `perfil` guarda os dados do usuário. Ainda não foi executado: rode primeiro num projeto de teste.

```sql
-- ===== Tipos =====
create type papel_membro as enum ('DONO','EDITOR','COLABORADOR','LEITOR');
create type status_convite as enum ('PENDENTE','ACEITO','EXPIRADO','CANCELADO');
create type tipo_conta as enum ('CORRENTE','POUPANCA','CARTEIRA','INVESTIMENTO','CARTAO_CREDITO');
create type tipo_cartao_fisico as enum ('TITULAR','ADICIONAL','VIRTUAL');
create type tipo_categoria as enum ('RECEITA','DESPESA');
create type categoria_sistema as enum ('JUROS_MULTA_PAGOS','JUROS_MULTA_RECEBIDOS','ACERTO');
create type natureza as enum ('PAGAR','RECEBER');
create type status_titulo as enum ('ABERTO','PARCIAL','QUITADO','CANCELADO');
create type modo_rateio as enum ('REAIS','PERCENTUAL');
create type motivo_baixa as enum ('PAGAMENTO','PERDA','ABATIMENTO');
create type direcao as enum ('ENTRADA','SAIDA');
create type origem_movimento as enum ('BAIXA','TRANSFERENCIA','AJUSTE','SALDO_INICIAL','ESTORNO');
create type status_fatura as enum ('FUTURA','ABERTA','FECHADA','PAGA','PAGA_PARCIAL');
create type frequencia as enum ('SEMANAL','MENSAL','ANUAL');
create type ajuste_dia_util as enum ('MANTER','ANTECIPAR','POSTERGAR');
create type tipo_recorrencia as enum ('COMUM','SALARIO');
create type formato_importacao as enum ('OFX','CSV');
create type estrategia_chave as enum ('FITID','HASH_OCORRENCIA');
create type status_linha as enum ('PENDENTE','CONCILIADA','IGNORADA','AUSENTE');
create type condicao_regra as enum ('CONTEM','COMECA_COM','IGUAL');
create type status_solicitacao as enum ('PENDENTE','APROVADA','RECUSADA','CANCELADA');
create type origem_auditoria as enum ('USUARIO','SISTEMA','IMPORTACAO');

-- ===== Usuários, espaço e participantes =====
create table perfil (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text not null,
  criado_em timestamptz not null default now()
);

create table espaco (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  dia_fechamento int not null default 5 check (dia_fechamento between 1 and 28),
  horizonte_recorrencia_meses int not null default 6 check (horizonte_recorrencia_meses between 1 and 24),
  notificar_email boolean not null default true,
  criado_em timestamptz not null default now()
);

create table membro (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  usuario_id uuid not null references perfil(id),
  papel papel_membro not null,
  criado_em timestamptz not null default now(),
  unique (espaco_id, usuario_id)
);

create table participante (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  nome text not null,
  usuario_id uuid references perfil(id),
  ativo boolean not null default true,
  unique (espaco_id, usuario_id)
);

create table convite (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  email text not null,
  papel papel_membro not null,
  participante_id uuid references participante(id),
  codigo text not null unique,
  status status_convite not null default 'PENDENTE',
  convidado_por_id uuid not null references perfil(id),
  expira_em timestamptz not null,
  criado_em timestamptz not null default now()
);

create table compartilhamento_visao (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  de_usuario_id uuid not null references perfil(id),
  para_usuario_id uuid not null references perfil(id),
  criado_em timestamptz not null default now(),
  unique (espaco_id, de_usuario_id, para_usuario_id)
);

-- ===== Cadastros =====
create table conta (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  nome text not null,
  tipo tipo_conta not null,
  instituicao text,
  titular_id uuid references participante(id), -- nulo = conta conjunta
  saldo_atual int not null default 0,
  limite int check (limite >= 0),
  dia_fechamento int check (dia_fechamento between 1 and 31),
  dia_vencimento int check (dia_vencimento between 1 and 31),
  cor text,
  icone text,
  ativa boolean not null default true,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

create table cartao_fisico (
  id uuid primary key default gen_random_uuid(),
  conta_id uuid not null references conta(id) on delete cascade,
  participante_id uuid not null references participante(id),
  final_cartao char(4) not null,
  apelido text,
  tipo tipo_cartao_fisico not null,
  ativo boolean not null default true
);

create table categoria (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  nome text not null,
  tipo tipo_categoria not null,
  pai_id uuid references categoria(id),
  sistema categoria_sistema,
  cor text,
  icone text,
  arquivada boolean not null default false
);

create table centro_custo (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  nome text not null,
  descricao text,
  data_inicio date,
  data_fim date,
  ativo boolean not null default true
);

-- ===== Fatura, parcelamento, recorrência =====
create table fatura (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  conta_id uuid not null references conta(id),
  mes_referencia char(7) not null, -- AAAA-MM
  data_fechamento date not null,
  data_vencimento date not null,
  saldo_anterior int not null default 0,
  valor_total int not null default 0,    -- realizado
  valor_previsto int not null default 0, -- recorrências previstas
  valor_pago int not null default 0,
  status status_fatura not null,
  unique (conta_id, mes_referencia)
);

create table grupo_parcelamento (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  descricao text not null,
  descricao_normalizada text not null,
  valor_total int not null check (valor_total > 0),
  quantidade_parcelas int not null check (quantidade_parcelas > 0),
  parcela_inicial int not null default 1,
  data_compra date not null,
  conta_prevista_id uuid references conta(id),
  criado_por_id uuid not null references perfil(id),
  criado_em timestamptz not null default now(),
  excluido_em timestamptz,
  check (parcela_inicial between 1 and quantidade_parcelas)
);
create index on grupo_parcelamento (espaco_id, descricao_normalizada);

create table regra_recorrencia (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  tipo tipo_recorrencia not null default 'COMUM',
  natureza natureza not null,
  descricao text not null,
  valor int not null check (valor > 0),
  valor_variavel boolean not null default false,
  categoria_id uuid references categoria(id),
  centro_custo_id uuid references centro_custo(id),
  responsavel_id uuid not null references participante(id),
  rateio jsonb, -- [{participante_id, percentual}]
  conta_prevista_id uuid references conta(id),
  frequencia frequencia not null,
  intervalo int not null default 1 check (intervalo > 0),
  dia_vencimento int not null check (dia_vencimento between 1 and 31),
  ajuste_dia_util ajuste_dia_util not null default 'MANTER',
  data_inicio date not null,
  data_fim date,
  gerado_ate date,
  ativa boolean not null default true
);

-- ===== Título, rateio, baixa =====
create table titulo (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  natureza natureza not null,
  descricao text not null,
  valor_original int not null check (valor_original > 0),
  valor_previsto int,
  estimado boolean not null default false,
  saldo int not null check (saldo >= 0),
  total_desconto int not null default 0,
  status status_titulo not null default 'ABERTO',
  data_competencia date not null,
  data_vencimento date not null,
  categoria_id uuid references categoria(id),
  centro_custo_id uuid references centro_custo(id),
  responsavel_id uuid not null references participante(id),
  modo_rateio modo_rateio,
  conta_prevista_id uuid references conta(id),
  fatura_id uuid references fatura(id),
  grupo_parcelamento_id uuid references grupo_parcelamento(id),
  numero_parcela int,
  regra_recorrencia_id uuid references regra_recorrencia(id),
  editado_manualmente boolean not null default false,
  observacao text,
  criado_por_id uuid not null references perfil(id),
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  excluido_em timestamptz,
  unique (grupo_parcelamento_id, numero_parcela)
);
create index on titulo (espaco_id, data_vencimento);
create index on titulo (fatura_id);

create table titulo_rateio (
  id uuid primary key default gen_random_uuid(),
  titulo_id uuid not null references titulo(id) on delete cascade,
  participante_id uuid not null references participante(id),
  valor int not null check (valor >= 0),
  percentual numeric(7,4) not null,
  unique (titulo_id, participante_id)
);

create table baixa (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  titulo_id uuid not null references titulo(id),
  motivo motivo_baixa not null,
  data date not null,
  valor_amortizado int not null check (valor_amortizado > 0),
  juros int not null default 0 check (juros >= 0),
  multa int not null default 0 check (multa >= 0),
  desconto int not null default 0 check (desconto >= 0),
  valor_movimentado int not null,
  observacao text,
  criado_por_id uuid not null references perfil(id),
  estornada_em timestamptz,
  estorno_motivo text,
  criado_em timestamptz not null default now(),
  check (valor_movimentado = valor_amortizado + juros + multa - desconto)
);

-- ===== Movimento e conciliação =====
create table conciliacao (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  conta_id uuid not null references conta(id),
  conciliado_por_id uuid not null references perfil(id),
  criado_em timestamptz not null default now()
);

create table movimento_conta (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  conta_id uuid not null references conta(id),
  data date not null,
  direcao direcao not null,
  valor int not null check (valor > 0),
  origem origem_movimento not null,
  baixa_id uuid unique references baixa(id),
  transferencia_id uuid,
  movimento_estornado_id uuid references movimento_conta(id),
  fatura_id uuid references fatura(id),
  cartao_fisico_id uuid references cartao_fisico(id),
  conciliacao_id uuid references conciliacao(id),
  descricao text not null,
  criado_por_id uuid not null references perfil(id),
  criado_em timestamptz not null default now()
);
create index on movimento_conta (conta_id, data);

create table layout_importacao (
  id uuid primary key default gen_random_uuid(),
  banco text not null,
  formato formato_importacao not null,
  estrategia_chave estrategia_chave not null,
  mapeamento jsonb not null,
  padrao_parcela text
);

create table importacao_extrato (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  conta_id uuid not null references conta(id),
  layout_id uuid references layout_importacao(id),
  formato formato_importacao not null,
  nome_arquivo text not null,
  hash_arquivo text not null,
  periodo_inicio date not null,
  periodo_fim date not null,
  saldo_informado int,
  limite_informado int,
  importado_por_id uuid not null references perfil(id),
  criado_em timestamptz not null default now()
);

create table linha_extrato (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  conta_id uuid not null references conta(id),
  importacao_id uuid not null references importacao_extrato(id),
  ultima_importacao_id uuid not null references importacao_extrato(id),
  id_externo text not null,
  data date not null,
  direcao direcao not null,
  valor int not null check (valor > 0),
  descricao text not null,
  descricao_normalizada text not null,
  final_cartao char(4),
  status status_linha not null default 'PENDENTE',
  conciliacao_id uuid references conciliacao(id),
  unique (conta_id, id_externo)
);

-- ===== Sugestões =====
create table regra_categorizacao (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  conta_id uuid references conta(id),
  condicao condicao_regra not null,
  texto text not null,
  direcao direcao,
  valor_min int,
  valor_max int,
  categoria_id uuid not null references categoria(id),
  centro_custo_id uuid references centro_custo(id),
  responsavel_id uuid references participante(id),
  prioridade int not null default 100,
  ativa boolean not null default true,
  vezes_aplicada int not null default 0
);

create table historico_sugestao (
  espaco_id uuid not null references espaco(id) on delete cascade,
  descricao_normalizada text not null,
  categoria_id uuid references categoria(id),
  responsavel_id uuid references participante(id),
  modo_rateio modo_rateio,
  rateio jsonb, -- percentuais
  contagem int not null default 1,
  ultimo_uso timestamptz not null default now(),
  primary key (espaco_id, descricao_normalizada)
);

-- ===== Colaboração e auditoria =====
create table solicitacao_alteracao (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  titulo_id uuid not null references titulo(id),
  solicitante_id uuid not null references perfil(id),
  alteracao_proposta jsonb not null,
  mensagem text,
  status status_solicitacao not null default 'PENDENTE',
  resolvido_por_id uuid references perfil(id),
  resolvido_em timestamptz,
  resposta text,
  criado_em timestamptz not null default now()
);

create table notificacao (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id) on delete cascade,
  usuario_id uuid not null references perfil(id),
  tipo text not null,
  referencia uuid,
  mensagem text not null,
  lida_em timestamptz,
  criado_em timestamptz not null default now()
);

create table auditoria (
  id uuid primary key default gen_random_uuid(),
  espaco_id uuid not null references espaco(id),
  entidade text not null,
  entidade_id uuid not null,
  acao text not null,
  alteracoes jsonb not null,
  usuario_id uuid references perfil(id),
  origem origem_auditoria not null,
  correlacao_id uuid not null,
  criado_em timestamptz not null default now()
);
create index on auditoria (entidade, entidade_id);
create index on auditoria (correlacao_id);
revoke update, delete on auditoria from authenticated, anon;

-- ===== Segurança por linha (RLS) — exemplo =====
alter table titulo enable row level security;

create or replace function eh_membro(p_espaco uuid) returns boolean
language sql stable security definer as $$
  select exists (select 1 from membro
                 where espaco_id = p_espaco and usuario_id = auth.uid());
$$;

-- Vê o que lançou, onde é responsável/rateado, ou de quem liberou a visão
create policy titulo_select on titulo for select using (
  eh_membro(espaco_id) and (
    criado_por_id = auth.uid()
    or exists (select 1 from participante p
               where p.id = titulo.responsavel_id and p.usuario_id = auth.uid())
    or exists (select 1 from titulo_rateio r join participante p on p.id = r.participante_id
               where r.titulo_id = titulo.id and p.usuario_id = auth.uid())
    or exists (select 1 from compartilhamento_visao c
               where c.espaco_id = titulo.espaco_id
                 and c.de_usuario_id = titulo.criado_por_id
                 and c.para_usuario_id = auth.uid())
  )
);
```

Observações:

- As políticas RLS valem quando o front acessa o Supabase direto. Se tudo passar pelo backend Fastify com a chave de serviço, o RLS é ignorado e as regras de visão ficam no backend.
- As demais tabelas seguem o mesmo padrão: `enable row level security` + política com `eh_membro(espaco_id)`.

Alteração: apelido dos lançamentos (rodar depois do script principal).

```sql
alter table titulo rename column descricao to descricao_original;
alter table titulo add column apelido text;
alter table grupo_parcelamento add column apelido text;

-- Texto exibido: apelido do grupo > apelido do título > descrição original
create or replace view vw_titulo_exibicao as
select t.id,
       coalesce(g.apelido, t.apelido, t.descricao_original) as descricao_exibida,
       t.descricao_original
from titulo t
left join grupo_parcelamento g on g.id = t.grupo_parcelamento_id;
```

```sql
-- Apelido por fornecedor: aplicado automaticamente nas importações
create table apelido_descricao (
  espaco_id uuid not null references espaco(id) on delete cascade,
  descricao_normalizada text not null,
  apelido text not null,
  criado_por_id uuid not null references perfil(id),
  atualizado_em timestamptz not null default now(),
  primary key (espaco_id, descricao_normalizada)
);
```

## 17. Views e regras fora do schema

- `vw_gasto_participante`: consumo por participante (rateio ou 100% do responsável, desconto proporcional).
- `vw_contas_a_pagar`: títulos abertos fora de cartão + faturas não pagas (valor = saldo anterior + total + previsto − pago).
- Constraints via migration SQL: valores positivos, `parcelaInicial ≤ numeroParcela ≤ quantidadeParcelas`, auditoria somente inserção.
- Previsto no cartão = título aberto de uma série `RECURRING` com `faturaId`; parcelas são sempre realizadas.

## 18. Pendências para o futuro

- Tabela de feriados para ajuste de dia útil.
- Antecipação de parcelas com desconto (modelável como baixa com desconto).
- Open Finance e leitura de fatura em PDF.
- Geração automática de acerto no dia de fechamento.
- Bloqueio de períodos fechados.
