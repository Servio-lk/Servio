package com.servio.common.event;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;

@Getter
public class PaymentCompletedEvent extends ApplicationEvent {
    private final Long appointmentId;
    private final Double amount;
    private final String paymentMethod;

    public PaymentCompletedEvent(Object source, Long appointmentId, Double amount, String paymentMethod) {
        super(source);
        this.appointmentId = appointmentId;
        this.amount = amount;
        this.paymentMethod = paymentMethod;
    }
}
