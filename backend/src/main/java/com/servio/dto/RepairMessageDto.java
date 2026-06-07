package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RepairMessageDto {
    private Long id;
    private Long conversationId;
    private Long repairId;
    private String senderId;
    private String senderRole;
    private String body;
    private LocalDateTime createdAt;
    private LocalDateTime readAt;
}
