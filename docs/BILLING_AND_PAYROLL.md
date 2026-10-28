# Billing and mechanic payroll

Servio keeps financial calculations in the Spring Boot backend and stores financial records in PostgreSQL. React administers billing and payroll; it does not determine authoritative totals. All `/api/admin/finance` endpoints require ADMIN authority.

## Setup

Run the backend against the configured database. Flyway applies `V31__billing_and_monthly_payroll.sql` and the forward completion migration `V32__complete_billing_payroll_schema.sql` on startup. V32 also completes databases that already applied an earlier V31. This migration preserves existing invoices, adds links and payment allocations, and creates payroll records. It does not infer historical payments from the old CASH/CARD label. Reconcile historical invoice payment evidence before collecting any historical balance.

The migration enables RLS on financial tables and revokes public Supabase client access. The backend must connect as the migration/table owner or a properly configured backend role with RLS access. Financial clients use backend APIs, not Supabase table APIs.

An active Supabase database connection is required to use the screens. Builds and regression tests use local test databases and do not apply migrations to the live database.

## Billing workflow

1. Open Billing and select an appointment, or choose a previously registered walk-in customer and service package. Create/open its job card. Existing appointment jobs are reused.
2. Add the job's service package. Its price comes from the job card's recorded service cost. There is no separate manual labour/service-charge option. Package cost must exclude parts you intend to bill separately.
3. Issue inventory parts with quantities. The server snapshots selling prices, deducts stock, and records movements. Returning a charge restores the stock once.
4. Enter a fixed invoice discount and save a draft. The backend computes quantity times rate, subtotal, discount, and total.
5. Issue the invoice. Its item descriptions and prices become immutable. Issuing never consumes stock again. One live invoice is allowed per appointment/job.
6. Available completed appointment payments are allocated up to the invoice total. Excess booking money remains unallocated; it is not counted twice. Late payment events also allocate within the payment transaction.
7. Record remaining cash, external card-terminal, or bank-transfer payments with references after receiving the funds. Partial and split payments are supported. Download the invoice and payment history as PDF.
8. Refund money through the actual payment channel first, then record its amount, reason, original payment, and reference. This action records a completed refund; it does not send money through PayHere. Refunds cannot exceed the original allocated amount.
Unallocated advances and late payments on cancelled bookings can be refunded from the Booking advances panel, without creating an invoice. Refunded advance money is excluded from future allocations.

9. An invoice can be voided only after its allocated money is refunded. Voiding does not automatically return parts: return job charges separately when parts are physically returned.

Invoice lifecycle: DRAFT, ISSUED, VOID. Settlement is derived from total and net allocated payments: UNPAID, PARTIALLY_PAID, PAID.

### Booking and PayHere

Booking prices come from catalog services, options, and valid offers. Incoming estimatedCost is ignored at the public booking API. Older clients can identify a service by name; option and promo IDs/codes are needed to price those selections. Zero-value bookings bypass card checkout.

PayHere checkout stores a unique payment-attempt order reference with an immutable expected amount and LKR currency. The verified server notification supplies the payment confirmation. Browser callbacks do not create completed payments. Duplicate gateway transaction IDs are ignored. A late payment is recorded without reviving a cancelled appointment or undoing admin approval. Checkout holds expire ten minutes after the latest attempt was created.

After upgrading, restart any checkout opened before this migration so it receives a stored payment-attempt reference.

The existing appointment Collect Cash button records a booking advance when there is no issued invoice. When an issued invoice exists, it settles that invoice. It rejects excess amounts and duplicate request keys. Receiving an advance does not set the final job cost; issuing an invoice records its final amount.

## Monthly mechanic payroll

Open Payroll. Salaries do not depend on customer invoices, job counts, or service charges.

1. Select each mechanic and save a salary agreement effective from the first day of a month. Configure basic salary, monthly allowances, hourly overtime rate, and the agreed unpaid-leave divisor.
2. Record daily attendance as PRESENT, PAID_LEAVE, UNPAID_LEAVE, or OFF. Overtime requires PRESENT attendance. Approve the reviewed entries. Bulk fill is a convenience for explicitly reviewed records; it does not infer attendance.
3. Record already-paid salary advances with their payment dates and references.
4. Select the month and generate draft payroll. Every currently active mechanic needs a salary agreement effective for that month. Generation snapshots salary rates and approved attendance. Regenerating a draft resets its adjustments.
5. Enter advance recoveries and other approved deductions with reasons. Recovery is limited to advances paid by the month's end and not previously recovered.
6. Approve after the month is complete. Every calendar day, including off days, must have approved attendance. If attendance or agreements changed since draft generation, regenerate before approval. Approval freezes the breakdown and records advance recovery once.
7. Record actual CASH or BANK_TRANSFER salary payments with references. Partial payments are supported; overpayments and duplicate request keys are rejected. A run closes when all salary balances are zero.
8. Download approved payslips with salary breakdowns and payment history.

```
Overtime pay = approved overtime hours * agreed hourly rate
Unpaid leave deduction = basic salary * approved unpaid days / agreed divisor
Gross salary = basic salary + allowances + overtime pay
Net payable = gross salary - unpaid leave deduction - advance recovery - approved deductions
```

Unpaid leave deductions are capped at basic salary. Paid leave does not reduce salary. Calculations use BigDecimal and HALF_UP rounding to two decimal places. Payroll attendance date checks use Asia/Colombo.

This version uses full-month agreements. It does not automatically prorate joining/termination months, calculate statutory contributions, assume tax rates, or send bank transfers. Those policies require explicit configuration before automation. Administrators can enter approved deductions with reasons.

## Monthly reporting

The Payroll page distinguishes issued invoice totals, customer collections, recorded refunds, approved net salaries, actual salary payments, and salary advances. Collection/payment figures use the month money moved; payroll approvals use their payroll month. Advances remain separate to avoid counting recovery as a second cash expense. These are operational cash and salary reports, not a full general ledger or tax return.

## Backend structure

- `finance/InvoiceService`: job charges, invoice snapshots, allocation, collection, refund, and void rules.
- `finance/PayrollService`: effective agreements, attendance, advances, monthly calculation, approval, and payouts.
- `finance/BookingPricingService`: trusted booking prices and discounts.
- `finance/PaymentAttemptService`: checkout snapshots and confirmation validation.
- `finance/FinanceStore`: parameterized SQL repository and transactional audit history.
- `finance/Money`: shared decimal calculations and financial validation.
- `finance/PaymentAllocationListener`: flushes recorded payments and applies them before commit.

Controllers return the existing ApiResponse envelope. Finance response fields use database-style snake_case. Commands use camelCase and idempotency request keys. Frontend clients retain keys through ambiguous network failures and clear them only after success.

Existing `/api/admin/bills` routes now read the connected invoice records. POST creates a job-linked draft with `{jobCardId, discount, requestKey}`; old standalone customer/item payloads are no longer accepted.

## Verification

```
cd backend
mvn test

cd ../frontend
npm run build
npx eslint src/pages/admin/Billing.tsx src/pages/admin/Payroll.tsx src/pages/admin/FinanceComponents.tsx src/services/financeApi.ts src/services/financeForm.ts src/services/billingApi.ts
```

Financial tests exercise SQL accounting against H2 in PostgreSQL mode, including allocations, retries, refunds, payroll approval, attendance drift, advances, and payments. PostgreSQL advisory locks are represented by test helpers. Migration V32 and all nine read-only admin finance endpoints were also verified against the configured PostgreSQL environment; unauthenticated payroll access returned HTTP 401. Concurrent PostgreSQL write scenarios are not covered by the local H2 tests.
