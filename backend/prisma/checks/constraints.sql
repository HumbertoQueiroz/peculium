-- Sanity checks for the SQL migrations. Run after applying them to an empty database:
--   psql -h localhost -p <port> -U postgres -d <database> -f backend/prisma/checks/constraints.sql
-- Works on plain PostgreSQL and on a Supabase-like one (auth.users and the anon and authenticated roles).
-- Each check prints PASS or FAIL; the last line shows the totals.

\set ON_ERROR_STOP on
\pset tuples_only on

CREATE TEMP TABLE results (ok boolean, label text);

CREATE FUNCTION pg_temp.expect_fail(label text, stmt text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE stmt;
    INSERT INTO results VALUES (false, label || ' (should have failed)');
  EXCEPTION WHEN OTHERS THEN
    INSERT INTO results VALUES (true, label || ' -> ' || SQLERRM);
  END;
END $$;

CREATE FUNCTION pg_temp.expect_ok(label text, stmt text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE stmt;
    INSERT INTO results VALUES (true, label);
  EXCEPTION WHEN OTHERS THEN
    INSERT INTO results VALUES (false, label || ' (should have worked): ' || SQLERRM);
  END;
END $$;

-- Fixtures
DO $$
DECLARE
  uid uuid := '11111111-1111-1111-1111-111111111111';
BEGIN
  IF to_regclass('auth.users') IS NOT NULL THEN
    INSERT INTO auth.users (id) VALUES (uid);
  END IF;
  INSERT INTO profile (id, name) VALUES (uid, 'Test');
  INSERT INTO space (id, name, timezone, currency)
    VALUES ('22222222-2222-2222-2222-222222222222', 'Home', 'America/Cuiaba', 'BRL');
  INSERT INTO participant (id, space_id, name, user_id)
    VALUES ('33333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222', 'Test', uid);
END $$;

SELECT pg_temp.expect_fail('invalid timezone',
  $$INSERT INTO space (name, timezone) VALUES ('x', 'Mars/Olympus')$$);
SELECT pg_temp.expect_fail('timezone as fixed offset',
  $$INSERT INTO space (name, timezone) VALUES ('x', '-04:00')$$);
SELECT pg_temp.expect_ok('valid timezone',
  $$INSERT INTO space (name, timezone, currency) VALUES ('x', 'Europe/Lisbon', 'EUR')$$);
SELECT pg_temp.expect_fail('currency format',
  $$INSERT INTO space (name, currency) VALUES ('x', 'real')$$);
SELECT pg_temp.expect_fail('closing day out of range',
  $$INSERT INTO space (name, closing_day) VALUES ('x', 31)$$);

-- Currency can change while the space is empty, and not after the first bill
SELECT pg_temp.expect_ok('currency change on empty space',
  $$UPDATE space SET currency = 'USD' WHERE id = '22222222-2222-2222-2222-222222222222'$$);
SELECT pg_temp.expect_ok('currency back to BRL',
  $$UPDATE space SET currency = 'BRL' WHERE id = '22222222-2222-2222-2222-222222222222'$$);

SELECT pg_temp.expect_ok('valid open bill', $$
  INSERT INTO bill (id, space_id, nature, original_description, normalized_description, original_amount,
                    balance, status, accrual_date, due_date, buyer_id, created_by_id)
  VALUES ('44444444-4444-4444-4444-444444444444', '22222222-2222-2222-2222-222222222222', 'PAYABLE',
          'Distribuidora', 'DISTRIBUIDORA', 10000, 10000, 'OPEN', '2026-11-01', '2026-11-10',
          '33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111')$$);
SELECT pg_temp.expect_fail('currency locked after a bill',
  $$UPDATE space SET currency = 'EUR' WHERE id = '22222222-2222-2222-2222-222222222222'$$);
SELECT pg_temp.expect_fail('paid bill with balance left', $$
  UPDATE bill SET status = 'PAID' WHERE id = '44444444-4444-4444-4444-444444444444'$$);
SELECT pg_temp.expect_fail('balance above original', $$
  UPDATE bill SET balance = 20000 WHERE id = '44444444-4444-4444-4444-444444444444'$$);
SELECT pg_temp.expect_fail('zero amount bill', $$
  INSERT INTO bill (space_id, nature, original_description, normalized_description, original_amount, balance,
                    accrual_date, due_date, buyer_id, created_by_id)
  VALUES ('22222222-2222-2222-2222-222222222222', 'PAYABLE', 'x', 'X', 0, 0, '2026-11-01', '2026-11-10',
          '33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111')$$);
SELECT pg_temp.expect_fail('installment number without plan', $$
  UPDATE bill SET installment_number = 1 WHERE id = '44444444-4444-4444-4444-444444444444'$$);

SELECT pg_temp.expect_fail('settlement formula', $$
  INSERT INTO settlement (space_id, bill_id, reason, date, amortized_amount, interest, penalty, discount,
                          moved_amount, created_by_id)
  VALUES ('22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444444', 'PAYMENT',
          '2026-11-10', 10000, 100, 0, 0, 10000, '11111111-1111-1111-1111-111111111111')$$);
SELECT pg_temp.expect_ok('settlement with interest and discount', $$
  INSERT INTO settlement (id, space_id, bill_id, reason, date, amortized_amount, interest, penalty, discount,
                          moved_amount, created_by_id)
  VALUES ('55555555-5555-5555-5555-555555555555', '22222222-2222-2222-2222-222222222222',
          '44444444-4444-4444-4444-444444444444', 'PAYMENT', '2026-11-10', 10000, 200, 100, 500, 9800,
          '11111111-1111-1111-1111-111111111111')$$);

SELECT pg_temp.expect_ok('account', $$
  INSERT INTO account (id, space_id, name, type) VALUES
  ('66666666-6666-6666-6666-666666666666', '22222222-2222-2222-2222-222222222222', 'Checking', 'CHECKING')$$);
SELECT pg_temp.expect_fail('transfer movement without transfer id', $$
  INSERT INTO account_movement (space_id, account_id, date, direction, amount, origin, description, created_by_id)
  VALUES ('22222222-2222-2222-2222-222222222222', '66666666-6666-6666-6666-666666666666', '2026-11-10',
          'OUTFLOW', 100, 'TRANSFER', 'x', '11111111-1111-1111-1111-111111111111')$$);
SELECT pg_temp.expect_ok('settlement movement', $$
  INSERT INTO account_movement (space_id, account_id, date, direction, amount, origin, settlement_id,
                                description, created_by_id)
  VALUES ('22222222-2222-2222-2222-222222222222', '66666666-6666-6666-6666-666666666666', '2026-11-10',
          'OUTFLOW', 9800, 'SETTLEMENT', '55555555-5555-5555-5555-555555555555', 'x',
          '11111111-1111-1111-1111-111111111111')$$);

-- Category tree
SELECT pg_temp.expect_ok('root category', $$
  INSERT INTO category (id, space_id, name, kind) VALUES
  ('77777777-7777-7777-7777-777777777771', '22222222-2222-2222-2222-222222222222', 'Housing', 'EXPENSE')$$);
SELECT pg_temp.expect_ok('child category', $$
  INSERT INTO category (id, space_id, name, kind, parent_id) VALUES
  ('77777777-7777-7777-7777-777777777772', '22222222-2222-2222-2222-222222222222', 'Rent', 'EXPENSE',
   '77777777-7777-7777-7777-777777777771')$$);
SELECT pg_temp.expect_fail('third category level', $$
  INSERT INTO category (space_id, name, kind, parent_id) VALUES
  ('22222222-2222-2222-2222-222222222222', 'Deep', 'EXPENSE', '77777777-7777-7777-7777-777777777772')$$);

-- Plans
SELECT pg_temp.expect_fail('plan with 121 repetitions', $$
  INSERT INTO installment_plan (space_id, kind, description, normalized_description, total_amount,
                                installment_count, purchase_date, created_by_id)
  VALUES ('22222222-2222-2222-2222-222222222222', 'RECURRING', 'x', 'X', 1000, 121, '2026-11-01',
          '11111111-1111-1111-1111-111111111111')$$);
SELECT pg_temp.expect_ok('plan with 12 repetitions', $$
  INSERT INTO installment_plan (space_id, kind, description, normalized_description, total_amount,
                                installment_count, purchase_date, created_by_id)
  VALUES ('22222222-2222-2222-2222-222222222222', 'RECURRING', 'Rent', 'RENT', 120000, 12, '2026-11-01',
          '11111111-1111-1111-1111-111111111111')$$);

-- Audit log is insert only
SELECT pg_temp.expect_ok('audit insert', $$
  INSERT INTO audit_log (id, space_id, entity, entity_id, action, changes, origin, correlation_id)
  VALUES ('88888888-8888-8888-8888-888888888888', '22222222-2222-2222-2222-222222222222', 'bill',
          '44444444-4444-4444-4444-444444444444', 'CREATE', '{}', 'USER', gen_random_uuid())$$);
SELECT pg_temp.expect_fail('audit update', $$UPDATE audit_log SET action = 'X'$$);
SELECT pg_temp.expect_fail('audit delete', $$DELETE FROM audit_log$$);
SELECT pg_temp.expect_fail('audit truncate', $$TRUNCATE audit_log$$);

-- Display view precedence: supplier nickname applies to the old bill
SELECT pg_temp.expect_ok('supplier nickname', $$
  INSERT INTO description_nickname (space_id, normalized_description, nickname, created_by_id)
  VALUES ('22222222-2222-2222-2222-222222222222', 'DISTRIBUIDORA', 'Distribuidora Amarelinha',
          '11111111-1111-1111-1111-111111111111')$$);
DO $$
DECLARE shown text;
BEGIN
  SELECT display_description INTO shown FROM bill_display WHERE id = '44444444-4444-4444-4444-444444444444';
  INSERT INTO results VALUES (shown = 'Distribuidora Amarelinha', 'view shows supplier nickname: ' || shown);
  UPDATE bill SET nickname = 'My nickname' WHERE id = '44444444-4444-4444-4444-444444444444';
  SELECT display_description INTO shown FROM bill_display WHERE id = '44444444-4444-4444-4444-444444444444';
  INSERT INTO results VALUES (shown = 'My nickname', 'view prefers bill nickname: ' || shown);
END $$;

-- Profile FK exists only where Supabase Auth does
DO $$
BEGIN
  IF to_regclass('auth.users') IS NOT NULL THEN
    PERFORM pg_temp.expect_fail('profile without auth user',
      $q$INSERT INTO profile (id, name) VALUES (gen_random_uuid(), 'ghost')$q$);
  ELSE
    PERFORM pg_temp.expect_ok('profile without auth schema',
      $q$INSERT INTO profile (id, name) VALUES (gen_random_uuid(), 'ghost')$q$);
  END IF;
END $$;

-- RLS denies the API roles
DO $$
DECLARE denied boolean;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    SET LOCAL ROLE authenticated;
    BEGIN
      PERFORM 1 FROM bill LIMIT 1;
      denied := false;
    EXCEPTION WHEN insufficient_privilege THEN
      denied := true;
    END;
    RESET ROLE;
    INSERT INTO results VALUES (denied, 'authenticated role cannot read bill');
  END IF;
END $$;

SELECT CASE WHEN ok THEN 'PASS ' ELSE 'FAIL ' END || label FROM results ORDER BY ok, label;
SELECT 'total ' || count(*) || ', failed ' || count(*) FILTER (WHERE NOT ok) FROM results;
