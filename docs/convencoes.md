# Convenções e padrões do projeto

Regras que valem para todo o código do Peculium. Ponto de partida: [decisões e modelo de dados](decisoes-e-modelo-de-dados.md), que descreve o negócio em português. Este documento define **como o código é escrito**.

## Decisões tomadas

| # | Tema | Decisão |
| --- | --- | --- |
| 1 | ORM | Prisma, com Supabase pelo session pooler |
| 2 | Estrutura | Monorepo com `backend`, `frontend` e `shared` |
| 3 | Datas e fuso | Instantes em UTC convertidos na exibição; datas puras sem conversão; "hoje" no servidor pelo fuso do espaço (`space.timezone`); biblioteca `date-fns` + `date-fns-tz` |
| 4 | API | Erro com código estável e paginação por cursor |
| 5 | Frontend | TanStack Query, React Hook Form + Zod, Tailwind CSS |
| 6 | Testes | Vitest em todos os pacotes |
| 7 | Idioma | **Todo o código em inglês**; documentação em português; interface traduzida (pt-BR e en) |
| 8 | Interface | Tailwind como padrão, componentes prontos do shadcn/ui, ícones Phosphor sempre que possível |
| 9 | Testes | Testes no backend **e** no frontend, com PostgreSQL real nas operações de gravação |
| 10 | Qualidade | Clean code e padrões de projeto aplicados só onde resolvem um problema real |
| 11 | Tradução | `pt-BR` e `en`, catálogos em `shared/locales`, erro traduzido por `Accept-Language` |
| 12 | Moeda | Uma moeda por espaço (`space.currency`), valores em `bigint` na unidade menor da moeda, sem câmbio |
| 13 | Commits | Padrão do Meu Vestir (tipo, escopo, emoji) com o assunto em inglês e português |
| 14 | Recorrência | É um parcelamento com repetição: quantidade obrigatória e lista completa gerada no cadastro. Sem agendador. Tabela única `installment_plan` com `kind`. |
| 15 | Backend dormindo | Render gratuito dorme; o front trata a primeira resposta lenta |
| 16 | Sistema de design | Índigo como única cor de destaque, neutros azul-marinho sem branco nem preto puros, OKLCH dentro do sRGB, Inter, cantos de 8 px. Atrasado e negativo em vermelho, a pagar em laranja escuro, a receber em azul-céu, resultado positivo em verde. Ver [sistema de design](design-system.md) |
| 17 | Autenticação | Supabase Auth; a API valida o JWT e relê papel e permissões do banco a cada requisição |
| 18 | Monorepo | pnpm 11 + Turborepo, como no `controle-financeiro` |
| 19 | Lint e formatação | Biome (lint e formatação em uma ferramenta só) |
| 20 | Camadas da API | `routes` → `controller` → `service` → `repository`, sempre |
| 21 | Mobile first | Mobile first, responsivo e acessível (WCAG 2.2 AA), com teste automático de acessibilidade |
| 22 | Hospedagem do backend | Render gratuito para começar (dorme após 15 minutos parado), plano pago quando houver uso real |
| 23 | E-mail | Resend (plano gratuito: 100 por dia e 3.000 por mês), para convites, avisos e SMTP do Supabase Auth |
| 24 | Validação nas rotas | `fastify-type-provider-zod`, como no `controle-financeiro` |
| 25 | Hospedagem do front | Cloudflare Pages |
| 26 | Leitura de OFX | Parser próprio pequeno, atrás de um adaptador, testado com arquivos reais |
| 27 | Integração contínua | GitHub Actions, com PostgreSQL em serviço para os testes de integração |
| 28 | Licença | Nenhuma: todos os direitos reservados |

## 1. Idioma

