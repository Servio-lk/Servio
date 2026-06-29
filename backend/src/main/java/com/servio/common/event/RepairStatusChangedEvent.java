package com.servio.common.event;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;

@Getter
public class RepairStatusChangedEvent extends ApplicationEvent {
    private final Long appointmentId;
    private final Long userId;
    private final String newStatus;
    private final String message;

    public RepairStatusChangedEvent(Object source, Long appointmentId, Long userId, String newStatus, String message) {
        super(source);
        this.appointmentId = appointmentId;
        this.userId = userId;
        this.newStatus = newStatus;
        this.message = message;
    }
}
