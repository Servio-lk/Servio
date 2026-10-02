package com.servio.notification.service;

import com.servio.notification.dto.NotificationDto;

/**
 * Optional delivery hook. In-app persistence stays in {@link NotificationService}.
 * Email and SMS implementations log until a provider is configured.
 */
public interface NotificationChannel {
    void deliver(NotificationDto notification);
}
