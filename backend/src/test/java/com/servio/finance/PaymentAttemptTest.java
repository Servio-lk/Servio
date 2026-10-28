package com.servio.finance;
import org.h2.jdbcx.JdbcDataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import java.math.BigDecimal;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;
class PaymentAttemptTest {
    JdbcTemplate jdbc; PaymentAttemptService service; TransactionTemplate tx;
    @BeforeEach void setup() {
        var ds=new JdbcDataSource();ds.setURL("jdbc:h2:mem:"+UUID.randomUUID()+";MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1");
        jdbc=new JdbcTemplate(ds);service=new PaymentAttemptService(new FinanceStore(jdbc));tx=new TransactionTemplate(new DataSourceTransactionManager(ds));
        jdbc.execute("CREATE TABLE appointments(id BIGINT PRIMARY KEY)");jdbc.update("INSERT INTO appointments VALUES(1)");
        jdbc.execute("CREATE TABLE payments(id BIGINT PRIMARY KEY,appointment_id BIGINT,payment_status VARCHAR)");
        jdbc.execute("CREATE TABLE payment_attempts(order_id VARCHAR PRIMARY KEY,appointment_id BIGINT,expected_amount NUMERIC(19,2),currency VARCHAR,status VARCHAR DEFAULT 'PENDING',transaction_id VARCHAR,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,expires_at TIMESTAMP)");
    }
    String reserve() {return tx.execute(s->service.reserve(1,new BigDecimal("5000"),"LKR"));}
    @Test void retriesReuseCheckoutSnapshotAndValidateBothAmountAndCurrency() {
        String order=reserve();assertEquals(order,reserve());
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM payment_attempts",Integer.class));
        assertThrows(SecurityException.class,()->tx.execute(s->service.validate(order,"1.00","LKR")));
        assertThrows(SecurityException.class,()->tx.execute(s->service.validate(order,"5000.00","USD")));
        assertEquals(1L,FinanceStore.id(tx.execute(s->service.validate(order,"5000.00","LKR")),"appointment_id"));
    }
    @Test void alreadyPaidBookingAndZeroValueCheckoutAreRejected() {
        assertThrows(IllegalArgumentException.class,()->tx.execute(s->service.reserve(1,BigDecimal.ZERO,"LKR")));
        jdbc.update("INSERT INTO payments VALUES(1,1,'COMPLETED')");
        assertThrows(IllegalStateException.class,()->reserve());
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM payment_attempts",Integer.class));
    }
    @Test void completionRequiresGatewayReferenceAndPreservesSnapshot() {
        String order=reserve();assertThrows(SecurityException.class,()->tx.execute(s->{service.complete(order,"");return null;}));
        tx.execute(s->{service.complete(order,"gateway-reference");return null;});
        assertEquals("COMPLETED",jdbc.queryForObject("SELECT status FROM payment_attempts",String.class));
        assertEquals(new BigDecimal("5000.00"),jdbc.queryForObject("SELECT expected_amount FROM payment_attempts",BigDecimal.class));
    }
}
