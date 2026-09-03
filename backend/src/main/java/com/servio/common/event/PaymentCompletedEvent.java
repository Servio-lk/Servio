package com.servio.common.event;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;
import java.util.UUID;

@Getter
public class PaymentCompletedEvent extends ApplicationEvent {
    private final Long appointmentId;
    private final UUID userId;
    private final Double amount;
    private final String paymentMethod;

    public PaymentCompletedEvent(Object source, Long appointmentId, UUID userId, Double amount, String paymentMethod) {
        super(source);
        this.appointmentId = appointmentId;
        this.userId = userId;
        this.amount = amount;
        this.paymentMethod = paymentMethod;
    }
}
