-- CreateEnum
CREATE TYPE "member_role" AS ENUM ('OWNER', 'EDITOR', 'CONTRIBUTOR', 'VIEWER');

-- CreateEnum
CREATE TYPE "invitation_status" AS ENUM ('PENDING', 'ACCEPTED', 'EXPIRED', 'CANCELED');

-- CreateEnum
CREATE TYPE "account_type" AS ENUM ('CHECKING', 'SAVINGS', 'WALLET', 'INVESTMENT', 'CREDIT_CARD');

-- CreateEnum
CREATE TYPE "physical_card_type" AS ENUM ('HOLDER', 'ADDITIONAL', 'VIRTUAL');

-- CreateEnum
CREATE TYPE "category_kind" AS ENUM ('INCOME', 'EXPENSE');

-- CreateEnum
CREATE TYPE "system_category" AS ENUM ('INTEREST_PENALTY_PAID', 'INTEREST_PENALTY_RECEIVED', 'REIMBURSEMENT');

-- CreateEnum
CREATE TYPE "nature" AS ENUM ('PAYABLE', 'RECEIVABLE');

-- CreateEnum
CREATE TYPE "bill_status" AS ENUM ('OPEN', 'PARTIAL', 'PAID', 'CANCELED');

-- CreateEnum
CREATE TYPE "split_mode" AS ENUM ('AMOUNT', 'PERCENTAGE');

-- CreateEnum
CREATE TYPE "settlement_reason" AS ENUM ('PAYMENT', 'LOSS', 'ABATEMENT');

-- CreateEnum
CREATE TYPE "direction" AS ENUM ('INFLOW', 'OUTFLOW');

-- CreateEnum
CREATE TYPE "movement_origin" AS ENUM ('SETTLEMENT', 'TRANSFER', 'ADJUSTMENT', 'OPENING_BALANCE', 'REVERSAL');

-- CreateEnum
CREATE TYPE "invoice_status" AS ENUM ('FUTURE', 'OPEN', 'CLOSED', 'PAID', 'PARTIALLY_PAID');

-- CreateEnum
CREATE TYPE "frequency" AS ENUM ('WEEKLY', 'MONTHLY', 'YEARLY');

-- CreateEnum
CREATE TYPE "business_day_adjustment" AS ENUM ('KEEP', 'ADVANCE', 'POSTPONE');

-- CreateEnum
CREATE TYPE "plan_kind" AS ENUM ('INSTALLMENT', 'RECURRING', 'SALARY');

-- CreateEnum
CREATE TYPE "import_format" AS ENUM ('OFX', 'CSV');

-- CreateEnum
CREATE TYPE "key_strategy" AS ENUM ('FITID', 'OCCURRENCE_HASH');

-- CreateEnum
CREATE TYPE "statement_line_status" AS ENUM ('PENDING', 'RECONCILED', 'IGNORED', 'MISSING');

-- CreateEnum
CREATE TYPE "rule_condition" AS ENUM ('CONTAINS', 'STARTS_WITH', 'EQUALS');

-- CreateEnum
CREATE TYPE "change_request_status" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELED');

-- CreateEnum
CREATE TYPE "audit_origin" AS ENUM ('USER', 'SYSTEM', 'IMPORT');

