package com.servio.finance;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import static com.servio.finance.FinanceStore.*;

@Service
@RequiredArgsConstructor
@Transactional
public class PayrollService {
    private final FinanceStore db;
    private LocalDate month(String value) { return YearMonth.parse(value).atDay(1); }
    private void monthLock(LocalDate date) {
        db.rows("SELECT pg_advisory_xact_lock(hashtext(?))","payroll-"+date.withDayOfMonth(1));
    }
    private void mechanicLock(long mechanicId) { db.one("SELECT id FROM mechanics WHERE id=? FOR UPDATE",mechanicId); }
    private void editableMonth(LocalDate date) {
        monthLock(date);
        if(!db.rows("SELECT id FROM payroll_runs WHERE payroll_month=? AND status<>'DRAFT'",date.withDayOfMonth(1)).isEmpty())
            throw new IllegalStateException("Approved payroll and its attendance cannot be changed");
    }
    public List<Map<String,Object>> mechanics() {
        return db.rows("SELECT id,full_name,email,is_active FROM mechanics ORDER BY full_name");
    }
    public List<Map<String,Object>> agreements() {
        return db.rows("SELECT a.*,m.full_name FROM mechanic_salary_agreements a JOIN mechanics m ON m.id=a.mechanic_id ORDER BY a.effective_from DESC,a.id DESC");
    }
    public Map<String,Object> agreement(FinanceRequests.Agreement r,String actor) {
        mechanicLock(r.mechanicId());
        if(r.effectiveFrom().getDayOfMonth()!=1) throw new IllegalArgumentException("Salary agreements must start on the first day of a month");
        if(!db.rows("SELECT p.id FROM payroll_items p JOIN payroll_runs r ON r.id=p.run_id WHERE p.mechanic_id=? AND r.payroll_month>=? AND r.status<>'DRAFT'",r.mechanicId(),r.effectiveFrom()).isEmpty())
            throw new IllegalStateException("Cannot change salary agreements affecting approved payroll");
        long id=db.insert("INSERT INTO mechanic_salary_agreements(mechanic_id,effective_from,basic_salary,allowances,overtime_rate,leave_divisor,created_by) VALUES(?,?,?,?,?,?,?) RETURNING id",
            r.mechanicId(),r.effectiveFrom(),Money.nonNegative(r.basicSalary(),"Salary"),Money.nonNegative(r.allowances(),"Allowances"),Money.nonNegative(r.overtimeRate(),"Overtime rate"),Money.positive(r.leaveDivisor(),"Leave divisor"),actor);
        db.audit("AGREEMENT",id,"CREATE",actor,"Effective "+r.effectiveFrom());
        return db.one("SELECT * FROM mechanic_salary_agreements WHERE id=?",id);
    }
    public List<Map<String,Object>> attendance(String month) {
        LocalDate start=month(month);
        return db.rows("SELECT a.*,m.full_name FROM mechanic_attendance a JOIN mechanics m ON m.id=a.mechanic_id WHERE work_date>=? AND work_date<? ORDER BY work_date,m.full_name",start,start.plusMonths(1));
    }
    public Map<String,Object> attendance(FinanceRequests.Attendance r,String actor) {
        editableMonth(r.workDate()); mechanicLock(r.mechanicId());
        if(r.workDate().isAfter(LocalDate.now(java.time.ZoneId.of("Asia/Colombo")))) throw new IllegalArgumentException("Cannot approve future attendance");
        if(!"PRESENT".equals(r.status()) && r.overtimeHours().signum()>0) throw new IllegalArgumentException("Overtime requires present attendance");
        long id=db.insert("INSERT INTO mechanic_attendance(mechanic_id,work_date,status,overtime_hours,approved,recorded_by) VALUES(?,?,?,?,?,?) ON CONFLICT(mechanic_id,work_date) DO UPDATE SET status=EXCLUDED.status,overtime_hours=EXCLUDED.overtime_hours,approved=EXCLUDED.approved,recorded_by=EXCLUDED.recorded_by RETURNING id",
            r.mechanicId(),r.workDate(),r.status(),r.overtimeHours(),r.approved(),actor);
        db.audit("ATTENDANCE",id,"UPDATE",actor,r.workDate()+" "+r.status());
        return db.one("SELECT * FROM mechanic_attendance WHERE id=?",id);
    }
    public void attendanceBatch(FinanceRequests.AttendanceBatch r,String actor) {
        if(r.entries().size()>31) throw new IllegalArgumentException("Save one mechanic month at a time");
        var first=r.entries().get(0);
        for(var entry:r.entries()) {
            if(!entry.mechanicId().equals(first.mechanicId()) || !entry.workDate().withDayOfMonth(1).equals(first.workDate().withDayOfMonth(1)))
                throw new IllegalArgumentException("Attendance batch must belong to one mechanic and month");
        }
        for(var entry:r.entries()) attendance(entry,actor);
    }
    public List<Map<String,Object>> advances() {
        return db.rows("SELECT a.*,m.full_name,a.amount-COALESCE(r.recovered,0) AS remaining FROM salary_advances a JOIN mechanics m ON m.id=a.mechanic_id LEFT JOIN (SELECT advance_id,SUM(amount) recovered FROM salary_advance_recoveries GROUP BY advance_id) r ON r.advance_id=a.id ORDER BY a.paid_date DESC,a.id DESC");
    }
    public Map<String,Object> advance(FinanceRequests.Advance r,String actor) {
        mechanicLock(r.mechanicId());
        var old=db.rows("SELECT * FROM salary_advances WHERE request_key=?",r.requestKey());
        if(!old.isEmpty()) {
            if(id(old.get(0),"mechanic_id")!=r.mechanicId() || decimal(old.get(0),"amount").compareTo(r.amount())!=0)
                throw new IllegalArgumentException("Advance request key was already used with different details");
            return old.get(0);
        }
        if(r.paidDate().isAfter(LocalDate.now(java.time.ZoneId.of("Asia/Colombo")))) throw new IllegalArgumentException("Advance payment date cannot be in the future");
        long id=db.insert("INSERT INTO salary_advances(mechanic_id,amount,paid_date,reference,request_key,recorded_by) VALUES(?,?,?,?,?,?) RETURNING id",r.mechanicId(),Money.positive(r.amount(),"Advance"),r.paidDate(),r.reference(),r.requestKey(),actor);
        db.audit("ADVANCE",id,"PAY",actor,r.amount()+" "+r.reference()); return db.one("SELECT * FROM salary_advances WHERE id=?",id);
    }
    public List<Map<String,Object>> runs() { return db.rows("SELECT * FROM payroll_runs ORDER BY payroll_month DESC"); }
    public Map<String,Object> run(long runId) {
        var r=db.one("SELECT * FROM payroll_runs WHERE id=?",runId);
        r.put("items",db.rows("SELECT i.*,COALESCE(p.paid,0) AS paid_amount,i.net_payable-COALESCE(p.paid,0) AS balance_due FROM payroll_items i LEFT JOIN (SELECT payroll_item_id,SUM(amount) paid FROM salary_payments GROUP BY payroll_item_id) p ON p.payroll_item_id=i.id WHERE i.run_id=? ORDER BY i.mechanic_name",runId));
        return r;
    }
    public Map<String,Object> generate(String value,String actor) {
        LocalDate start=month(value); editableMonth(start);
        var mechanics=db.rows("SELECT id,full_name FROM mechanics WHERE is_active=true ORDER BY id FOR UPDATE");
        if(mechanics.isEmpty()) throw new IllegalArgumentException("No active mechanics");
        var old=db.rows("SELECT id FROM payroll_runs WHERE payroll_month=?",start);
        long runId=old.isEmpty() ? db.insert("INSERT INTO payroll_runs(payroll_month,created_by) VALUES(?,?) RETURNING id",start,actor) : id(old.get(0),"id");
        db.update("DELETE FROM payroll_items WHERE run_id=?",runId);
        for(var m:mechanics) {
            var contracts=db.rows("SELECT * FROM mechanic_salary_agreements WHERE mechanic_id=? AND effective_from<=? ORDER BY effective_from DESC LIMIT 1",m.get("id"),start);
            if(contracts.isEmpty()) throw new IllegalArgumentException("Missing salary agreement for "+m.get("full_name")+" in "+value);
            var a=contracts.get(0);
            var attendance=db.one("SELECT COALESCE(SUM(CASE WHEN approved THEN overtime_hours ELSE 0 END),0) AS hours,COUNT(*) FILTER (WHERE status='UNPAID_LEAVE' AND approved) AS unpaid FROM mechanic_attendance WHERE mechanic_id=? AND work_date>=? AND work_date<?",m.get("id"),start,start.plusMonths(1));
            var salary=Money.salary(decimal(a,"basic_salary"),decimal(a,"allowances"),decimal(attendance,"hours"),decimal(a,"overtime_rate"),decimal(attendance,"unpaid"),decimal(a,"leave_divisor"),BigDecimal.ZERO,BigDecimal.ZERO);
            db.update("INSERT INTO payroll_items(run_id,mechanic_id,mechanic_name,agreement_id,basic_salary,allowances,overtime_hours,overtime_rate,overtime_pay,unpaid_days,leave_divisor,leave_deduction,gross_salary,net_payable) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                runId,m.get("id"),m.get("full_name"),a.get("id"),a.get("basic_salary"),a.get("allowances"),attendance.get("hours"),a.get("overtime_rate"),salary.overtimePay(),attendance.get("unpaid"),a.get("leave_divisor"),salary.leaveDeduction(),salary.gross(),salary.net());
        }
        db.audit("PAYROLL",runId,"GENERATE",actor,"Monthly salary snapshots; draft adjustments reset"); return run(runId);
    }
    private BigDecimal availableAdvance(long mechanicId,LocalDate cutoff) {
        return db.amount("SELECT COALESCE(SUM(a.amount-COALESCE(r.recovered,0)),0) FROM salary_advances a LEFT JOIN (SELECT advance_id,SUM(amount) recovered FROM salary_advance_recoveries GROUP BY advance_id) r ON r.advance_id=a.id WHERE a.mechanic_id=? AND a.paid_date<?",mechanicId,cutoff);
    }
    public Map<String,Object> adjust(long itemId,FinanceRequests.Adjustment r,String actor) {
        var i=db.one("SELECT * FROM payroll_items WHERE id=?",itemId);
        var run=db.one("SELECT * FROM payroll_runs WHERE id=?",i.get("run_id"));
        LocalDate start=((java.sql.Date)run.get("payroll_month")).toLocalDate();
        editableMonth(start); mechanicLock(id(i,"mechanic_id"));
        i=db.one("SELECT * FROM payroll_items WHERE id=? FOR UPDATE",itemId);
        if(r.advanceRecovery().compareTo(availableAdvance(id(i,"mechanic_id"),start.plusMonths(1)))>0) throw new IllegalArgumentException("Recovery exceeds available advances for this month");
        var salary=Money.salary(decimal(i,"basic_salary"),decimal(i,"allowances"),decimal(i,"overtime_hours"),decimal(i,"overtime_rate"),decimal(i,"unpaid_days"),decimal(i,"leave_divisor"),r.advanceRecovery(),r.otherDeduction());
        db.update("UPDATE payroll_items SET advance_recovery=?,other_deduction=?,adjustment_reason=?,net_payable=? WHERE id=?",Money.nonNegative(r.advanceRecovery(),"Recovery"),Money.nonNegative(r.otherDeduction(),"Deduction"),r.reason(),salary.net(),itemId);
        db.audit("PAYROLL_ITEM",itemId,"ADJUST",actor,r.reason()); return run(id(i,"run_id"));
    }
    public Map<String,Object> approve(long runId,String actor) {
        var run=db.one("SELECT * FROM payroll_runs WHERE id=?",runId);
        LocalDate start=((java.sql.Date)run.get("payroll_month")).toLocalDate();
        monthLock(start); run=db.one("SELECT * FROM payroll_runs WHERE id=? FOR UPDATE",runId);
        if(!"DRAFT".equals(run.get("status"))) return run(runId);
        if(start.plusMonths(1).minusDays(1).isAfter(LocalDate.now(java.time.ZoneId.of("Asia/Colombo")))) throw new IllegalStateException("Approve payroll only after the month's attendance is complete");
        var items=db.rows("SELECT * FROM payroll_items WHERE run_id=? ORDER BY mechanic_id FOR UPDATE",runId);
        if(items.isEmpty()) throw new IllegalStateException("Payroll has no items");
        for(var i:items) {
            long mechanicId=id(i,"mechanic_id"); mechanicLock(mechanicId);
            var attendance=db.one("SELECT COUNT(*) AS days,COALESCE(SUM(overtime_hours),0) AS hours,COUNT(*) FILTER (WHERE status='UNPAID_LEAVE') AS unpaid FROM mechanic_attendance WHERE mechanic_id=? AND work_date>=? AND work_date<? AND approved=true",mechanicId,start,start.plusMonths(1));
            if(((Number)attendance.get("days")).intValue()!=YearMonth.from(start).lengthOfMonth()) throw new IllegalStateException("Record and approve every calendar day, including off days, for "+i.get("mechanic_name"));
            var a=db.one("SELECT * FROM mechanic_salary_agreements WHERE mechanic_id=? AND effective_from<=? ORDER BY effective_from DESC LIMIT 1",mechanicId,start);
            if(id(a,"id")!=id(i,"agreement_id") || decimal(attendance,"hours").compareTo(decimal(i,"overtime_hours"))!=0 || decimal(attendance,"unpaid").compareTo(decimal(i,"unpaid_days"))!=0)
                throw new IllegalStateException("Attendance or salary changed; regenerate draft payroll before approval");
            BigDecimal remaining=decimal(i,"advance_recovery");
            if(remaining.compareTo(availableAdvance(mechanicId,start.plusMonths(1)))>0) throw new IllegalStateException("Advance balance changed; adjust payroll before approval");
            for(var advance:db.rows("SELECT * FROM salary_advances WHERE mechanic_id=? AND paid_date<? ORDER BY paid_date,id FOR UPDATE",mechanicId,start.plusMonths(1))) {
                BigDecimal recovered=db.amount("SELECT COALESCE(SUM(amount),0) FROM salary_advance_recoveries WHERE advance_id=?",advance.get("id"));
                BigDecimal amount=decimal(advance,"amount").subtract(recovered).min(remaining);
                if(amount.signum()>0) { db.update("INSERT INTO salary_advance_recoveries(advance_id,payroll_item_id,amount) VALUES(?,?,?)",advance.get("id"),i.get("id"),amount); remaining=remaining.subtract(amount); }
            }
        }
        db.update("UPDATE payroll_runs SET status='APPROVED',approved_by=?,approved_at=CURRENT_TIMESTAMP WHERE id=?",actor,runId);
        closeIfPaid(runId); db.audit("PAYROLL",runId,"APPROVE",actor,"Immutable monthly breakdown approved"); return run(runId);
    }
    public Map<String,Object> pay(long itemId,FinanceRequests.SalaryPayment r,String actor) {
        var i=db.one("SELECT * FROM payroll_items WHERE id=?",itemId);
        long runId=id(i,"run_id");
        var run=db.one("SELECT * FROM payroll_runs WHERE id=? FOR UPDATE",runId);
        i=db.one("SELECT * FROM payroll_items WHERE id=? FOR UPDATE",itemId);
        var old=db.rows("SELECT * FROM salary_payments WHERE request_key=?",r.requestKey());
        if(!old.isEmpty()) {
            if(id(old.get(0),"payroll_item_id")!=itemId || decimal(old.get(0),"amount").compareTo(r.amount())!=0 || !r.method().equals(old.get(0).get("method")))
                throw new IllegalArgumentException("Salary payment request key was already used with different details");
            return run(runId);
        }
        if(!"APPROVED".equals(run.get("status"))) throw new IllegalStateException("Payroll must be approved and unpaid");
        BigDecimal paid=db.amount("SELECT COALESCE(SUM(amount),0) FROM salary_payments WHERE payroll_item_id=?",itemId);
        BigDecimal amount=Money.positive(r.amount(),"Salary payment");
        if(amount.compareTo(decimal(i,"net_payable").subtract(paid))>0) throw new IllegalArgumentException("Salary payment exceeds remaining payable");
        db.update("INSERT INTO salary_payments(payroll_item_id,amount,method,reference,request_key,recorded_by) VALUES(?,?,?,?,?,?)",itemId,amount,r.method(),r.reference(),r.requestKey(),actor);
        db.audit("PAYROLL_ITEM",itemId,"PAY",actor,amount+" "+r.method()+" "+r.reference()); closeIfPaid(runId); return run(runId);
    }
    private void closeIfPaid(long runId) {
        BigDecimal balance=db.amount("SELECT COALESCE(SUM(i.net_payable-COALESCE(p.paid,0)),0) FROM payroll_items i LEFT JOIN (SELECT payroll_item_id,SUM(amount) paid FROM salary_payments GROUP BY payroll_item_id) p ON p.payroll_item_id=i.id WHERE i.run_id=?",runId);
        if(balance.signum()==0) db.update("UPDATE payroll_runs SET status='CLOSED' WHERE id=?",runId);
    }
    public Map<String,Object> payslip(long itemId) {
        var item=db.one("SELECT i.*,r.payroll_month,r.status AS payroll_status FROM payroll_items i JOIN payroll_runs r ON r.id=i.run_id WHERE i.id=?",itemId);
        if("DRAFT".equals(item.get("payroll_status"))) throw new IllegalStateException("Approve payroll before issuing payslips");
        item.put("payments",db.rows("SELECT * FROM salary_payments WHERE payroll_item_id=? ORDER BY paid_at",itemId)); return item;
    }
}
