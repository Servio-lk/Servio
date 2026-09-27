package com.servio.notification.service;

import com.servio.notification.dto.NotificationDto;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class SmsNotificationChannel implements NotificationChannel {
    @Override
    public void deliver(NotificationDto notification) {
        log.debug("SMS hook for user {}: {}", notification.getUserId(), notification.getTitle());
    }
}
