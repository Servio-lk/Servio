package com.servio.finance;
import com.servio.admin.repository.JobCardRepository;
import com.servio.inventory.service.InventoryService;
import org.h2.jdbcx.JdbcDataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import java.math.BigDecimal;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;

/** Exercises real SQL and rollback locally without connecting to the live database. */
class InvoiceAccountingTest {
    JdbcTemplate jdbc; FinanceStore db; InvoiceService service; TransactionTemplate tx;
    @BeforeEach void setup() {
        var ds=new JdbcDataSource();ds.setURL("jdbc:h2:mem:"+UUID.randomUUID()+";MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1");
        jdbc=new JdbcTemplate(ds);db=new FinanceStore(jdbc);tx=new TransactionTemplate(new DataSourceTransactionManager(ds));
        service=new InvoiceService(db,mock(JobCardRepository.class),mock(com.servio.admin.service.JobCardService.class),mock(InventoryService.class),mock(org.springframework.context.ApplicationEventPublisher.class));
        jdbc.execute("CREATE TABLE billing_invoices(id BIGINT PRIMARY KEY,invoice_no VARCHAR,appointment_id BIGINT,job_card_id BIGINT,status VARCHAR,currency VARCHAR,net_total NUMERIC(19,2),void_reason VARCHAR)");
        jdbc.execute("CREATE TABLE billing_invoice_items(id BIGSERIAL PRIMARY KEY,bill_id BIGINT,description VARCHAR,quantity NUMERIC,rate NUMERIC,amount NUMERIC)");
        jdbc.execute("CREATE TABLE payments(id BIGSERIAL PRIMARY KEY,appointment_id BIGINT,user_id UUID,amount NUMERIC(19,2),payment_method VARCHAR,payment_status VARCHAR,transaction_id VARCHAR UNIQUE,payment_date TIMESTAMP,created_at TIMESTAMP,currency VARCHAR,request_key VARCHAR UNIQUE,reference VARCHAR(255))");
        jdbc.execute("CREATE TABLE payment_allocations(id BIGSERIAL PRIMARY KEY,bill_id BIGINT,payment_id BIGINT,amount NUMERIC(19,2),created_by VARCHAR,UNIQUE(bill_id,payment_id))");
        jdbc.execute("CREATE TABLE billing_refunds(id BIGSERIAL PRIMARY KEY,bill_id BIGINT,payment_id BIGINT,amount NUMERIC(19,2),reason VARCHAR,reference VARCHAR,request_key VARCHAR UNIQUE,recorded_by VARCHAR)");
        jdbc.execute("CREATE TABLE finance_audit(id BIGSERIAL PRIMARY KEY,resource_type VARCHAR,resource_id BIGINT,action VARCHAR,actor VARCHAR,details VARCHAR)");
        jdbc.update("INSERT INTO billing_invoices VALUES(1,'INV-TEST',NULL,NULL,'ISSUED','LKR',1000,NULL)");
    }
    BigDecimal n(String value) { return new BigDecimal(value); }
    Map<String,Object> collect(String amount,String key) {
        return tx.execute(s->service.collect(1,new FinanceRequests.Collection(n(amount),"CASH","receipt",key),"admin"));
    }
    @Test void partialPaymentAndRetryNeverDoubleCount() {
        collect("400","same-request");var result=collect("400","same-request");
        assertEquals(n("400.00"),result.get("paid_amount"));assertEquals(n("600.00"),result.get("balance_due"));
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM payments",Integer.class));
        collect("600","balance");assertEquals("PAID",service.invoice(1).get("settlement_status"));
    }
    @Test void excessPaymentRejectedWithoutPersistingMoney() {
        collect("400","first");assertThrows(IllegalArgumentException.class,()->collect("601","excess"));
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM payments",Integer.class));
        assertEquals(n("600.00"),service.invoice(1).get("balance_due"));
    }
    @Test void refundRetriesAndVoidingPreservePaymentHistory() {
        collect("400","first");long payment=jdbc.queryForObject("SELECT id FROM payments",Long.class);
        var refund=new FinanceRequests.Refund(payment,n("400"),"Cancelled work","refund-receipt","refund-key");
        tx.execute(s->service.refund(1,refund,"admin"));tx.execute(s->service.refund(1,refund,"admin"));
        assertEquals(n("0.00"),service.invoice(1).get("paid_amount"));
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM billing_refunds",Integer.class));
        assertEquals("VOID",tx.execute(s->service.voidInvoice(1,"Cancelled work","admin")).get("status"));
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM payments",Integer.class));
    }
    @Test void paidInvoiceCannotBeVoidedAndRefundCannotExceedAllocatedPayment() {
        collect("400","first");long payment=jdbc.queryForObject("SELECT id FROM payments",Long.class);
        assertThrows(IllegalStateException.class,()->tx.execute(s->service.voidInvoice(1,"Cancel","admin")));
        assertThrows(IllegalArgumentException.class,()->tx.execute(s->service.refund(1,new FinanceRequests.Refund(payment,n("401"),"Cancel","ref","key"),"admin")));
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM billing_refunds",Integer.class));
    }
    @Test void existingAppointmentCashCollectionCreatesAdvanceThenSettlesInvoice() {
        jdbc.execute("CREATE TABLE appointments(id BIGINT PRIMARY KEY,user_id UUID,estimated_cost NUMERIC(19,2),actual_cost NUMERIC(19,2))");
        jdbc.update("INSERT INTO appointments VALUES(7,NULL,1000,NULL)");
        var request=new com.servio.admin.dto.PaymentCollectionRequest();request.setAmount(n("400"));request.setPaymentMethod("CASH");request.setRequestKey("legacy-cash");
        tx.execute(status->{service.appointmentPayment(7,request,"admin");return null;});
        tx.execute(status->{service.appointmentPayment(7,request,"admin");return null;});
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM payments",Integer.class));
        jdbc.update("UPDATE billing_invoices SET appointment_id=7 WHERE id=1");tx.execute(status->service.allocate(1,"admin"));
        request.setAmount(n("600"));request.setRequestKey("legacy-balance");
        tx.execute(status->{service.appointmentPayment(7,request,"admin");return null;});
        assertEquals("PAID",service.invoice(1).get("settlement_status"));
    }
    @Test void paymentKeyCannotBeReusedForAnotherInvoice() {
        collect("400","same-key");jdbc.update("INSERT INTO billing_invoices VALUES(2,'INV-SECOND',NULL,NULL,'ISSUED','LKR',1000,NULL)");
        assertThrows(IllegalArgumentException.class,()->tx.execute(s->service.collect(2,new FinanceRequests.Collection(n("400"),"CASH","receipt","same-key"),"admin")));
    }
    @Test void refundedBookingAdvanceCannotBeAllocatedToAnInvoiceLater() {
        jdbc.execute("CREATE TABLE appointments(id BIGINT PRIMARY KEY,user_id UUID)");jdbc.update("INSERT INTO appointments VALUES(7,NULL)");
        jdbc.update("UPDATE billing_invoices SET appointment_id=7 WHERE id=1");
        jdbc.update("INSERT INTO payments(appointment_id,amount,payment_method,payment_status,currency) VALUES(7,1200,'PAYHERE','COMPLETED','LKR')");
        long payment=jdbc.queryForObject("SELECT id FROM payments",Long.class);
        var refund=new FinanceRequests.Refund(payment,n("300"),"Excess advance","gateway-refund","refund-key");
        tx.execute(s->{service.refundAdvance(payment,refund,"admin");return null;});tx.execute(s->{service.refundAdvance(payment,refund,"admin");return null;});
        tx.execute(s->service.allocate(1,"admin"));
        assertEquals(n("900.00"),service.invoice(1).get("paid_amount"));assertEquals(n("100.00"),service.invoice(1).get("balance_due"));
        assertThrows(IllegalArgumentException.class,()->tx.execute(s->{service.refundAdvance(payment,new FinanceRequests.Refund(payment,n("1"),"Already allocated","reference","another-key"),"admin");return null;}));
    }
    @Test void bookingAdvanceIsCappedAtInvoiceBalanceAndRepeatedAllocationIsSafe() {
        jdbc.execute("CREATE TABLE appointments(id BIGINT PRIMARY KEY,user_id UUID)");jdbc.update("INSERT INTO appointments VALUES(7,NULL)");
        jdbc.update("UPDATE billing_invoices SET appointment_id=7 WHERE id=1");
        jdbc.update("INSERT INTO payments(appointment_id,amount,payment_method,payment_status,currency) VALUES(7,1200,'PAYHERE','COMPLETED','LKR')");
        tx.execute(s->service.allocate(1,"admin"));var result=tx.execute(s->service.allocate(1,"admin"));
        assertEquals(n("1000.00"),result.get("paid_amount"));assertEquals(n("0.00"),result.get("balance_due"));
        assertEquals(n("1000.00"),db.amount("SELECT SUM(amount) FROM payment_allocations"));
    }
}