-- CreateTable
CREATE TABLE "profile" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "locale" TEXT NOT NULL DEFAULT 'pt-BR',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "profile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "space" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "closing_day" INTEGER NOT NULL DEFAULT 5,
    "notify_by_email" BOOLEAN NOT NULL DEFAULT true,
    "timezone" TEXT NOT NULL DEFAULT 'America/Sao_Paulo',
    "currency" CHAR(3) NOT NULL DEFAULT 'BRL',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "space_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "member" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "role" "member_role" NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "member_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "participant" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "user_id" UUID,
    "active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "participant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invitation" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "email" TEXT NOT NULL,
    "role" "member_role" NOT NULL,
    "participant_id" UUID,
    "code" TEXT NOT NULL,
    "status" "invitation_status" NOT NULL DEFAULT 'PENDING',
    "invited_by_id" UUID NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "invitation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "view_share" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "from_user_id" UUID NOT NULL,
    "to_user_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "view_share_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "account" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "type" "account_type" NOT NULL,
    "institution" TEXT,
    "holder_id" UUID,
    "balance" BIGINT NOT NULL DEFAULT 0,
    "credit_limit" BIGINT,
    "closing_day" INTEGER,
    "due_day" INTEGER,
    "color" TEXT,
    "icon" TEXT,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "physical_card" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "account_id" UUID NOT NULL,
    "participant_id" UUID NOT NULL,
    "last_digits" CHAR(4) NOT NULL,
    "nickname" TEXT,
    "type" "physical_card_type" NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "physical_card_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "category" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "kind" "category_kind" NOT NULL,
    "parent_id" UUID,
    "system_type" "system_category",
    "color" TEXT,
    "icon" TEXT,
    "archived" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "category_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cost_center" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "start_date" DATE,
    "end_date" DATE,
    "active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "cost_center_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "card_invoice" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "account_id" UUID NOT NULL,
    "reference_month" CHAR(7) NOT NULL,
    "closing_date" DATE NOT NULL,
    "due_date" DATE NOT NULL,
    "previous_balance" BIGINT NOT NULL DEFAULT 0,
    "total_amount" BIGINT NOT NULL DEFAULT 0,
    "expected_amount" BIGINT NOT NULL DEFAULT 0,
    "paid_amount" BIGINT NOT NULL DEFAULT 0,
    "status" "invoice_status" NOT NULL,

    CONSTRAINT "card_invoice_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "installment_plan" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "kind" "plan_kind" NOT NULL DEFAULT 'INSTALLMENT',
    "description" TEXT NOT NULL,
    "normalized_description" TEXT NOT NULL,
    "nickname" TEXT,
    "total_amount" BIGINT NOT NULL,
    "installment_count" INTEGER NOT NULL,
    "initial_installment" INTEGER NOT NULL DEFAULT 1,
    "purchase_date" DATE NOT NULL,
    "frequency" "frequency" NOT NULL DEFAULT 'MONTHLY',
    "interval" INTEGER NOT NULL DEFAULT 1,
    "due_day" INTEGER,
    "business_day_adjustment" "business_day_adjustment" NOT NULL DEFAULT 'KEEP',
    "expected_account_id" UUID,
    "created_by_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "installment_plan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bill" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "nature" "nature" NOT NULL,
    "original_description" TEXT NOT NULL,
    "normalized_description" TEXT NOT NULL,
    "nickname" TEXT,
    "original_amount" BIGINT NOT NULL,
    "expected_amount" BIGINT,
    "estimated" BOOLEAN NOT NULL DEFAULT false,
    "balance" BIGINT NOT NULL,
    "total_discount" BIGINT NOT NULL DEFAULT 0,
    "status" "bill_status" NOT NULL DEFAULT 'OPEN',
    "accrual_date" DATE NOT NULL,
    "due_date" DATE NOT NULL,
    "category_id" UUID,
    "cost_center_id" UUID,
    "buyer_id" UUID NOT NULL,
    "split_mode" "split_mode",
    "expected_account_id" UUID,
    "card_invoice_id" UUID,
    "installment_plan_id" UUID,
    "installment_number" INTEGER,
    "manually_edited" BOOLEAN NOT NULL DEFAULT false,
    "notes" TEXT,
    "created_by_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "bill_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bill_split" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "bill_id" UUID NOT NULL,
    "participant_id" UUID NOT NULL,
    "amount" BIGINT NOT NULL,
    "percentage" DECIMAL(7,4) NOT NULL,

    CONSTRAINT "bill_split_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "settlement" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "bill_id" UUID NOT NULL,
    "reason" "settlement_reason" NOT NULL,
    "date" DATE NOT NULL,
    "amortized_amount" BIGINT NOT NULL,
    "interest" BIGINT NOT NULL DEFAULT 0,
    "penalty" BIGINT NOT NULL DEFAULT 0,
    "discount" BIGINT NOT NULL DEFAULT 0,
    "moved_amount" BIGINT NOT NULL,
    "notes" TEXT,
    "created_by_id" UUID NOT NULL,
    "reversed_at" TIMESTAMPTZ(6),
    "reversal_reason" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "settlement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reconciliation" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "account_id" UUID NOT NULL,
    "reconciled_by_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "reconciliation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "account_movement" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "account_id" UUID NOT NULL,
    "date" DATE NOT NULL,
    "direction" "direction" NOT NULL,
    "amount" BIGINT NOT NULL,
    "origin" "movement_origin" NOT NULL,
    "settlement_id" UUID,
    "transfer_id" UUID,
    "reversed_movement_id" UUID,
    "card_invoice_id" UUID,
    "physical_card_id" UUID,
    "reconciliation_id" UUID,
    "description" TEXT NOT NULL,
    "created_by_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "account_movement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "import_layout" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "bank" TEXT NOT NULL,
    "format" "import_format" NOT NULL,
    "key_strategy" "key_strategy" NOT NULL,
    "mapping" JSONB NOT NULL,
    "installment_pattern" TEXT,

    CONSTRAINT "import_layout_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "statement_import" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "account_id" UUID NOT NULL,
    "layout_id" UUID,
    "format" "import_format" NOT NULL,
    "file_name" TEXT NOT NULL,
    "file_hash" TEXT NOT NULL,
    "period_start" DATE NOT NULL,
    "period_end" DATE NOT NULL,
    "reported_balance" BIGINT,
    "reported_limit" BIGINT,
    "imported_by_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "statement_import_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "statement_line" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "account_id" UUID NOT NULL,
    "import_id" UUID NOT NULL,
    "last_import_id" UUID NOT NULL,
    "external_id" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "direction" "direction" NOT NULL,
    "amount" BIGINT NOT NULL,
    "description" TEXT NOT NULL,
    "normalized_description" TEXT NOT NULL,
    "card_last_digits" CHAR(4),
    "status" "statement_line_status" NOT NULL DEFAULT 'PENDING',
    "reconciliation_id" UUID,

    CONSTRAINT "statement_line_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "categorization_rule" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "account_id" UUID,
    "condition" "rule_condition" NOT NULL,
    "text" TEXT NOT NULL,
    "direction" "direction",
    "min_amount" BIGINT,
    "max_amount" BIGINT,
    "category_id" UUID NOT NULL,
    "cost_center_id" UUID,
    "buyer_id" UUID,
    "priority" INTEGER NOT NULL DEFAULT 100,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "times_applied" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "categorization_rule_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "suggestion_history" (
    "space_id" UUID NOT NULL,
    "normalized_description" TEXT NOT NULL,
    "category_id" UUID,
    "buyer_id" UUID,
    "split_mode" "split_mode",
    "split" JSONB,
    "count" INTEGER NOT NULL DEFAULT 1,
    "last_used_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "suggestion_history_pkey" PRIMARY KEY ("space_id","normalized_description")
);

