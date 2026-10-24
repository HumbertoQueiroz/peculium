# Sistema de design

Regras visuais do Peculium. Os valores exatos de cada cor, raio e fonte estão em [`frontend/src/styles/theme.css`](../frontend/src/styles/theme.css), que é a **fonte da verdade**. Este documento explica as escolhas e as regras de uso. Convenções de código estão em [convenções](convencoes.md).

## Decisões

| Tema | Decisão |
| --- | --- |
| Cor da marca | **Índigo** (azul-roxo, `#4F46E5` no claro e `#818CF8` no escuro), a mesma do `controle-financeiro`. Uma só cor de destaque; o roxo aparece apenas nos gráficos e no degradê decorativo. |
| Neutros | **Azul-marinho**: no claro, fundo `#EEF2FA` e cartões `#F8FAFF`; no escuro, fundo `#070D2B` e cartões `#0F173F` |
| Branco e preto | **Nunca puros**, em nenhum modo: superfícies claras são azul-branco e as escuras são azul-marinho profundo. Sombras e sobreposições também levam o tom do marinho. |
| Formato das cores | **OKLCH dentro do sRGB**, para a luminosidade percebida ser uniforme e a aparência igual em qualquer monitor padrão |
| Papéis, não paleta | Componentes usam só papéis do `theme.css`. Classe da paleta do Tailwind (`bg-slate-100`), `bg-black`, `text-white` e hex solto falham em teste. |
| Fonte | **Inter**, com números tabulares nos valores |
| Cantos | **8 px** (`--radius: 0.5rem`) |
| Componentes | shadcn/ui sobre Tailwind CSS |
| Ícones | Phosphor Icons |
| Modo escuro | Sim, classe `.dark` no `<html>`, segue o sistema e aceita escolha do usuário |

## Papéis de cor

Componentes usam **papéis**, nunca valores soltos: `bg-primary`, `text-muted-foreground`, `border-border`. Trocar uma cor é mudar um valor no `theme.css`.

| Papel | Uso |
| --- | --- |
| `background` / `foreground` | Fundo da página e texto principal |
| `card` / `popover` | Superfícies elevadas (cartões, menus, diálogos) |
| `muted` / `muted-foreground` | Áreas discretas e texto de apoio |
| `primary` | Ação principal (no máximo um botão primário por tela) |
| `secondary` | Ação secundária |
| `accent` | Realce suave, item selecionado, hover de menu |
| `border` | Divisores e bordas decorativas |
| `input` | Borda de campos de formulário (mais forte, precisa de contraste 3:1) |
| `ring` | Anel de foco |
| `destructive` | Ação destrutiva (excluir) |

## Cores dos estados do dinheiro

Cada estado tem três tons: texto (`payable`), fundo suave (`payable-muted`) e borda (`payable-border`).

| Estado | Papel | Cor | Quando |
| --- | --- | --- | --- |
| A pagar | `payable` | Laranja escuro | Título a pagar em aberto ou parcial, dentro do prazo |
| Atrasado | `overdue` | Vermelho | Título em aberto ou parcial com vencimento anterior a "hoje" |
| Negativo | `negative` (mesmo vermelho de `overdue`) | Vermelho | Qualquer valor menor que zero (saldo, projeção, diferença) |
| A receber | `receivable` | Azul-céu | Título a receber em aberto, dentro do prazo |
| Positivo | `positive` | Verde | **Resultado calculado** maior que zero: saldo, total, projeção |
| Quitado | `paid` | Cinza neutro | Título pago ou recebido por completo |

Regras:

- **Vermelho é reservado para alerta**: atrasado, negativo e ação destrutiva. A despesa comum não é vermelha.
- **Atrasado é derivado, não gravado.** O enum `BillStatus` não tem `OVERDUE`. O front e o servidor calculam: status `OPEN` ou `PARTIAL` e `dueDate` anterior ao "hoje" do espaço (fuso do espaço, ver convenções).
- **Vence a regra mais grave:** atrasado ganha de a pagar. Um título a receber atrasado também fica vermelho.
- **Cor nunca vai sozinha.** Laranja e vermelho se confundem para quem tem daltonismo. Todo estado leva o **rótulo** (`A pagar`, `Atrasado`) e todo valor leva o **sinal** (`+` e `−`). O atrasado ainda ganha o ícone `WarningCircle` do Phosphor.
- **Verde é só para cálculo positivo.** Um título a receber não é verde: é azul-céu (`receivable`). O verde (`positive`) aparece no resultado de uma conta, como o saldo projetado ou o total do mês.
- **A receber é azul-céu, diferente do índigo da marca**, para o rótulo "A receber" não se confundir com um botão ou item ativo.
- Cancelado usa `paid-muted` com texto riscado.

