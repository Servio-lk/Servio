package com.servio.auth.dto;

import lombok.Data;

@Data
public class UpdatePreferencesRequest {
    private Boolean promotionalOffers;
    private Boolean pushNotifications;
    private Boolean securityAlerts;
}