-- CreateTable
CREATE TABLE "description_nickname" (
    "space_id" UUID NOT NULL,
    "normalized_description" TEXT NOT NULL,
    "nickname" TEXT NOT NULL,
    "created_by_id" UUID NOT NULL,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "description_nickname_pkey" PRIMARY KEY ("space_id","normalized_description")
);

-- CreateTable
CREATE TABLE "change_request" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "bill_id" UUID NOT NULL,
    "requester_id" UUID NOT NULL,
    "proposed_change" JSONB NOT NULL,
    "message" TEXT,
    "status" "change_request_status" NOT NULL DEFAULT 'PENDING',
    "resolved_by_id" UUID,
    "resolved_at" TIMESTAMPTZ(6),
    "response" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "change_request_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notification" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "reference" UUID,
    "params" JSONB NOT NULL DEFAULT '{}',
    "read_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_log" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "space_id" UUID NOT NULL,
    "entity" TEXT NOT NULL,
    "entity_id" UUID NOT NULL,
    "action" TEXT NOT NULL,
    "changes" JSONB NOT NULL,
    "user_id" UUID,
    "origin" "audit_origin" NOT NULL,
    "correlation_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_log_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "member_space_id_user_id_key" ON "member"("space_id", "user_id");

-- CreateIndex
CREATE UNIQUE INDEX "participant_space_id_user_id_key" ON "participant"("space_id", "user_id");

-- CreateIndex
CREATE UNIQUE INDEX "invitation_code_key" ON "invitation"("code");

-- CreateIndex
CREATE UNIQUE INDEX "view_share_space_id_from_user_id_to_user_id_key" ON "view_share"("space_id", "from_user_id", "to_user_id");

-- CreateIndex
CREATE UNIQUE INDEX "card_invoice_account_id_reference_month_key" ON "card_invoice"("account_id", "reference_month");

-- CreateIndex
CREATE INDEX "installment_plan_space_id_normalized_description_idx" ON "installment_plan"("space_id", "normalized_description");

