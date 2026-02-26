package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Payload pushed over WebSocket whenever an appointment changes.
 * Clients subscribe to:
 *   /topic/appointments           – all changes (admin dashboard)
 *   /topic/appointments/user/{id} – changes for a specific user
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AppointmentWebSocketEvent {
    /** CREATED | UPDATED | CANCELLED | DELETED */
    private String type;
    private Long appointmentId;
    /** Numeric backend user ID (null for Supabase-only users) */
    private Long userId;
    private String serviceType;
    private String status;
    private String appointmentDate;
}
