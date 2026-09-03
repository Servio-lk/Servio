package com.servio.repair.controller;

import com.servio.common.dto.ApiResponse;
import com.servio.repair.dto.RepairConversationDto;
import com.servio.repair.dto.RepairMessageDto;
import com.servio.repair.dto.RepairMessageRequest;
import com.servio.repair.service.RepairChatService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RepairChatControllerTest {

    @Mock
    private RepairChatService repairChatService;
    @Mock
    private Authentication authentication;

    @InjectMocks
    private RepairChatController repairChatController;

    private Long repairId;

    @BeforeEach
    void setUp() {
        repairId = 55L;
    }

    @Test
    @DisplayName("getConversation returns success ApiResponse with conversation DTO")
    void testGetConversationSuccess() {
        RepairConversationDto dto = RepairConversationDto.builder()
                .id(1L)
                .repairId(repairId)
                .build();

        when(repairChatService.getConversationDto(repairId, authentication)).thenReturn(dto);

        ResponseEntity<ApiResponse<RepairConversationDto>> response = repairChatController.getConversation(repairId, authentication);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals(dto, response.getBody().getData());
    }

    @Test
    @DisplayName("getMessages returns success ApiResponse with message list")
    void testGetMessagesSuccess() {
        RepairMessageDto msg = RepairMessageDto.builder()
                .id(10L)
                .body("Diagnostic in progress")
                .senderId("tech_1")
                .build();

        when(repairChatService.getMessages(repairId, authentication)).thenReturn(List.of(msg));

        ResponseEntity<ApiResponse<List<RepairMessageDto>>> response = repairChatController.getMessages(repairId, authentication);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals(1, response.getBody().getData().size());
        assertEquals("Diagnostic in progress", response.getBody().getData().get(0).getBody());
    }

    @Test
    @DisplayName("sendMessage returns success ApiResponse with newly sent message DTO")
    void testSendMessageSuccess() {
        RepairMessageRequest request = new RepairMessageRequest();
        request.setBody("Can you provide an estimate?");

        RepairMessageDto dto = RepairMessageDto.builder()
                .id(11L)
                .body("Can you provide an estimate?")
                .senderId("cust_1")
                .build();

        when(repairChatService.sendMessage(repairId, request, authentication)).thenReturn(dto);

        ResponseEntity<ApiResponse<RepairMessageDto>> response = repairChatController.sendMessage(repairId, request, authentication);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals(dto, response.getBody().getData());
    }
}
