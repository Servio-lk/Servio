package com.servio.finance;
import com.servio.admin.dto.JobCardDto;
import com.servio.admin.entity.JobCard;
import com.servio.admin.repository.JobCardRepository;
import com.servio.admin.service.JobCardService;
import com.servio.inventory.service.InventoryService;
import org.h2.jdbcx.JdbcDataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import java.math.BigDecimal;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;

class JobBillingTest {
    JdbcTemplate jdbc; FinanceStore db; InvoiceService service; TransactionTemplate tx;
    JobCardRepository jobs; JobCardService jobCards; InventoryService inventory;
    @BeforeEach void setup() {
        var ds=new JdbcDataSource();ds.setURL("jdbc:h2:mem:"+UUID.randomUUID()+";MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1");
        jdbc=new JdbcTemplate(ds);db=new FinanceStore(jdbc);tx=new TransactionTemplate(new DataSourceTransactionManager(ds));
        jobs=mock(JobCardRepository.class);jobCards=mock(JobCardService.class);inventory=mock(InventoryService.class);
        service=new InvoiceService(db,jobs,jobCards,inventory,mock(org.springframework.context.ApplicationEventPublisher.class));
        jdbc.execute("CREATE TABLE job_cards(id BIGINT PRIMARY KEY,appointment_id BIGINT,walk_in_customer_id BIGINT,job_number VARCHAR,status VARCHAR,billing_request_key VARCHAR)");
        jdbc.execute("CREATE TABLE billing_invoices(id BIGINT PRIMARY KEY,job_card_id BIGINT,status VARCHAR)");
        jdbc.execute("CREATE TABLE job_charges(id BIGSERIAL PRIMARY KEY,job_card_id BIGINT,inventory_item_id BIGINT,description VARCHAR,quantity NUMERIC(19,2),rate NUMERIC(19,2),amount NUMERIC(19,2),request_key VARCHAR UNIQUE,created_by VARCHAR,reversed_at TIMESTAMP,reversed_by VARCHAR)");
        jdbc.execute("CREATE TABLE inventory_items(id BIGINT PRIMARY KEY,name VARCHAR,selling_price_per_unit NUMERIC(19,2))");
        jdbc.execute("CREATE TABLE finance_audit(id BIGSERIAL PRIMARY KEY,resource_type VARCHAR,resource_id BIGINT,action VARCHAR,actor VARCHAR,details VARCHAR)");
        jdbc.update("INSERT INTO job_cards VALUES(1,7,NULL,'JC-1','NEW',NULL)");jdbc.update("INSERT INTO inventory_items VALUES(2,'Oil filter',1000)");
    }
    @Test void issuingPartTwiceWithSameKeyConsumesStockOnlyOnceAndReturnIsIdempotent() {
        when(jobs.findById(1L)).thenReturn(Optional.of(JobCard.builder().id(1L).jobNumber("JC-1").build()));
        var r=new FinanceRequests.Charge(1L,2L,new BigDecimal("2"),"same-key");
        var charge=tx.execute(s->service.charge(r,"admin"));tx.execute(s->service.charge(r,"admin"));
        assertEquals(new BigDecimal("2000.00"),charge.get("amount"));verify(inventory,times(1)).updateStock(eq(2L),any(),eq("admin"));
        long id=FinanceStore.id(charge,"id");tx.execute(s->{service.reverseCharge(id,"admin");return null;});tx.execute(s->{service.reverseCharge(id,"admin");return null;});
        verify(inventory,times(2)).updateStock(eq(2L),any(),eq("admin"));assertTrue(service.charges(1).isEmpty());
    }
    @Test void issuedInvoicePreventsChangingChargedParts() {
        jdbc.update("INSERT INTO billing_invoices VALUES(9,1,'ISSUED')");
        assertThrows(IllegalStateException.class,()->tx.execute(s->service.charge(new FinanceRequests.Charge(1L,2L,BigDecimal.ONE,"key"),"admin")));
        verifyNoInteractions(inventory);
    }
    @Test void appointmentJobReusesExistingCardAndUsesServerEstimateForNewCard() {
        jdbc.execute("CREATE TABLE appointments(id BIGINT PRIMARY KEY,service_type VARCHAR,estimated_cost NUMERIC(19,2),status VARCHAR)");jdbc.update("INSERT INTO appointments VALUES(7,'Oil change',5000,'CONFIRMED')");
        var result=tx.execute(s->service.createJob(new FinanceRequests.Job(7L,null,null,"key"),"admin"));assertEquals(1L,FinanceStore.id(result,"id"));verifyNoInteractions(jobCards);
        jdbc.update("DELETE FROM job_cards");
        when(jobCards.createJobCard(any())).thenAnswer(inv->{JobCardDto dto=inv.getArgument(0);jdbc.update("INSERT INTO job_cards VALUES(1,7,NULL,'JC-1','NEW',?)",dto.getBillingRequestKey());return JobCardDto.builder().id(1L).build();});
        tx.execute(s->service.createJob(new FinanceRequests.Job(7L,null,null,"key"),"admin"));
        var dto=ArgumentCaptor.forClass(JobCardDto.class);verify(jobCards).createJobCard(dto.capture());assertEquals(new BigDecimal("5000.00"),dto.getValue().getEstimatedCost());
    }
    @Test void jobRequiresExactlyOneCustomerSource() {
        assertThrows(IllegalArgumentException.class,()->service.createJob(new FinanceRequests.Job(null,null,null,"key"),"admin"));
        assertThrows(IllegalArgumentException.class,()->service.createJob(new FinanceRequests.Job(7L,8L,1L,"key"),"admin"));
    }
}