## Outros papéis de feedback

| Papel | Uso |
| --- | --- |
| `warning` | Atenção sem erro: solicitação de alteração pendente, estimativa a confirmar |
| `info` | Informação neutra: dicas, avisos de importação |

## Gráficos

`chart-1` a `chart-5` são cores categóricas (índigo, roxo, rosa, dourado e cinza-azulado) que **evitam laranja, vermelho, verde e azul-céu**, para não parecerem estados de dinheiro. Quando um gráfico mostra estado (a pagar, atrasado, a receber), usa os papéis de estado, não as cores de categoria.

## Tipografia

- **Inter** variável (`@fontsource-variable/inter`), servida junto do app.
- **Valores monetários** sempre com `tabular-nums`, para as colunas alinharem.
- Escala: corpo 14 px nas telas densas (listas, tabelas) e 16 px em texto corrido. Títulos 18, 20 e 24 px. Dois pesos: 400 e 500.
- Texto da interface em sentence case ("Nova conta", não "Nova Conta").

## Forma, espaço e movimento

- **Cantos:** `rounded-lg` (8 px) em cartões e campos, `rounded-md` (6 px) em botões e chips, `rounded-xl` (12 px) em diálogos.
- **Espaçamento:** escala de 4 px do Tailwind. Margens laterais de página: 16 px no celular, 24 px a partir do tablet.
- **Elevação:** cartão é `bg-card` com borda `border`, sem sombra. Sombra fica para menus e diálogos.
- **Movimento:** 150 ms, curva de saída suave. Com `prefers-reduced-motion`, animações ficam praticamente instantâneas (já está no tema).

## Ícones

- **Phosphor Icons** (`@phosphor-icons/react`), peso `regular` por padrão e `fill` para o item ativo de navegação.
- Tamanhos 16, 20 e 24 px. Ícone decorativo leva `aria-hidden`; botão só com ícone leva `aria-label`.
- Ícones fixos por significado: `WarningCircle` (atrasado), `CheckCircle` (quitado), `ArrowDown` e `ArrowUp` (entrada e saída).

## Estados de interação

Todo elemento clicável tem os quatro estados definidos, e o hover é obrigatório no computador:

| Estado | Regra |
| --- | --- |
| Hover | Sempre presente. Muda fundo, borda ou sublinhado de forma perceptível. Só em aparelhos com mouse. |
| Foco | Anel `ring` sempre visível ao navegar por teclado. |
| Pressionado (`active`) | Um passo além do hover (um pouco mais escuro no claro, mais claro no escuro). |
| Desabilitado | Evitar. Preferir manter ativo e responder ao uso. Se for inevitável, explicar o motivo em texto. |

Padrões de hover por tipo:

- **Botão primário:** fundo de `primary` um passo mais forte.
- **Botão secundário e ghost:** fundo `accent` ou `muted`.
- **Link:** sublinhado.
- **Linha ou cartão clicável:** fundo `muted` e borda um passo mais forte.
- **Item de menu e aba:** fundo `accent`.
- **Ícone de ação:** fundo `muted` em volta do ícone.

Toda a base do app já aplica `cursor: pointer` aos elementos clicáveis (regra em `theme.css`), então uma tela nova nasce com o cursor certo. O hover nunca é o único caminho para uma função: no toque e no teclado, tudo continua acessível.

## Acessibilidade

- Texto precisa de contraste mínimo **4,5:1** e elementos de interface (bordas de campo, anel de foco) de **3:1**. Todos os pares de `theme.css` foram calculados nos dois modos e passam; uma cor nova só entra depois de ser medida.
- Foco sempre visível, com `ring`.
- Área de toque mínima de **44 px** nos controles, como nas convenções de mobile first, responsivo e acessível (ver [convenções](convencoes.md)).
- Nenhuma informação apenas por cor (ver estados do dinheiro).

## Componentes do produto

Componentes próprios que montam sobre o shadcn/ui, em `frontend/src/shared/ui`:

- **`Money`**: formata na moeda do espaço, com `Intl.NumberFormat`, `tabular-nums` e sinal. Recebe o estado (`payable`, `overdue`, `receivable`, `paid`, `positive`, `negative`) e aplica a cor.
- **`BillStatusBadge`**: recebe o título e calcula o estado visível (incluindo atrasado), com rótulo traduzido, cor e ícone.
- **`EmptyState`**, **`PageHeader`** e **`ConfirmDialog`**: padrões de tela repetidos.

Todo texto vem dos catálogos de tradução (`bills.status.overdue`, `bills.status.payable`), nunca fixo no componente.
