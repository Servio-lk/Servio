package com.servio.notification.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationRequest {
    private UUID userId;
    private String title;
    private String message;
    private String type; // APPOINTMENT, PAYMENT, REMINDER, PROMOTIONAL
}
