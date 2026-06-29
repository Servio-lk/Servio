package com.servio.common.event;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;

@Getter
public class AppointmentCreatedEvent extends ApplicationEvent {
    private final Long appointmentId;
    private final Long userId;
    private final String serviceType;
    private final String appointmentDate;

    public AppointmentCreatedEvent(Object source, Long appointmentId, Long userId, String serviceType, String appointmentDate) {
        super(source);
        this.appointmentId = appointmentId;
        this.userId = userId;
        this.serviceType = serviceType;
        this.appointmentDate = appointmentDate;
    }
}
