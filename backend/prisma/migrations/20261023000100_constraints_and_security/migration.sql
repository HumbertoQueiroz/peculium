-- Everything Prisma cannot express: value checks, triggers, the audit lock, the FK to
-- Supabase Auth, row level security and the display view.
-- Written by hand; keep it in sync with docs/convencoes.md.

-- ===== Value checks =====

ALTER TABLE "space"
  ADD CONSTRAINT "space_closing_day_range" CHECK ("closing_day" BETWEEN 1 AND 28),
  ADD CONSTRAINT "space_currency_format" CHECK ("currency" ~ '^[A-Z]{3}$');

ALTER TABLE "account"
  ADD CONSTRAINT "account_closing_day_range" CHECK ("closing_day" IS NULL OR "closing_day" BETWEEN 1 AND 31),
  ADD CONSTRAINT "account_due_day_range" CHECK ("due_day" IS NULL OR "due_day" BETWEEN 1 AND 31),
  ADD CONSTRAINT "account_credit_limit_not_negative" CHECK ("credit_limit" IS NULL OR "credit_limit" >= 0);

ALTER TABLE "physical_card"
  ADD CONSTRAINT "physical_card_last_digits_format" CHECK ("last_digits" ~ '^[0-9]{4}$');

ALTER TABLE "card_invoice"
  ADD CONSTRAINT "card_invoice_reference_month_format"
    CHECK ("reference_month" ~ '^[0-9]{4}-(0[1-9]|1[0-2])$'),
  ADD CONSTRAINT "card_invoice_amounts_not_negative"
    CHECK ("total_amount" >= 0 AND "expected_amount" >= 0 AND "paid_amount" >= 0);

-- A plan is a group of bills created together: installments, a recurrence or a salary.
ALTER TABLE "installment_plan"
  ADD CONSTRAINT "installment_plan_total_positive" CHECK ("total_amount" > 0),
  ADD CONSTRAINT "installment_plan_count_range" CHECK ("installment_count" BETWEEN 1 AND 120),
  ADD CONSTRAINT "installment_plan_initial_range"
    CHECK ("initial_installment" BETWEEN 1 AND "installment_count"),
  ADD CONSTRAINT "installment_plan_interval_positive" CHECK ("interval" > 0),
  ADD CONSTRAINT "installment_plan_due_day_range" CHECK ("due_day" IS NULL OR "due_day" BETWEEN 1 AND 31);

-- Status follows the balance: OPEN keeps it whole, PARTIAL leaves some, PAID empties it.
ALTER TABLE "bill"
  ADD CONSTRAINT "bill_original_amount_positive" CHECK ("original_amount" > 0),
  ADD CONSTRAINT "bill_expected_amount_positive" CHECK ("expected_amount" IS NULL OR "expected_amount" > 0),
  ADD CONSTRAINT "bill_balance_within_original" CHECK ("balance" BETWEEN 0 AND "original_amount"),
  ADD CONSTRAINT "bill_total_discount_not_negative" CHECK ("total_discount" >= 0),
  ADD CONSTRAINT "bill_status_matches_balance" CHECK (
    "status" = 'CANCELED'
    OR ("status" = 'OPEN' AND "balance" = "original_amount")
    OR ("status" = 'PARTIAL' AND "balance" > 0 AND "balance" < "original_amount")
    OR ("status" = 'PAID' AND "balance" = 0)
  ),
  ADD CONSTRAINT "bill_installment_pair" CHECK (
    ("installment_plan_id" IS NULL) = ("installment_number" IS NULL)
  ),
  ADD CONSTRAINT "bill_installment_number_positive" CHECK ("installment_number" IS NULL OR "installment_number" > 0);

ALTER TABLE "bill_split"
  ADD CONSTRAINT "bill_split_amount_not_negative" CHECK ("amount" >= 0),
  ADD CONSTRAINT "bill_split_percentage_range" CHECK ("percentage" BETWEEN 0 AND 100);

ALTER TABLE "settlement"
  ADD CONSTRAINT "settlement_amortized_positive" CHECK ("amortized_amount" > 0),
  ADD CONSTRAINT "settlement_extras_not_negative"
    CHECK ("interest" >= 0 AND "penalty" >= 0 AND "discount" >= 0),
  ADD CONSTRAINT "settlement_moved_amount_formula"
    CHECK ("moved_amount" = "amortized_amount" + "interest" + "penalty" - "discount"),
  ADD CONSTRAINT "settlement_moved_amount_not_negative" CHECK ("moved_amount" >= 0);

-- A movement carries exactly the link its origin asks for.
ALTER TABLE "account_movement"
  ADD CONSTRAINT "account_movement_amount_positive" CHECK ("amount" > 0),
  ADD CONSTRAINT "account_movement_transfer_link"
    CHECK (("origin" = 'TRANSFER') = ("transfer_id" IS NOT NULL)),
  ADD CONSTRAINT "account_movement_reversal_link"
    CHECK (("origin" = 'REVERSAL') = ("reversed_movement_id" IS NOT NULL)),
  ADD CONSTRAINT "account_movement_settlement_link"
    CHECK ("settlement_id" IS NULL OR "origin" = 'SETTLEMENT');

ALTER TABLE "statement_import"
  ADD CONSTRAINT "statement_import_period_order" CHECK ("period_start" <= "period_end");

ALTER TABLE "statement_line"
  ADD CONSTRAINT "statement_line_amount_positive" CHECK ("amount" > 0);