-- CreateIndex
CREATE INDEX "bill_space_id_due_date_idx" ON "bill"("space_id", "due_date");

-- CreateIndex
CREATE INDEX "bill_space_id_normalized_description_idx" ON "bill"("space_id", "normalized_description");

-- CreateIndex
CREATE INDEX "bill_card_invoice_id_idx" ON "bill"("card_invoice_id");

-- CreateIndex
CREATE UNIQUE INDEX "bill_installment_plan_id_installment_number_key" ON "bill"("installment_plan_id", "installment_number");

-- CreateIndex
CREATE UNIQUE INDEX "bill_split_bill_id_participant_id_key" ON "bill_split"("bill_id", "participant_id");

-- CreateIndex
CREATE UNIQUE INDEX "account_movement_settlement_id_key" ON "account_movement"("settlement_id");

-- CreateIndex
CREATE INDEX "account_movement_account_id_date_idx" ON "account_movement"("account_id", "date");

-- CreateIndex
CREATE UNIQUE INDEX "statement_line_account_id_external_id_key" ON "statement_line"("account_id", "external_id");

-- CreateIndex
CREATE INDEX "audit_log_entity_entity_id_idx" ON "audit_log"("entity", "entity_id");

-- CreateIndex
CREATE INDEX "audit_log_correlation_id_idx" ON "audit_log"("correlation_id");

