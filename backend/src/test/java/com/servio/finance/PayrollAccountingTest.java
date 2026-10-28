package com.servio.finance;
import org.h2.jdbcx.JdbcDataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import java.math.BigDecimal;
import java.time.*;
import java.nio.file.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;

public class PayrollAccountingTest {
    JdbcTemplate jdbc; FinanceStore db; PayrollService service; TransactionTemplate tx;
    LocalDate start=YearMonth.now().minusMonths(1).atDay(1);
    public static int hash(String s) {return s.hashCode();}
    public static int lock(int key) {return key;}
    @BeforeEach void setup() throws Exception {
        var ds=new JdbcDataSource();ds.setURL("jdbc:h2:mem:"+UUID.randomUUID()+";MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1");
        jdbc=new JdbcTemplate(ds);db=new FinanceStore(jdbc);service=new PayrollService(db);tx=new TransactionTemplate(new DataSourceTransactionManager(ds));
        jdbc.execute("CREATE ALIAS hashtext FOR 'com.servio.finance.PayrollAccountingTest.hash'");
        jdbc.execute("CREATE ALIAS pg_advisory_xact_lock FOR 'com.servio.finance.PayrollAccountingTest.lock'");
        jdbc.execute("CREATE TABLE mechanics(id BIGINT PRIMARY KEY,full_name VARCHAR,is_active BOOLEAN)");
        String migration=Files.readString(Path.of("src/main/resources/db/migration/V31__billing_and_monthly_payroll.sql"));
        for(String table:List.of("mechanic_salary_agreements","mechanic_attendance","salary_advances","payroll_runs","payroll_items","salary_advance_recoveries","salary_payments","finance_audit")) {
            int begin=migration.indexOf("CREATE TABLE "+table+" (");int end=migration.indexOf(";",begin);jdbc.execute(migration.substring(begin,end));
        }
        jdbc.update("INSERT INTO mechanics VALUES(1,'Mechanic One',true)");
        tx.execute(s->service.agreement(new FinanceRequests.Agreement(1L,start,new BigDecimal("60000"),new BigDecimal("5000"),new BigDecimal("500"),new BigDecimal("30")),"admin"));
        for(int day=1;day<=YearMonth.from(start).lengthOfMonth();day++) jdbc.update("INSERT INTO mechanic_attendance(mechanic_id,work_date,status,overtime_hours,approved,recorded_by) VALUES(1,?,?,?,true,'admin')",start.withDayOfMonth(day),day==1?"UNPAID_LEAVE":"PRESENT",day==2?new BigDecimal("6"):BigDecimal.ZERO);
    }
    long generate() {return FinanceStore.id(tx.execute(s->service.generate(start.toString().substring(0,7),"admin")),"id");}
    long item(long run) {return jdbc.queryForObject("SELECT id FROM payroll_items WHERE run_id=?",Long.class,run);}
    @Test void approvalRequiresCompleteAttendanceAndRejectsStaleDraft() {
        long run=generate();jdbc.update("UPDATE mechanic_attendance SET approved=false WHERE work_date=?",start);
        assertThrows(IllegalStateException.class,()->tx.execute(s->service.approve(run,"admin")));
        jdbc.update("UPDATE mechanic_attendance SET approved=true,overtime_hours=2,status='PRESENT' WHERE work_date=?",start);
        assertThrows(IllegalStateException.class,()->tx.execute(s->service.approve(run,"admin")));
        assertEquals("DRAFT",service.run(run).get("status"));
    }
    @Test void monthlySalarySnapshotAndPaymentsAreImmutableAndIdempotent() {
        long run=generate(),item=item(run);tx.execute(s->service.approve(run,"admin"));
        assertEquals(new BigDecimal("66000.00"),db.amount("SELECT net_payable FROM payroll_items WHERE id=?",item));
        var payment=new FinanceRequests.SalaryPayment(new BigDecimal("30000"),"BANK_TRANSFER","bank-receipt","same-key");
        tx.execute(s->service.pay(item,payment,"admin"));tx.execute(s->service.pay(item,payment,"admin"));
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM salary_payments",Integer.class));
        assertThrows(IllegalStateException.class,()->tx.execute(s->service.generate(start.toString().substring(0,7),"admin")));
        assertThrows(IllegalArgumentException.class,()->tx.execute(s->service.pay(item,new FinanceRequests.SalaryPayment(new BigDecimal("36001"),"CASH","receipt","overpay"),"admin")));
        tx.execute(s->service.pay(item,new FinanceRequests.SalaryPayment(new BigDecimal("36000"),"BANK_TRANSFER","final-receipt","final-key"),"admin"));
        assertEquals("CLOSED",service.run(run).get("status"));
        assertEquals(2,((List<?>)service.payslip(item).get("payments")).size());
    }
    @Test void advanceRecoveryIsRecordedOnlyOnceAtApproval() {
        tx.execute(s->service.advance(new FinanceRequests.Advance(1L,new BigDecimal("5000"),start,"advance-receipt","advance-key"),"admin"));
        long run=generate(),item=item(run);
        tx.execute(s->service.adjust(item,new FinanceRequests.Adjustment(new BigDecimal("5000"),BigDecimal.ZERO,"Recover paid advance"),"admin"));
        tx.execute(s->service.approve(run,"admin"));tx.execute(s->service.approve(run,"admin"));
        assertEquals(new BigDecimal("5000.00"),db.amount("SELECT SUM(amount) FROM salary_advance_recoveries"));
        assertEquals(new BigDecimal("61000.00"),db.amount("SELECT net_payable FROM payroll_items WHERE id=?",item));
        assertThrows(IllegalStateException.class,()->tx.execute(s->service.adjust(item,new FinanceRequests.Adjustment(BigDecimal.ZERO,BigDecimal.ZERO,"Change"),"admin")));
    }
    @Test void insufficientAdvanceAndPrematureSalaryPaymentsAreRejected() {
        long run=generate(),item=item(run);
        assertThrows(IllegalArgumentException.class,()->tx.execute(s->service.adjust(item,new FinanceRequests.Adjustment(BigDecimal.ONE,BigDecimal.ZERO,"No advance"),"admin")));
        assertThrows(IllegalStateException.class,()->tx.execute(s->service.pay(item,new FinanceRequests.SalaryPayment(BigDecimal.ONE,"CASH","receipt","key"),"admin")));
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM salary_payments",Integer.class));
    }
}
