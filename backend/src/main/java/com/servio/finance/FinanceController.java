package com.servio.finance;
import com.servio.common.dto.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/admin/finance")
@PreAuthorize("hasAuthority('ADMIN')")
@RequiredArgsConstructor
public class FinanceController {
    private final InvoiceService billing;
    private final PayrollService payroll;
    private final FinanceStore db;
    private ApiResponse<Object> ok(Object value) { return ApiResponse.success("Success",value); }
    @PostMapping("/jobs") public Object createJob(@Valid @RequestBody FinanceRequests.Job r,Authentication a) { return ok(billing.createJob(r,a.getName())); }
    @GetMapping("/jobs") public Object jobs() { return ok(billing.jobs()); }
    @GetMapping("/jobs/{id}/charges") public Object charges(@PathVariable long id) { return ok(billing.charges(id)); }
    @PostMapping("/charges") public Object charge(@Valid @RequestBody FinanceRequests.Charge r,Authentication a) { return ok(billing.charge(r,a.getName())); }
    @PostMapping("/charges/{id}/reverse") public Object reverse(@PathVariable long id,Authentication a) { billing.reverseCharge(id,a.getName()); return ok(null); }
    @GetMapping("/invoices") public Object invoices() { return ok(billing.invoices()); }
    @PostMapping("/invoices") public Object draft(@Valid @RequestBody FinanceRequests.Draft r,Authentication a) { return ok(billing.draft(r,a.getName())); }
    @GetMapping("/invoices/{id}") public Object invoice(@PathVariable long id) { return ok(billing.invoice(id)); }
    @PostMapping("/invoices/{id}/issue") public Object issue(@PathVariable long id,Authentication a) { return ok(billing.issue(id,a.getName())); }
    @PostMapping("/invoices/{id}/allocate") public Object allocate(@PathVariable long id,Authentication a) { return ok(billing.allocate(id,a.getName())); }
    @PostMapping("/invoices/{id}/payments") public Object collect(@PathVariable long id,@Valid @RequestBody FinanceRequests.Collection r,Authentication a) { return ok(billing.collect(id,r,a.getName())); }
    @PostMapping("/invoices/{id}/refunds") public Object refund(@PathVariable long id,@Valid @RequestBody FinanceRequests.Refund r,Authentication a) { return ok(billing.refund(id,r,a.getName())); }
    @PostMapping("/invoices/{id}/void") public Object voidInvoice(@PathVariable long id,@Valid @RequestBody FinanceRequests.Reason r,Authentication a) { return ok(billing.voidInvoice(id,r.reason(),a.getName())); }
    @GetMapping("/booking-payments") public Object bookingPayments() { return ok(billing.bookingPayments()); }
    @PostMapping("/booking-payments/{id}/refunds") public Object refundAdvance(@PathVariable long id,@Valid @RequestBody FinanceRequests.Refund r,Authentication a) { billing.refundAdvance(id,r,a.getName()); return ok(null); }
    @GetMapping("/mechanics") public Object mechanics() { return ok(payroll.mechanics()); }
    @GetMapping("/agreements") public Object agreements() { return ok(payroll.agreements()); }
    @PostMapping("/agreements") public Object agreement(@Valid @RequestBody FinanceRequests.Agreement r,Authentication a) { return ok(payroll.agreement(r,a.getName())); }
    @GetMapping("/attendance") public Object attendance(@RequestParam String month) { return ok(payroll.attendance(month)); }
    @PostMapping("/attendance") public Object attendance(@Valid @RequestBody FinanceRequests.Attendance r,Authentication a) { return ok(payroll.attendance(r,a.getName())); }
    @PostMapping("/attendance/batch") public Object attendanceBatch(@Valid @RequestBody FinanceRequests.AttendanceBatch r,Authentication a) { payroll.attendanceBatch(r,a.getName()); return ok(null); }
    @GetMapping("/advances") public Object advances() { return ok(payroll.advances()); }
    @PostMapping("/advances") public Object advance(@Valid @RequestBody FinanceRequests.Advance r,Authentication a) { return ok(payroll.advance(r,a.getName())); }
    @GetMapping("/payroll") public Object runs() { return ok(payroll.runs()); }
    @PostMapping("/payroll") public Object generate(@Valid @RequestBody FinanceRequests.Month r,Authentication a) { return ok(payroll.generate(r.month(),a.getName())); }
    @GetMapping("/payroll/{id}") public Object run(@PathVariable long id) { return ok(payroll.run(id)); }
    @PostMapping("/payroll/{id}/approve") public Object approve(@PathVariable long id,Authentication a) { return ok(payroll.approve(id,a.getName())); }
    @PostMapping("/payroll-items/{id}/adjust") public Object adjust(@PathVariable long id,@Valid @RequestBody FinanceRequests.Adjustment r,Authentication a) { return ok(payroll.adjust(id,r,a.getName())); }
    @PostMapping("/payroll-items/{id}/payments") public Object pay(@PathVariable long id,@Valid @RequestBody FinanceRequests.SalaryPayment r,Authentication a) { return ok(payroll.pay(id,r,a.getName())); }
    @GetMapping("/payroll-items/{id}/payslip") public Object payslip(@PathVariable long id) { return ok(payroll.payslip(id)); }
    @GetMapping("/summary") public Object summary(@RequestParam String month) {
        var start=java.time.YearMonth.parse(month).atDay(1); var end=start.plusMonths(1);
        return ok(Map.of(
            "invoiced",db.amount("SELECT COALESCE(SUM(net_total),0) FROM billing_invoices WHERE status='ISSUED' AND issued_at>=? AND issued_at<?",start,end),
            "collected",db.amount("SELECT COALESCE(SUM(amount),0) FROM payments WHERE payment_status='COMPLETED' AND currency='LKR' AND payment_date>=? AND payment_date<?",start,end),
            "refunded",db.amount("SELECT COALESCE(SUM(amount),0) FROM billing_refunds WHERE created_at>=? AND created_at<?",start,end),
            "salaries_approved",db.amount("SELECT COALESCE(SUM(i.net_payable),0) FROM payroll_items i JOIN payroll_runs r ON r.id=i.run_id WHERE r.payroll_month=? AND r.status<>'DRAFT'",start),
            "salaries_paid",db.amount("SELECT COALESCE(SUM(amount),0) FROM salary_payments WHERE paid_at>=? AND paid_at<?",start,end),
            "advances_paid",db.amount("SELECT COALESCE(SUM(amount),0) FROM salary_advances WHERE paid_date>=? AND paid_date<?",start,end)));
    }
}
