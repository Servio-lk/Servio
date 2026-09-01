package com.servio.agent.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.servio.agent.config.GeminiConfig;
import com.servio.agent.dto.AgentChatRequest;
import com.servio.agent.dto.AgentChatResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
@RequiredArgsConstructor
public class AgentService {

    private final GeminiConfig geminiConfig;
    private final AgentToolService agentToolService;
    private final ObjectMapper objectMapper;
    private final RestTemplate restTemplate = new RestTemplate();

    // Cache of recent conversations: conversationId -> List of turns (Jackson ObjectNodes)
    private final Map<String, List<ObjectNode>> conversationHistory = new ConcurrentHashMap<>();

    private static final String SYSTEM_INSTRUCTION = """
            You are Servio AI, an intelligent, helpful, and courteous automotive assistant for the Servio vehicle service and repair center.
            Your role is to help customers:
            1. View and select their registered vehicles using `get_user_vehicles`.
            2. Explore available maintenance packages, repair services, and transparent pricing using `get_catalog_services` or `get_service_details`.
            3. Check date and time availability using `get_booked_slots`.
            4. Confirm and finalize service appointments using `book_appointment`.

            Behavior guidelines:
            - Always be professional, empathetic, and automotive-savvy.
            - Currencies are in Sri Lankan Rupees (LKR).
            - Always ask the customer to confirm details (vehicle, service, date & time) before calling `book_appointment`.
            - If the user asks general car care questions, provide expert automotive advice and suggest relevant Servio services when applicable.
            """;

    public AgentChatResponse chat(AgentChatRequest request, Authentication authentication) {
        String conversationId = request.getConversationId();
        if (conversationId == null || conversationId.trim().isEmpty()) {
            conversationId = UUID.randomUUID().toString();
        }

        if (!geminiConfig.isConfigured()) {
            return AgentChatResponse.builder()
                    .conversationId(conversationId)
                    .message("Hello! I am Servio's AI Assistant. To activate my live intelligence, please configure your `GEMINI_API_KEY` in `backend/.env`. Once added, I will be able to inspect your registered vehicles, look up services and pricing, and book appointments for you directly.")
                    .toolCallsExecuted(Collections.emptyList())
                    .build();
        }

        List<ObjectNode> history = conversationHistory.computeIfAbsent(conversationId, k -> Collections.synchronizedList(new ArrayList<>()));
        List<String> executedTools = new ArrayList<>();

        try {
            // Append the new user message turn
            ObjectNode userTurn = objectMapper.createObjectNode();
            userTurn.put("role", "user");
            ArrayNode userParts = userTurn.putArray("parts");
            userParts.addObject().put("text", request.getMessage());
            history.add(userTurn);

            // Run multi-turn tool-calling loop (max 5 iterations)
            int iterations = 0;
            String finalResponseText = "I'm here to help with your vehicle service needs.";

            while (iterations < 5) {
                iterations++;
                ObjectNode requestBody = buildGeminiRequestBody(history);

                String endpoint = String.format(
                        "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s",
                        geminiConfig.getModel(),
                        geminiConfig.getApiKey()
                );

                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.APPLICATION_JSON);
                HttpEntity<String> httpEntity = new HttpEntity<>(objectMapper.writeValueAsString(requestBody), headers);

                ResponseEntity<String> response = restTemplate.postForEntity(endpoint, httpEntity, String.class);
                JsonNode root = objectMapper.readTree(response.getBody());

                JsonNode candidate = root.path("candidates").path(0);
                JsonNode content = candidate.path("content");
                JsonNode parts = content.path("parts");

                if (parts.isMissingNode() || parts.isEmpty()) {
                    break;
                }

                // Append model's response to history
                ObjectNode modelTurn = (ObjectNode) content;
                history.add(modelTurn);

                // Check if the model made any function calls
                List<JsonNode> functionCalls = new ArrayList<>();
                StringBuilder textAccumulator = new StringBuilder();

                for (JsonNode part : parts) {
                    if (part.has("functionCall")) {
                        functionCalls.add(part.get("functionCall"));
                    }
                    if (part.has("text")) {
                        textAccumulator.append(part.get("text").asText());
                    }
                }

                if (functionCalls.isEmpty()) {
                    // No function call: final answer reached
                    finalResponseText = textAccumulator.toString();
                    break;
                }

                // Execute function calls and send function responses
                ObjectNode functionTurn = objectMapper.createObjectNode();
                functionTurn.put("role", "function");
                ArrayNode funcParts = functionTurn.putArray("parts");

                for (JsonNode call : functionCalls) {
                    String funcName = call.path("name").asText();
                    executedTools.add(funcName);

                    Map<String, Object> args = new HashMap<>();
                    if (call.has("args")) {
                        args = objectMapper.convertValue(call.get("args"), Map.class);
                    }

                    Object toolResult = agentToolService.executeTool(funcName, args, authentication);

                    ObjectNode partNode = funcParts.addObject();
                    ObjectNode funcResponse = partNode.putObject("functionResponse");
                    funcResponse.put("name", funcName);
                    funcResponse.set("response", objectMapper.valueToTree(Map.of("output", toolResult)));
                }

                history.add(functionTurn);
            }

            // Cap history to last 20 turns to conserve token budget
            if (history.size() > 20) {
                history.subList(0, history.size() - 20).clear();
            }

            return AgentChatResponse.builder()
                    .conversationId(conversationId)
                    .message(finalResponseText)
                    .toolCallsExecuted(executedTools)
                    .build();

        } catch (Exception e) {
            log.error("Error in agent chat loop: {}", e.getMessage(), e);
            return AgentChatResponse.builder()
                    .conversationId(conversationId)
                    .message("I encountered an issue processing your request: " + e.getMessage())
                    .toolCallsExecuted(executedTools)
                    .build();
        }
    }

    private ObjectNode buildGeminiRequestBody(List<ObjectNode> history) {
        ObjectNode body = objectMapper.createObjectNode();

        // System instruction
        ObjectNode systemInstruction = body.putObject("system_instruction");
        ArrayNode sysParts = systemInstruction.putArray("parts");
        sysParts.addObject().put("text", SYSTEM_INSTRUCTION);

        // Contents (conversation turns)
        ArrayNode contents = body.putArray("contents");
        for (ObjectNode turn : history) {
            contents.add(turn);
        }

        // Tools
        ArrayNode tools = body.putArray("tools");
        ObjectNode toolObj = tools.addObject();
        ArrayNode functionDeclarations = toolObj.putArray("function_declarations");

        List<Map<String, Object>> decls = agentToolService.getToolDeclarations();
        for (Map<String, Object> d : decls) {
            functionDeclarations.add(objectMapper.valueToTree(d));
        }

        return body;
    }
}