- **Código em inglês**: tabelas, colunas, entidades, campos de API, funções, variáveis, arquivos e comentários.
- **Negócio em português**: o documento de decisões e este documento continuam em português do Brasil.
- **Interface traduzida**: todo texto exibido ao usuário, incluindo mensagens de erro, existe em português do Brasil (`pt-BR`) e em inglês (`en`), sem texto fixo no código. Ver seção 12.
- **Assunto do commit nos dois idiomas**, inglês e português, no padrão do Meu Vestir (seção 10).
- Sem acentos nem cedilha em identificadores.
- O documento de decisões usa termos em português. O [glossário](#glossário-português--inglês) abaixo define o nome de cada um no código. Termo novo entra no glossário **antes** de aparecer no código.

### Glossário português → inglês

Glossário revisado e aprovado. Os nomes do SQL do documento de decisões serão renomeados conforme esta tabela quando o schema for criado.

| Português | Inglês (código) | Observação |
| --- | --- | --- |
| espaço | `space` | A "casa"; equivale à filial no Protheus |
| usuário / perfil | `user` / `profile` | `profile` é a tabela ligada a `auth.users` |
| membro | `member` | |
| participante | `participant` | Quem gasta, com ou sem login |
| convite | `invitation` | |
| conta | `account` | Corrente, poupança, carteira, investimento, cartão |
| cartão físico | `physical_card` | |
| categoria | `category` | No máximo 2 níveis |
| centro de custo | `cost_center` | |
| título | `bill` | Conta a pagar ou a receber; `nature` = `PAYABLE` ou `RECEIVABLE` |
| natureza | `nature` | |
| baixa | `settlement` | Pagamento ou recebimento aplicado a um título |
| movimento da conta | `account_movement` | Única coisa que altera saldo |
| fatura (cartão) | `card_invoice` | |
| extrato | `statement` | `statement_import`, `statement_line` |
| conciliação | `reconciliation` | |
| parcelamento / parcela | `installment_plan` / `installment` | |
| recorrência | `installment_plan` com `kind = RECURRING` | Parcelamento com repetição; gera a lista completa ao cadastrar. Salário é `kind = SALARY`. |
| rateio | `split` | `bill_split` |
| acerto entre participantes | `reimbursement` | Título a receber gerado no relatório |
| apelido | `nickname` | `description_nickname` guarda o apelido por descrição |
| pagador / comprador / consumidor | `payer` / `buyer` / `consumer` | |
| auditoria | `audit_log` | |
| solicitação de alteração | `change_request` | |
| compartilhamento de visão | `view_share` | |
| dono, editor, colaborador, leitor | `OWNER`, `EDITOR`, `CONTRIBUTOR`, `VIEWER` | Papéis |
| vencimento / competência | `due_date` / `accrual_date` | |
| valor original / saldo | `original_amount` / `balance` | |
| juros / multa / desconto | `interest` / `penalty` / `discount` | |
| aberto, parcial, quitado, cancelado | `OPEN`, `PARTIAL`, `PAID`, `CANCELED` | Status do título |

## 2. Estrutura do repositório

Monorepo com **pnpm 11 e Turborepo**, no mesmo formato do `controle-financeiro`, com três pacotes (decisão tomada). Requer Node 22 ou mais novo. Comandos da raiz: `pnpm dev`, `build`, `lint`, `typecheck`, `test` e `format`, todos delegados ao Turborepo, que guarda cache entre pacotes. A versão do pnpm fica fixada em `packageManager` no `package.json`.

```
peculium/
  backend/    API Fastify + Prisma
  frontend/   React + Vite
  shared/     schemas Zod e tipos usados pelos dois lados
  docs/       decisões, convenções, ADRs
```

- `shared` guarda os schemas Zod de entrada e saída da API. Front e back importam do mesmo lugar, então o contrato não diverge.
- Constantes, enums e funções puras usados pelos dois lados também ficam em `shared`, por exemplo `formatCurrency` e a conversão de reais para centavos.
- Decisões novas de arquitetura entram como arquivo curto em `docs/adr/NNNN-titulo.md`.

### Acesso a dados e Supabase

- **Prisma** como ORM. É o que o documento de decisões assume com `$transaction` e `Int`.
- Conexão pelo **session pooler do Supabase (porta 5432)** em `DATABASE_URL`, que serve ao servidor Fastify e às migrations. Sem `DIRECT_URL` e sem `?pgbouncer=true`, que são para ambientes serverless.
- Usuário **`prisma` dedicado** no banco, com permissões no schema `public`. Esse usuário ignora o RLS, então as regras de visão ficam no backend.
- **Data API (PostgREST) do Supabase desligada**, já que só o backend acessa o banco.
- O que o Prisma não gera fica em **migrations SQL** escritas à mão, ao lado da migration gerada: `check` de valores, gatilhos (fuso válido, moeda travada, categoria em dois níveis), trava da auditoria, FK de `profile` para `auth.users` (só onde existe o schema `auth`), RLS ligado e a view `bill_display`.
- `backend/prisma/checks/constraints.sql` verifica essas regras num banco vazio e imprime PASS ou FAIL. Roda em PostgreSQL comum e em um que imita o Supabase.

### Serviços externos

- **Backend:** Render, no plano gratuito para começar. O servidor dorme após 15 minutos parado e a primeira resposta leva cerca de 1 minuto; o front trata isso (seção 8). Passa para o plano pago quando houver uso real, sem mudar código.
- **Front:** Cloudflare Pages, plano gratuito, sem restrição de uso comercial. Cada push gera uma prévia.
- **E-mail:** Resend, no plano gratuito (100 por dia e 3.000 por mês, sem cobrança extra: ao bater o limite o envio pausa). Envia convites e avisos do backend e serve de SMTP ao Supabase Auth. Exige domínio próprio verificado para enviar de verdade. Os limites do plano podem mudar; conferir antes de depender deles.
- **Acesso por adaptador:** Supabase Auth, Resend e qualquer serviço novo ficam atrás de uma interface do projeto (padrão Adapter, seção 11), para trocar e testar sem rede.

## 3. Nomenclatura

| Item | Padrão | Exemplo |
| --- | --- | --- |
| Arquivos TypeScript | kebab-case | `settlement-service.ts` |
| Componentes React | PascalCase, um por arquivo | `BillList.tsx` |
| Variáveis e funções | camelCase | `calculateBalance` |
| Tipos, interfaces, classes | PascalCase | `Bill`, `OperationContext` |
| Constantes | UPPER_SNAKE_CASE | `DEFAULT_CLOSING_DAY` |
| Enums (TS e SQL) | valores em UPPER_SNAKE_CASE | `PAID`, `PARTIAL` |
| Rotas HTTP | kebab-case, plural | `/bills`, `/statement-imports` |
| JSON da API | camelCase | `dueDate` |
| Tabelas e colunas SQL | snake_case, singular | `bill`, `due_date` |

- Booleanos começam com `is`, `has` ou são adjetivos claros: `active`, `estimated`, `isJoint`.
- Funções que alteram dados usam verbo de ação do domínio: `settleBill`, `reverseSettlement`, `reconcileLines`.
- Prisma mapeia camelCase para snake_case com `@map` e `@@map`.

## 4. Banco de dados

- **Chaves**: `uuid` com `gen_random_uuid()`.
- **Dinheiro**: inteiro na **unidade menor da moeda** do espaço (centavos no real, no euro e no dólar; ienes inteiros no iene), sempre positivo. O sinal vem de `nature` ou `direction`. Nunca `float`, nunca `numeric` para valor monetário. Percentual de rateio é a exceção, com `numeric(7,4)`. Tipo da coluna e moeda: ver seção 12.
- **Datas sem hora** (`due_date`, `accrual_date`): tipo `date`.
- **Instantes** (`created_at`, `reversed_at`): `timestamptz`.
- **Mês de referência**: `char(7)` no formato `YYYY-MM`.
- **Colunas padrão**: `created_at` em toda tabela; `updated_at` nas tabelas editáveis; `deleted_at` onde há soft delete.
- **Multiespaço**: toda tabela de negócio tem `space_id`, e toda consulta filtra por ele (ver seção 6).
- **Enums** como `create type ... as enum`, com valores em maiúsculas.
- **Integridade na migration**, não só na aplicação: `check` de valores positivos, chaves únicas, `initial_installment <= installment_number <= installment_count`.
- **Auditoria**: somente inserção, com `revoke update, delete`.
- **Migrations**: versionadas no repositório, nunca alterar uma migration já aplicada. Ajuste novo é migration nova.
- **Índices**: criar junto com a tabela, começando por `space_id` combinado com a data mais consultada.

## 5. Dinheiro e datas no código

- Valor monetário é `number` inteiro na unidade menor da moeda em todo o código. A conversão para a forma de exibição só acontece na borda da interface, em funções únicas de `shared` (`formatCurrency`, `toMinorUnits`), que recebem a moeda.
- Entrada de valor na tela é convertida para a unidade menor antes de ir para a API.
- Rateio em reais: a diferença de arredondamento fica no responsável (e na primeira parcela, no parcelamento), como definido no documento de decisões.
- **Instantes** (`created_at`, `reversed_at`) são gravados em UTC e trafegam em ISO 8601 UTC. A interface converte para o horário local de quem está vendo, usando `date-fns` e `date-fns-tz`.
- **Datas sem hora** (`due_date`, `accrual_date`, `date` da baixa) trafegam como texto `YYYY-MM-DD` e **nunca são convertidas de fuso**. Converter uma data pura como se fosse um instante desloca o dia.
- **"Hoje" no servidor** (atraso, dia de fechamento, datas das ocorrências geradas) usa o **fuso do espaço**, na coluna `space.timezone`, com o nome IANA (`America/Cuiaba`, `Europe/Lisbon`). O servidor roda em UTC, então sem esse fuso um título que vence hoje apareceria atrasado à noite, e uma família em outro país teria o "hoje" calculado no horário errado.
  - A coluna nasce preenchida com o fuso do navegador de quem cria o espaço e pode ser alterada nas configurações, só pelo dono.
  - O valor é validado contra a lista de nomes IANA. Nunca se guarda deslocamento fixo (`-04:00`), porque ele não acompanha horário de verão.
  - Toda regra que depende do dia (atraso, recorrência, fechamento) recebe o fuso do espaço por parâmetro, nunca lê um fuso global.
  - Padrão quando o navegador não informar o fuso: `America/Sao_Paulo`.
- Cálculos de data (fechamento, dia útil, último dia do mês) ficam em um módulo próprio e testado. Nada de `new Date()` espalhado.

## 6. Backend

### Camadas

```
routes -> controller -> service -> repository
```

Mesmas camadas do `controle-financeiro` (decisão tomada).

- **Routes** declaram o endpoint e validam entrada e saída com os schemas Zod de `shared`. Sem regra de negócio.
- **Controllers** traduzem HTTP: leem a requisição, chamam um service e montam a resposta e o código de status. O service não conhece HTTP.
- **Services** concentram a regra de negócio e recebem o cliente transacional, nunca o cliente global.
- **Repositories** são os únicos que conhecem o Prisma. Toda consulta e gravação passa por eles, o que deixa o service testável sem banco.
- **Regras puras** (cálculo de saldo, rateio, recorrência, sugestão) viram funções sem acesso a banco, para testar sem infraestrutura.

### Operações e auditoria

- Toda operação que grava passa por um único ponto de entrada, `runOperation(context, action, fn)`, dentro de uma transação.
- A auditoria é gravada ali, na mesma transação. Uma linha por operação, com `correlationId` agrupando as linhas da mesma ação.
- Campos derivados (saldo, totais) não entram na auditoria.
- Toda operação auditada tem um teste de integração.

### Espaço, papel e visibilidade

- O `spaceId` vem do **contexto autenticado**, nunca do corpo da requisição.
- Papel define o que a pessoa pode fazer; privacidade define o que ela vê. As duas checagens são independentes e ficam em módulos separados.
- Consulta que lista ou busca dados passa pelo filtro de visibilidade. Ninguém edita o que não vê.

### Importação de extrato

- **OFX:** parser próprio e pequeno, atrás de um adaptador (`StatementReader`), que lê a versão 1 (SGML) e a 2 (XML). Fica coberto por testes com **arquivos reais de bancos, anonimizados**, porque as variações entre bancos é onde um parser quebra. Biblioteca de npm não foi adotada por estar pouco mantida.
- **CSV:** layouts por banco, partindo do que o `controle-financeiro` já tem em `Docs/importacao-csv.md`.
- Os dois formatos entregam as mesmas `statement_line` ao resto do sistema, e o layout escolhe a chave de idempotência (`FITID` ou hash da ocorrência).

### Validação e erros

- Entrada e saída validadas com Zod, usando os schemas de `shared`, ligados às rotas pelo `fastify-type-provider-zod` (como no `controle-financeiro`). A versão do provider acompanha a do Zod; conferir a compatibilidade ao instalar.
- O código da API é organizado por funcionalidade: `modules/<funcionalidade>/` com `routes`, `controller`, `service` e `repository` lado a lado (por exemplo `modules/bills/`).
- Erros de negócio usam classes próprias (`BusinessError`, `NotFoundError`, `PermissionError`) com código estável. Um handler único converte em resposta HTTP.
- Formato de erro da API:

```json
{ "error": { "code": "SETTLEMENT_EXCEEDS_BALANCE", "message": "O valor amortizado não pode ser maior que o saldo." } }
```

- O `code` é em inglês e estável; o front decide o comportamento por ele.
- A `message` vem no idioma pedido pelo cabeçalho `Accept-Language` (`pt-BR` ou `en`) e pode mudar sem aviso. O exemplo acima é a resposta em `pt-BR`.

## 7. API

- REST sobre JSON, prefixo `/api/v1`.
- Recursos no plural, em inglês: `/bills`, `/bills/:id/settlements`, `/accounts`, `/card-invoices`.
- Verbos HTTP: `GET` lê, `POST` cria, `PATCH` altera parcialmente, `DELETE` faz soft delete. Ação de domínio que não é CRUD vira sub-rota: `POST /settlements/:id/reversal`.
- Listagens com **paginação por cursor** e filtros por query string. Todo filtro de período usa `dueDate`, alinhado à regra de relatórios.
- Autenticação por token do Supabase Auth no cabeçalho `Authorization`.

## 8. Frontend

- React com TypeScript em modo estrito, Vite.
- Estrutura por funcionalidade:

```
frontend/src/
  features/
    bills/          componentes, hooks e chamadas da funcionalidade
    card-invoices/
    statement-import/
  shared/           componentes, hooks e utilitários usados por várias funcionalidades
```

- **TanStack Query** para dados do servidor: cache, recarga e invalidação depois de gravar (baixar um título atualiza lista, saldo e fatura).
- **React Hook Form** para formulários, validando com os schemas Zod de `shared`.
- **Tailwind CSS** é a preferência para todo estilo. Sem CSS avulso nem CSS Modules, a não ser que o Tailwind não resolva.
- **shadcn/ui** para componentes prontos (botão, diálogo, tabela, formulário, seletor de data). Os componentes são copiados para `shared/ui` pelo CLI e passam a ser código do projeto, então podem ser ajustados. Antes de criar um componente de interface, verificar se o shadcn/ui já tem.
- **Phosphor Icons** (`@phosphor-icons/react`) para todos os ícones sempre que houver equivalente. Ao adicionar um componente do shadcn/ui, trocar os ícones que vêm de outra biblioteca pelo equivalente Phosphor. Um peso (`regular`, `bold`, `fill`) por contexto, definido em um único lugar.
- Classes condicionais com `cn()` (o utilitário que o shadcn/ui instala). Valores repetidos de design (cores, espaçamento, raio) vêm dos tokens do Tailwind, nunca de valores soltos.
- **O backend pode estar dormindo.** O plano gratuito do Render adormece o servidor após 15 minutos parado, e a primeira resposta pode levar cerca de 1 minuto. O front está preparado para isso:
  - Ao abrir o app, dispara uma chamada leve de aquecimento (`GET /health`) antes de qualquer outra.
  - Primeira chamada com limite de tempo de pelo menos 60 segundos e nova tentativa automática com espera crescente.
  - Mostra um estado de carregamento próprio ("acordando o servidor"), nunca uma tela de erro por lentidão.
  - Só trata como falha de verdade depois de esgotar as tentativas, e então oferece "tentar de novo".
- Nenhuma regra de negócio no front: ele exibe e envia. Cálculos que o servidor já faz não são refeitos na tela.

### Mobile first, responsivo e acessível

Valem para toda tela nova (decisão tomada; parte vem do `controle-financeiro`).

**Mobile first**

- O CSS parte da largura de celular. Os breakpoints do Tailwind (`sm:`, `md:`, `lg:`) só **acrescentam**; nunca desfazem um layout de desktop escrito antes.
- **`flex` por padrão**, com `gap` em vez de margens soltas. `grid` só quando linhas **e** colunas precisam se alinhar entre si (tabela de fatura no desktop, formulário de duas colunas).
- Nada de `float`, de `position: absolute` para posicionar conteúdo de fluxo nem de largura fixa em pixel.
- **Navegação:** barra inferior no celular e lateral a partir de `md:`.
- **Listas:** viram cartões abaixo de `md:` e tabela a partir dele (`DataList`).
- **Painéis:** sobem de baixo no celular (sheet) e viram diálogo no desktop (`Panel`).
- **Alvo de toque de no mínimo 44 px**, inclusive nos botões pequenos, que são compactos na aparência e não no alvo.
- **Campo de texto com no mínimo 16 px**, para o iOS não dar zoom ao focar.
- **Altura da janela com `dvh`** e margem segura do iPhone (`env(safe-area-inset-bottom)`) na barra inferior.
- **Todo elemento clicável tem estado de hover no computador**, sem exceção: botões, links, linhas e cartões clicáveis, itens de menu, abas e ícones de ação. O hover muda fundo, borda ou sublinhado de forma perceptível, com transição curta, e vem sempre junto de `cursor: pointer`, foco visível e estado de clique (`active`). A variante `hover:` do Tailwind v4 só vale em aparelhos que suportam hover (confirmar na versão instalada), então o toque no celular não deixa um hover preso.
- **Nenhuma função depende de hover.** O hover é só retorno visual: tudo que aparece ao passar o mouse também aparece ao tocar ou focar.

**Responsivo**

- Sem rolagem horizontal a partir de 320 px de largura, e o conteúdo continua utilizável com zoom de 200%.
- Larguras de referência para teste: 320, 375, 768, 1024 e 1440 px.
- Tabelas largas viram cartões no celular; só dados realmente tabulares ganham rolagem horizontal, e com indicação visível.
- Imagens e gráficos escalam com o contêiner.

**Acessível (WCAG 2.2, nível AA)**

- **HTML semântico** antes de `div` com `role`: `button`, `nav`, `main`, `table`, títulos em ordem. Os componentes do shadcn/ui (Radix) já trazem a semântica e o foco corretos; não trocá-los por `div` clicável.
- **Teclado completo:** toda ação funciona só com teclado, a ordem de tabulação segue a leitura, o foco é sempre visível e diálogos prendem o foco e devolvem ao elemento de origem.
- **Formulários:** todo campo tem rótulo visível ligado a ele. O erro aparece junto do campo, ligado por `aria-describedby`, e é anunciado ao leitor de tela. Não depende só de cor.
- **Cor nunca anda sozinha:** todo estado leva rótulo ou ícone e todo valor leva sinal. O leitor de tela fala o sinal e o estado ("menos R$ 340,00", "atrasado"), por isso o `Money` e o `BillStatusBadge` trazem texto oculto para leitor de tela.
- **Contraste** de 4,5:1 no texto e 3:1 nos controles, já garantido pelo teste do tema.
- **Ícones:** decorativos com `aria-hidden`; botão só com ícone com `aria-label` traduzido.
- **Idioma:** o atributo `lang` do `<html>` acompanha o idioma ativo (`pt-BR` ou `en`).
- **Movimento:** respeita `prefers-reduced-motion`.
- **Tabelas de dados** com `th` e `scope`, e legenda quando houver mais de uma na tela.
- **Atalhos:** link "pular para o conteúdo" no início da página.

**Como se verifica**

- O grupo de regras `a11y` do Biome roda no lint e falha o build.
- Testes de componente rodam `vitest-axe` e falham com violação.
- Os fluxos críticos do Playwright rodam `@axe-core/playwright` em projeto de celular e de desktop.
- Antes de publicar uma tela nova: percorrer com o teclado e conferir uma vez com leitor de tela.

## 9. Testes

- **Vitest** em `backend`, `frontend` e `shared`. Todo código novo nasce com teste, nos dois lados.

### Backend

- Regras puras (saldo, rateio, recorrência, sugestão): teste unitário, sem banco.
- Operações que gravam: teste de integração contra PostgreSQL real (container local), nunca com banco simulado.
- Rotas: teste de ponta a ponta da requisição com o `inject` do Fastify, cobrindo validação, permissão e formato de erro.
- Cobrir sempre: permissão por papel, visibilidade, filtro por espaço, auditoria e transação (falha no meio desfaz tudo).

### Frontend

- **React Testing Library** com `user-event`: testar o que o usuário vê e faz (digitar, clicar, ler o resultado), não detalhes internos do componente.
- **MSW** para simular a API nos testes de tela, usando os schemas de `shared` para montar as respostas.
- Cobrir sempre: formulários (validação e envio), estados de carregamento, erro e lista vazia, e regras de exibição (apelido em destaque, valor formatado, atraso destacado).
- Consultar elementos por papel e rótulo acessível (`getByRole`, `getByLabelText`), o que também mantém a interface acessível.
- **Playwright** para os fluxos críticos de ponta a ponta (cadastro, lançar e baixar um título, importar e conciliar), a partir do momento em que o fluxo existir de verdade.

### Para todos

- Teste com nome que descreve o comportamento (`it('rejects a settlement greater than the balance')`), estrutura organizar–agir–verificar e um assunto por teste.
- Bug corrigido ganha um teste que reproduz o erro antes da correção.
- Teste não depende de ordem de execução nem de data real: o relógio é injetado.
- O CI roda todos os testes; pull request com teste falhando não entra.

## 10. Git e qualidade

- Branch `main` protegida, trabalho em `feat/…`, `fix/…`, `docs/…`, `chore/…`.
- **Commits no padrão do Meu Vestir**: Conventional Commits com escopo, emoji (base [gitmoji](https://gitmoji.dev/)) e número da issue quando houver.
  - Formato: `tipo(escopo): emoji assunto em inglês | assunto em português`
  - Exemplo: `feat(bills): ✨ add partial settlement | adiciona baixa parcial`
  - Com issue: `fix(accounts): 🐛 fix balance after reversal | corrige saldo após estorno (#12)`
  - O separador entre os idiomas é ` | `. O inglês vem primeiro.
  - Assunto com até 100 caracteres no total (o limite sobe porque leva os dois idiomas). Corpo opcional, em português ou inglês, para explicar o porquê.
  - Tipos: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`.
  - Emojis: `✨` funcionalidade, `🐛` correção, `✅` testes, `💄` visual, `🔒️` segurança, `🔧` configuração, `📝` documentação, `♻️` refatoração, `⚡️` desempenho, `⬆️` dependências.
  - Escopo em inglês e em minúsculas, igual ao termo do glossário: `bills`, `settlements`, `accounts`, `card-invoices`, `statements`, `auth`, `i18n`, `db`.
- Pull request pequeno, com descrição do que muda e como testar.
- **Biome** faz o lint e a formatação em todos os pacotes, com as mesmas preferências do `controle-financeiro`: ponto e vírgula, aspas simples, vírgula final em tudo, 100 colunas, indentação de 2 espaços e fim de linha LF. O grupo de regras `a11y` fica ligado como erro. `tsc --noEmit` em modo estrito, e checagem automática (CI) rodando lint, tipos e testes.
- **CI no GitHub Actions** a cada push e pull request: instala com pnpm, usa o cache do Turborepo e sobe um PostgreSQL como serviço do job para os testes de integração. Falha em lint, tipos, testes ou acessibilidade impede o merge.
- **Licença:** nenhuma. O repositório é público para portfólio, mas sem arquivo de licença ninguém pode reutilizar o código sem permissão (todos os direitos reservados). Se a decisão mudar, a licença entra como arquivo `LICENSE` na raiz.
- Arquivos de segredo nunca vão para o git. Cada workspace tem `.env.example` com os nomes das variáveis e valores de exemplo.

## 11. Padrões de projeto e código limpo

### Código limpo

- **Nome que diz a intenção.** `calculateRemainingBalance` em vez de `calc` ou `process`. Sem abreviações obscuras.
- **Função pequena, uma responsabilidade.** Referência: até cerca de 20 linhas e no máximo 3 parâmetros; acima disso, agrupar em um objeto ou dividir a função. Arquivo acima de cerca de 300 linhas é sinal para dividir.
- **Retorno antecipado** em vez de `if` aninhado. Máximo de dois níveis de indentação na lógica.
- **Sem número ou texto mágico.** Constante nomeada: `DEFAULT_CLOSING_DAY`, não `5`.
- **Comentário explica o porquê**, nunca o quê. Se o comentário descreve o que o código faz, renomear ou extrair função.
- **Sem código morto**, sem `console.log` esquecido, sem `any` e sem `@ts-ignore`. Tipo desconhecido usa `unknown` e é validado.
- **Dados imutáveis por padrão**: `const`, `readonly` e novos objetos em vez de mutar os existentes.
- **Duplicação só vira abstração na terceira repetição** e quando as cópias mudam pelo mesmo motivo. Abstração prematura custa mais do que repetição.
- **Efeito colateral isolado.** Regra de negócio é função pura; banco, relógio, e-mail e rede ficam nas bordas e entram por parâmetro.

### Padrões de projeto

Padrão entra quando resolve um problema que o projeto já tem, nunca "por precaução". Os que o documento de decisões já pede:

| Padrão | Onde usar |
| --- | --- |
| **Service layer** | Regra de negócio fora das rotas (`BillService`, `SettlementService`). |
| **Unit of Work** | `runOperation` envolve a operação em uma transação e grava a auditoria junto. |
| **Strategy** | Escolha de comportamento por contexto: chave de idempotência da importação (`FITID` ou hash), ordem de sugestão de categoria e de responsável, ajuste de dia útil da recorrência. |
| **Factory / registro** | Layout de importação por banco e formato (OFX e CSV): um registro devolve o leitor correto. |
| **Adapter** | Isolar serviços externos (Supabase Auth, envio de e-mail, leitores de arquivo) atrás de uma interface do projeto, para trocar e testar sem rede. |
| **Repository** | Camada fixa da API (seção 6): só o repository conhece o Prisma. |
| **Specification (filtros compostos)** | Filtro de visibilidade e filtros de relatório montados a partir de pedaços reutilizáveis. |

- **Injeção de dependência por parâmetro**, sem contêiner: services recebem o cliente transacional, o relógio e os adaptadores como argumentos, o que facilita o teste.
- **Princípios SOLID** como guia de revisão, em especial responsabilidade única e inversão de dependência (a regra de negócio depende de interfaces, não de Prisma ou Supabase direto).
- **Composição em vez de herança**, no backend e nos componentes React. Componente grande se divide em componentes e hooks pequenos.
- No front, **hooks personalizados** isolam a lógica (`useSettleBill`) e deixam o componente só com a apresentação.

## 12. Tradução (i18n)

- **Idiomas iniciais:** `pt-BR` (padrão) e `en`. Outro idioma entra adicionando um catálogo, sem mexer em código.
- **Nenhum texto fixo no código.** Todo texto exibido ao usuário sai de um catálogo, no front e no back.
- **Catálogos em `shared/locales/`** (`pt-BR.json` e `en.json`), usados pelos dois lados. As chaves são em inglês, em notação com ponto e por área: `bills.settle.title`, `errors.SETTLEMENT_EXCEEDS_BALANCE`.
- **Frontend:** `i18next` com `react-i18next`. O idioma inicial vem do navegador e a escolha do usuário fica salva no perfil (`profile.locale`).
- **Backend:** lê `Accept-Language`, traduz `message` de erros e textos de e-mail e notificação pelo mesmo catálogo. Cada texto novo entra nos dois idiomas no mesmo pull request.
- **Formatação pelo `Intl` do navegador e do Node**, nunca à mão: números, moeda, data e hora usam `Intl.NumberFormat` e `Intl.DateTimeFormat` com o idioma ativo. Nunca montar texto concatenando pedaços; usar variáveis e plural do `i18next`.
- **Teste:** existe um teste que falha se uma chave estiver em um catálogo e faltar no outro.
- O `code` de erro e os valores de enum (`PAID`, `OPEN`) nunca são traduzidos; o que se traduz é o texto exibido.

### O que fica no banco e o que é traduzido

Três tipos de texto, cada um com um destino:

| Tipo | Exemplo | Onde fica | Tradução |
| --- | --- | --- | --- |
| **Erros da API** | `SETTLEMENT_EXCEEDS_BALANCE` | **Não é guardado.** O erro é montado na hora da resposta. | Servidor busca a `message` no catálogo do idioma de `Accept-Language`. |
| **Códigos e tipos do sistema** | `OPEN`, `PAID`, `OWNER`, `PAYABLE`, ações de auditoria (`CREATE`, `REVERSE`), categorias de sistema | No banco, **em inglês**, como código. | Traduzidos ao exibir, pelo catálogo, no idioma de quem está vendo. |
| **Texto digitado pelo usuário** | Descrição de lançamento, apelido, nome de categoria, nome de participante | No banco, **exatamente como foi digitado**. | **Nunca traduzido.** |

Consequências:

- Uma mesma linha pode ser exibida em idiomas diferentes para pessoas diferentes, porque o banco guarda o código (`PAID`) e não o texto ("Quitado").
- **Notificações guardam `type` e `params`, nunca o texto pronto.** A coluna `mensagem text` do documento de decisões vira `type text` e `params jsonb` (por exemplo `{ "billId": "...", "name": "Luz" }`). O texto é montado ao exibir, no idioma de quem lê. Assim, trocar o idioma do perfil muda também as notificações antigas.
- **E-mails são montados no idioma do destinatário no momento do envio**, a partir do `profile.locale`, usando os mesmos catálogos.
- A tabela de auditoria guarda ação e nomes de campo em inglês, e a tela os traduz. Os valores `de` e `para` de campos de texto livre ficam como foram digitados.
- Categoria criada pelo sistema (juros e multa, acerto) é identificada pelo código em `category.system_type` e tem o nome vindo do catálogo, não de uma coluna de texto. Categoria criada pelo usuário usa o `name` digitado.

## 13. Moeda

- **Uma moeda por espaço**, na coluna `space.currency`, com o código ISO 4217 (`BRL`, `EUR`, `USD`). Tudo dentro do espaço usa essa moeda. **Não há câmbio nem conversão.** Uma família em Portugal usa euro e uma no Brasil usa real, em espaços diferentes.
- A moeda é escolhida na criação do espaço, com sugestão pelo idioma do navegador (padrão `BRL`). **Só pode ser alterada enquanto o espaço não tiver nenhum título nem movimento**, porque trocar a moeda de valores já lançados mudaria o significado deles.
- **Unidade menor segue a moeda.** O número de casas decimais vem do ISO 4217 (`BRL`, `EUR`, `USD` têm 2; `JPY` tem 0; `KWD` tem 3), obtido por `Intl.NumberFormat(...).resolvedOptions()`. Nunca assumir 2 casas.
- **Tipo da coluna: `bigint` na unidade menor (decisão tomada).** Um `integer` de 32 bits só vai até 2.147.483.647 na unidade menor, ou cerca de R$ 21 milhões, e estoura em moedas de valor nominal alto, como o dong vietnamita. Foi descartado `numeric(15,2)` porque fixa 2 casas decimais (não serve ao dinar do Kuwait) e obrigaria todo cálculo a passar por `Decimal`. No código o valor continua `number`; a conversão acontece na camada de acesso a dados, com verificação de `Number.isSafeInteger`.
- **Valores não carregam moeda por linha**, já que a moeda é a do espaço. Quem exibe ou exporta recebe a moeda do espaço.
- **Importação de extrato:** se o arquivo informar uma moeda diferente da do espaço (campo `CURDEF` do OFX), a importação é bloqueada com erro `STATEMENT_CURRENCY_MISMATCH`.
- **Formatação** sempre por `Intl.NumberFormat` com o idioma ativo e a moeda do espaço (`1.234,56` em `pt-BR` e `1,234.56` em `en`). Ver seção 12.
- **Rateio:** a diferença de arredondamento fica no responsável, respeitando a unidade menor da moeda.
- **Evolução:** moeda por conta com câmbio fica como pendência futura. As funções de dinheiro já recebem a moeda como parâmetro, então essa mudança não exige reescrever o cálculo.

## 14. Segurança

### Autenticação

- **Supabase Auth** (decisão tomada): cadastro, confirmação de e-mail, recuperação de senha e login ficam com o Supabase. `profile.id` é o mesmo uuid de `auth.users.id`.
- O front usa o `supabase-js` só para autenticar e envia o **access token** no cabeçalho `Authorization: Bearer` para a API. Nenhuma outra chamada do front vai direto ao Supabase (a Data API fica desligada).
- O backend **verifica a assinatura do JWT** a cada requisição (chaves públicas JWKS do projeto, ou o segredo JWT em projetos antigos; conferir no momento de implementar) e usa o `sub` como `profile.id`.
- **Papel e permissões são relidos do banco a cada requisição**; o token serve só para saber quem é a pessoa. Assim, rebaixar ou remover alguém vale na hora, sem esperar o token expirar. Padrão herdado do `controle-financeiro`.
- Guards compostos por rota, como no app anterior (`requireAuth` e variações por papel e por espaço). Rota nova nasce protegida por hook de escopo, em vez de depender de alguém repetir o `preHandler`.
- O token fica no armazenamento do `supabase-js`, mais exposto a XSS que um cookie `httpOnly`. Compensação: CSP estrita, token de vida curta com renovação automática e nenhum HTML injetado sem sanitizar.
- **E-mails de autenticação** (confirmação e recuperação) saem pelo SMTP configurado no Supabase; o envio padrão tem limite baixo no plano gratuito, então o SMTP próprio entra antes de ter usuários reais.
- Chave de serviço do Supabase só no backend, nunca no front.
- **RLS ligado em todas as tabelas, sem nenhuma política.** Só o backend lê e grava (a Data API do Supabase fica desligada), e o papel do backend ignora o RLS. Quem não é o backend não recebe nada: se a Data API for ligada por engano, o banco continua fechado. As regras de visão ficam no código da API.
- Os papéis `anon` e `authenticated` do Supabase perdem os privilégios de tabela que recebem por padrão.
- Dados financeiros e e-mails não aparecem em log. Log registra identificadores e códigos.
- Convites usam código aleatório de uso único com expiração.
