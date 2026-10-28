package com.servio.finance;
import com.servio.booking.dto.AppointmentRequest;
import org.h2.jdbcx.JdbcDataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;
class BookingPricingTest {
    JdbcTemplate jdbc; BookingPricingService pricing;
    @BeforeEach void setup() {
        var ds=new JdbcDataSource();ds.setURL("jdbc:h2:mem:"+UUID.randomUUID()+";MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1");
        jdbc=new JdbcTemplate(ds);pricing=new BookingPricingService(new FinanceStore(jdbc));
        jdbc.execute("CREATE TABLE services(id BIGINT PRIMARY KEY,name VARCHAR,base_price NUMERIC(19,2),is_active BOOLEAN)");
        jdbc.execute("CREATE TABLE service_options(id BIGINT PRIMARY KEY,service_id BIGINT,price_adjustment NUMERIC(19,2))");
        jdbc.execute("CREATE TABLE offers(promo_code VARCHAR,discount_type VARCHAR,discount_value NUMERIC(19,2),applicable_service VARCHAR,is_active BOOLEAN,valid_from TIMESTAMP,valid_until TIMESTAMP)");
        jdbc.update("INSERT INTO services VALUES(1,'Oil Change',5000,true)");jdbc.update("INSERT INTO service_options VALUES(4,1,1000)");
        jdbc.update("INSERT INTO service_options VALUES(5,2,999)");
        jdbc.update("INSERT INTO offers VALUES('TEN','PERCENTAGE',10,'Oil Change',true,NULL,NULL)");
    }
    @Test void ignoresClientTotalsAndPricesSelectedPackageAndOffer() {
        var r=AppointmentRequest.builder().serviceId(1L).optionId(4L).promoCode("TEN").estimatedCost(BigDecimal.ONE).build();
        pricing.price(r);assertEquals(new BigDecimal("5400.00"),r.getEstimatedCost());assertEquals("Oil Change",r.getServiceType());
    }
    @Test void legacyClientsCanIdentifyServiceByNameButCannotSetPrice() {
        var r=AppointmentRequest.builder().serviceType("Oil Change").estimatedCost(BigDecimal.ZERO).build();
        pricing.price(r);assertEquals(new BigDecimal("5000.00"),r.getEstimatedCost());
    }
    @Test void wrongServiceOptionAndExpiredOfferAreRejected() {
        assertThrows(IllegalArgumentException.class,()->pricing.price(AppointmentRequest.builder().serviceId(1L).optionId(5L).build()));
        jdbc.update("UPDATE offers SET valid_until=?",LocalDateTime.now().minusDays(1));
        assertThrows(IllegalArgumentException.class,()->pricing.price(AppointmentRequest.builder().serviceId(1L).promoCode("TEN").build()));
    }
    @Test void offerCannotBeAppliedToAnotherService() {
        jdbc.update("UPDATE offers SET applicable_service='Brake Service'");
        assertThrows(IllegalArgumentException.class,()->pricing.price(AppointmentRequest.builder().serviceId(1L).promoCode("TEN").build()));
    }
}
