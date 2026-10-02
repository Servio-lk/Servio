package com.servio.common.event;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;

import java.util.UUID;

@Getter
public class AccountUpdatedEvent extends ApplicationEvent {
    private final UUID userId;
    private final String message;

    public AccountUpdatedEvent(Object source, UUID userId, String message) {
        super(source);
        this.userId = userId;
        this.message = message;
    }
}
