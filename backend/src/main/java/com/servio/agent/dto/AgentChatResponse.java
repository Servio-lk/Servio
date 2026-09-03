package com.servio.agent.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AgentChatResponse {
    private String conversationId;
    private String message;
    private List<String> toolCallsExecuted;
    private Object actionData;
}
