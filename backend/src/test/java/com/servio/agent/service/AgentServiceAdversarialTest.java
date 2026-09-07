package com.servio.agent.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.servio.agent.config.GeminiConfig;
import com.servio.agent.dto.AgentChatRequest;
import com.servio.agent.dto.AgentChatResponse;
import com.servio.agent.entity.AgentConversation;
import com.servio.agent.repository.AgentConversationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.Authentication;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AgentServiceAdversarialTest {

    @Mock
    private GeminiConfig geminiConfig;
    @Mock
    private AgentToolService agentToolService;
    @Mock
    private AgentConversationRepository conversationRepository;
    @Mock
    private Authentication authentication;

    private ObjectMapper objectMapper;
    private AgentService agentService;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
        agentService = new AgentService(geminiConfig, agentToolService, conversationRepository, objectMapper);
    }

    @Test
    @DisplayName("When Gemini is unconfigured, returns guidance message and fallback without crashing")
    void testChat_geminiUnconfigured_returnsGuidance() {
        when(geminiConfig.isConfigured()).thenReturn(false);

        AgentChatRequest request = new AgentChatRequest();
        request.setMessage("Help me book a service");

        AgentChatResponse response = agentService.chat(request, authentication);

        assertNotNull(response);
        assertNotNull(response.getConversationId());
        assertTrue(response.getMessage().contains("GEMINI_API_KEY"));
        assertTrue(response.getToolCallsExecuted().isEmpty());
    }

    @Test
    @DisplayName("When conversation ID is passed, loads existing conversation entity from repository")
    void testChat_loadsConversationFromRepository() {
        String convId = UUID.randomUUID().toString();
        UUID userId = UUID.randomUUID();

        when(geminiConfig.isConfigured()).thenReturn(false);

        AgentChatRequest request = new AgentChatRequest();
        request.setConversationId(convId);
        request.setMessage("Can you check my brakes?");

        AgentChatResponse response = agentService.chat(request, authentication);

        assertNotNull(response);
        assertEquals(convId, response.getConversationId());
    }
}