ALTER TABLE "categorization_rule"
  ADD CONSTRAINT "categorization_rule_amounts_not_negative"
    CHECK (("min_amount" IS NULL OR "min_amount" >= 0) AND ("max_amount" IS NULL OR "max_amount" >= 0)),
  ADD CONSTRAINT "categorization_rule_amount_order"
    CHECK ("min_amount" IS NULL OR "max_amount" IS NULL OR "min_amount" <= "max_amount");

ALTER TABLE "suggestion_history"
  ADD CONSTRAINT "suggestion_history_count_positive" CHECK ("count" > 0);

-- ===== Triggers =====

-- The time zone is an IANA name that PostgreSQL knows, never a fixed offset.
CREATE FUNCTION "space_validate_timezone"() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_timezone_names WHERE name = NEW."timezone") THEN
    RAISE EXCEPTION 'invalid time zone: %', NEW."timezone" USING ERRCODE = '22023';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER "space_validate_timezone"
  BEFORE INSERT OR UPDATE OF "timezone" ON "space"
  FOR EACH ROW EXECUTE FUNCTION "space_validate_timezone"();

-- Changing the currency of values already entered would change what they mean.
CREATE FUNCTION "space_lock_currency"() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM "bill" WHERE "space_id" = OLD."id")
     OR EXISTS (SELECT 1 FROM "account_movement" WHERE "space_id" = OLD."id") THEN
    RAISE EXCEPTION 'space currency is locked once the space has bills or movements'
      USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER "space_lock_currency"
  BEFORE UPDATE OF "currency" ON "space"
  FOR EACH ROW WHEN (OLD."currency" IS DISTINCT FROM NEW."currency")
  EXECUTE FUNCTION "space_lock_currency"();

-- At most two levels, and a parent always lives in the same space.
CREATE FUNCTION "category_validate_tree"() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW."parent_id" IS NULL THEN
    RETURN NEW;
  END IF;
  IF NEW."parent_id" = NEW."id" THEN
    RAISE EXCEPTION 'a category cannot be its own parent' USING ERRCODE = '23514';
  END IF;
  IF EXISTS (
    SELECT 1 FROM "category"
    WHERE "id" = NEW."parent_id" AND ("parent_id" IS NOT NULL OR "space_id" <> NEW."space_id")
  ) THEN
    RAISE EXCEPTION 'a category has at most two levels and its parent must be in the same space'
      USING ERRCODE = '23514';
  END IF;
  IF EXISTS (SELECT 1 FROM "category" WHERE "parent_id" = NEW."id") THEN
    RAISE EXCEPTION 'a category with children cannot become a child' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER "category_validate_tree"
  BEFORE INSERT OR UPDATE OF "parent_id" ON "category"
  FOR EACH ROW EXECUTE FUNCTION "category_validate_tree"();

-- ===== Audit log: insert only =====
-- Blocks every role, including the one the backend connects with, so a bug cannot rewrite history.

CREATE FUNCTION "audit_log_reject_change"() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'audit_log is insert only' USING ERRCODE = '42501';
END;
$$;

CREATE TRIGGER "audit_log_no_update_delete"
  BEFORE UPDATE OR DELETE ON "audit_log"
  FOR EACH ROW EXECUTE FUNCTION "audit_log_reject_change"();

CREATE TRIGGER "audit_log_no_truncate"
  BEFORE TRUNCATE ON "audit_log"
  FOR EACH STATEMENT EXECUTE FUNCTION "audit_log_reject_change"();

-- ===== Supabase Auth link =====
-- Skipped on a plain PostgreSQL (local development and tests), where there is no auth schema.

DO $$
BEGIN
  IF to_regclass('auth.users') IS NOT NULL THEN
    ALTER TABLE "profile"
      ADD CONSTRAINT "profile_id_fkey" FOREIGN KEY ("id") REFERENCES auth.users ("id") ON DELETE CASCADE;
  END IF;
END;
$$;

-- ===== Row level security: deny by default =====
-- Only the backend reads and writes (the Supabase Data API is off). With RLS on and no
-- policies, anyone who is not the backend role gets nothing, which keeps the database closed
-- if the Data API is ever turned on by mistake. The backend role bypasses RLS.

ALTER TABLE "profile" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "space" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "member" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "participant" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "invitation" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "view_share" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "account" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "physical_card" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "category" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "cost_center" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "card_invoice" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "installment_plan" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "bill" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "bill_split" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "settlement" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "reconciliation" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "account_movement" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "import_layout" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "statement_import" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "statement_line" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "categorization_rule" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "suggestion_history" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "description_nickname" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "change_request" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "notification" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "audit_log" ENABLE ROW LEVEL SECURITY;

-- Supabase hands the API roles table privileges by default; take them back.
DO $$
DECLARE
  api_role text;
BEGIN
  FOREACH api_role IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = api_role) THEN
      EXECUTE format('REVOKE ALL ON ALL TABLES IN SCHEMA public FROM %I', api_role);
      EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM %I', api_role);
    END IF;
  END LOOP;
END;
$$;

-- ===== Views =====

-- The text shown for a bill: plan nickname, then bill nickname, then the supplier nickname for
-- the same normalized description, then the original text, which is never changed.
CREATE VIEW "bill_display" WITH (security_invoker = true) AS
SELECT
  b."id",
  b."space_id",
  COALESCE(p."nickname", b."nickname", n."nickname", b."original_description") AS "display_description",
  b."original_description"
FROM "bill" b
LEFT JOIN "installment_plan" p ON p."id" = b."installment_plan_id"
LEFT JOIN "description_nickname" n
  ON n."space_id" = b."space_id" AND n."normalized_description" = b."normalized_description";
