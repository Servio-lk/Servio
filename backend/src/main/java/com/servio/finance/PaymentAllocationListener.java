package com.servio.finance;
import com.servio.common.event.PaymentCompletedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/** Allocate late booking payments in the same transaction as payment recording. */
@Component
@RequiredArgsConstructor
public class PaymentAllocationListener {
    private final jakarta.persistence.EntityManager entityManager;
    private final FinanceStore db;
    private final InvoiceService invoices;
    @TransactionalEventListener(phase=TransactionPhase.BEFORE_COMMIT)
    public void paymentCompleted(PaymentCompletedEvent event) {
        entityManager.flush();
        for(var invoice:db.rows("SELECT id FROM billing_invoices WHERE appointment_id=? AND status='ISSUED'",event.getAppointmentId()))
            invoices.allocate(FinanceStore.id(invoice,"id"),"payment-notification");
    }
}
