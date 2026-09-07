package com.servio.agent.controller;

import com.servio.agent.dto.AgentChatRequest;
import com.servio.agent.dto.AgentChatResponse;
import com.servio.agent.service.AgentService;
import com.servio.common.dto.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/agent")
@RequiredArgsConstructor
public class AgentController {

    private final AgentService agentService;

    @PostMapping("/chat")
    public ResponseEntity<ApiResponse<AgentChatResponse>> chat(
            @Valid @RequestBody AgentChatRequest request,
            Authentication authentication
    ) {
        AgentChatResponse response = agentService.chat(request, authentication);
        return ResponseEntity.ok(ApiResponse.success("Agent processed request successfully", response));
    }
}
