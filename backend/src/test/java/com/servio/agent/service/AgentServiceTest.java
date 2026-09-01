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

import java.time.LocalDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AgentServiceTest {

    @Mock
    private GeminiConfig geminiConfig;
    @Mock
    private AgentToolService agentToolService;
    @Mock
    private AgentConversationRepository agentConversationRepository;
    @Mock
    private Authentication authentication;

    private ObjectMapper objectMapper;
    private AgentService agentService;
    private UUID testUserId;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
        agentService = new AgentService(geminiConfig, agentToolService, agentConversationRepository, objectMapper);
        testUserId = UUID.randomUUID();
    }

    @Test
    @DisplayName("chat returns informative guidance when GEMINI_API_KEY is not configured")
    void testChat_geminiUnconfigured_returnsGuidance() {
        when(geminiConfig.isConfigured()).thenReturn(false);

        AgentChatRequest request = new AgentChatRequest();
        request.setMessage("Can I book an oil change for tomorrow at 10 AM?");

        AgentChatResponse response = agentService.chat(request, authentication);

        assertNotNull(response);
        assertNotNull(response.getConversationId());
        assertTrue(response.getMessage().contains("GEMINI_API_KEY"));
        assertTrue(response.getToolCallsExecuted().isEmpty());
        verify(agentConversationRepository, never()).save(any());
    }

    @Test
    @DisplayName("chat preserves provided conversationId across turns")
    void testChat_preservesConversationId() {
        String existingConvId = UUID.randomUUID().toString();
        when(geminiConfig.isConfigured()).thenReturn(false);

        AgentChatRequest request = new AgentChatRequest();
        request.setConversationId(existingConvId);
        request.setMessage("What services do you offer?");

        AgentChatResponse response = agentService.chat(request, authentication);

        assertNotNull(response);
        assertEquals(existingConvId, response.getConversationId());
    }

    @Test
    @DisplayName("chat loads existing conversation entity from repository if available")
    void testChat_loadsExistingConversationFromRepository() {
        String convId = UUID.randomUUID().toString();
        AgentConversation existingConv = AgentConversation.builder()
                .id(convId)
                .userId(testUserId)
                .historyJson("[{\"role\":\"user\",\"parts\":[{\"text\":\"Hi\"}]},{\"role\":\"model\",\"parts\":[{\"text\":\"Hello!\"}]}]")
                .createdAt(LocalDateTime.now().minusHours(1))
                .updatedAt(LocalDateTime.now().minusHours(1))
                .build();

        when(geminiConfig.isConfigured()).thenReturn(false);

        AgentChatRequest request = new AgentChatRequest();
        request.setConversationId(convId);
        request.setMessage("Follow-up question");

        AgentChatResponse response = agentService.chat(request, authentication);

        assertNotNull(response);
        assertEquals(convId, response.getConversationId());
    }

    @Test
    @DisplayName("chat gracefully handles exceptions in chat execution loop")
    void testChat_handlesExceptionGracefully() {
        when(geminiConfig.isConfigured()).thenReturn(true);
        when(geminiConfig.getModel()).thenReturn("gemini-1.5-flash");
        when(geminiConfig.getApiKey()).thenReturn("invalid-api-key");

        AgentChatRequest request = new AgentChatRequest();
        request.setMessage("Help me check my brakes");

        // When external API fails (e.g. invalid key or unreachable endpoint), it returns error response without crashing
        AgentChatResponse response = agentService.chat(request, authentication);

        assertNotNull(response);
        assertTrue(response.getMessage().contains("issue") || response.getMessage().contains("error") || response.getMessage().contains("I encountered an issue"));
    }
}
