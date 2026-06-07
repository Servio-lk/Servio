package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RepairConversationDto {
    private Long id;
    private Long conversationId;
    private Long repairId;
    private String realtimeChannel;
    private Boolean isReadOnly;
    private List<RepairConversationMemberDto> members;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
