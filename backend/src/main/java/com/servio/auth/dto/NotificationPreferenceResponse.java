package com.servio.auth.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class NotificationPreferenceResponse {
    private boolean promotionalOffers;
    private boolean pushNotifications;
    private boolean securityAlerts;
}