-- AddForeignKey
ALTER TABLE "member" ADD CONSTRAINT "member_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "member" ADD CONSTRAINT "member_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "participant" ADD CONSTRAINT "participant_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "participant" ADD CONSTRAINT "participant_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invitation" ADD CONSTRAINT "invitation_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invitation" ADD CONSTRAINT "invitation_participant_id_fkey" FOREIGN KEY ("participant_id") REFERENCES "participant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invitation" ADD CONSTRAINT "invitation_invited_by_id_fkey" FOREIGN KEY ("invited_by_id") REFERENCES "profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "view_share" ADD CONSTRAINT "view_share_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "view_share" ADD CONSTRAINT "view_share_from_user_id_fkey" FOREIGN KEY ("from_user_id") REFERENCES "profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "view_share" ADD CONSTRAINT "view_share_to_user_id_fkey" FOREIGN KEY ("to_user_id") REFERENCES "profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account" ADD CONSTRAINT "account_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account" ADD CONSTRAINT "account_holder_id_fkey" FOREIGN KEY ("holder_id") REFERENCES "participant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "physical_card" ADD CONSTRAINT "physical_card_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "physical_card" ADD CONSTRAINT "physical_card_participant_id_fkey" FOREIGN KEY ("participant_id") REFERENCES "participant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "category" ADD CONSTRAINT "category_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "category" ADD CONSTRAINT "category_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cost_center" ADD CONSTRAINT "cost_center_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "card_invoice" ADD CONSTRAINT "card_invoice_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "card_invoice" ADD CONSTRAINT "card_invoice_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "installment_plan" ADD CONSTRAINT "installment_plan_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "installment_plan" ADD CONSTRAINT "installment_plan_expected_account_id_fkey" FOREIGN KEY ("expected_account_id") REFERENCES "account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "installment_plan" ADD CONSTRAINT "installment_plan_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill" ADD CONSTRAINT "bill_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill" ADD CONSTRAINT "bill_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill" ADD CONSTRAINT "bill_cost_center_id_fkey" FOREIGN KEY ("cost_center_id") REFERENCES "cost_center"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill" ADD CONSTRAINT "bill_buyer_id_fkey" FOREIGN KEY ("buyer_id") REFERENCES "participant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill" ADD CONSTRAINT "bill_expected_account_id_fkey" FOREIGN KEY ("expected_account_id") REFERENCES "account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill" ADD CONSTRAINT "bill_card_invoice_id_fkey" FOREIGN KEY ("card_invoice_id") REFERENCES "card_invoice"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill" ADD CONSTRAINT "bill_installment_plan_id_fkey" FOREIGN KEY ("installment_plan_id") REFERENCES "installment_plan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill" ADD CONSTRAINT "bill_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill_split" ADD CONSTRAINT "bill_split_bill_id_fkey" FOREIGN KEY ("bill_id") REFERENCES "bill"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill_split" ADD CONSTRAINT "bill_split_participant_id_fkey" FOREIGN KEY ("participant_id") REFERENCES "participant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "settlement" ADD CONSTRAINT "settlement_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "settlement" ADD CONSTRAINT "settlement_bill_id_fkey" FOREIGN KEY ("bill_id") REFERENCES "bill"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "settlement" ADD CONSTRAINT "settlement_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reconciliation" ADD CONSTRAINT "reconciliation_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reconciliation" ADD CONSTRAINT "reconciliation_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reconciliation" ADD CONSTRAINT "reconciliation_reconciled_by_id_fkey" FOREIGN KEY ("reconciled_by_id") REFERENCES "profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account_movement" ADD CONSTRAINT "account_movement_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account_movement" ADD CONSTRAINT "account_movement_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account_movement" ADD CONSTRAINT "account_movement_settlement_id_fkey" FOREIGN KEY ("settlement_id") REFERENCES "settlement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account_movement" ADD CONSTRAINT "account_movement_reversed_movement_id_fkey" FOREIGN KEY ("reversed_movement_id") REFERENCES "account_movement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account_movement" ADD CONSTRAINT "account_movement_card_invoice_id_fkey" FOREIGN KEY ("card_invoice_id") REFERENCES "card_invoice"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account_movement" ADD CONSTRAINT "account_movement_physical_card_id_fkey" FOREIGN KEY ("physical_card_id") REFERENCES "physical_card"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account_movement" ADD CONSTRAINT "account_movement_reconciliation_id_fkey" FOREIGN KEY ("reconciliation_id") REFERENCES "reconciliation"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account_movement" ADD CONSTRAINT "account_movement_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "statement_import" ADD CONSTRAINT "statement_import_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "statement_import" ADD CONSTRAINT "statement_import_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "statement_import" ADD CONSTRAINT "statement_import_layout_id_fkey" FOREIGN KEY ("layout_id") REFERENCES "import_layout"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "statement_import" ADD CONSTRAINT "statement_import_imported_by_id_fkey" FOREIGN KEY ("imported_by_id") REFERENCES "profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "statement_line" ADD CONSTRAINT "statement_line_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "statement_line" ADD CONSTRAINT "statement_line_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "statement_line" ADD CONSTRAINT "statement_line_import_id_fkey" FOREIGN KEY ("import_id") REFERENCES "statement_import"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "statement_line" ADD CONSTRAINT "statement_line_last_import_id_fkey" FOREIGN KEY ("last_import_id") REFERENCES "statement_import"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "statement_line" ADD CONSTRAINT "statement_line_reconciliation_id_fkey" FOREIGN KEY ("reconciliation_id") REFERENCES "reconciliation"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "categorization_rule" ADD CONSTRAINT "categorization_rule_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "categorization_rule" ADD CONSTRAINT "categorization_rule_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "categorization_rule" ADD CONSTRAINT "categorization_rule_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "categorization_rule" ADD CONSTRAINT "categorization_rule_cost_center_id_fkey" FOREIGN KEY ("cost_center_id") REFERENCES "cost_center"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "categorization_rule" ADD CONSTRAINT "categorization_rule_buyer_id_fkey" FOREIGN KEY ("buyer_id") REFERENCES "participant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "suggestion_history" ADD CONSTRAINT "suggestion_history_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "suggestion_history" ADD CONSTRAINT "suggestion_history_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "suggestion_history" ADD CONSTRAINT "suggestion_history_buyer_id_fkey" FOREIGN KEY ("buyer_id") REFERENCES "participant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "description_nickname" ADD CONSTRAINT "description_nickname_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "description_nickname" ADD CONSTRAINT "description_nickname_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "change_request" ADD CONSTRAINT "change_request_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "change_request" ADD CONSTRAINT "change_request_bill_id_fkey" FOREIGN KEY ("bill_id") REFERENCES "bill"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "change_request" ADD CONSTRAINT "change_request_requester_id_fkey" FOREIGN KEY ("requester_id") REFERENCES "profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "change_request" ADD CONSTRAINT "change_request_resolved_by_id_fkey" FOREIGN KEY ("resolved_by_id") REFERENCES "profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notification" ADD CONSTRAINT "notification_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notification" ADD CONSTRAINT "notification_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_log" ADD CONSTRAINT "audit_log_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "space"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_log" ADD CONSTRAINT "audit_log_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
