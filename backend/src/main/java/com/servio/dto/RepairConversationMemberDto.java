package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RepairConversationMemberDto {
    private Long id;
    private Long conversationId;
    private String role;
    private String memberRef;
    private String memberUserId;
    private Long mechanicId;
    private Boolean canWrite;
}
