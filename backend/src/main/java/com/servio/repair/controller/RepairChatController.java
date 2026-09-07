package com.servio.repair.controller;

import com.servio.repair.dto.RepairConversationDto;
import com.servio.repair.dto.RepairMessageRequest;
import com.servio.repair.dto.RepairMessageDto;
import com.servio.common.dto.ApiResponse;

import com.servio.repair.service.RepairChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/repairs/{repairId}")
@RequiredArgsConstructor
public class RepairChatController {
    private final RepairChatService repairChatService;

    @GetMapping("/conversation")
    public ResponseEntity<ApiResponse<RepairConversationDto>> getConversation(
            @PathVariable Long repairId,
            Authentication authentication
    ) {
        try {
            RepairConversationDto conversation = repairChatService.getConversationDto(repairId, authentication);
            return ResponseEntity.ok(ApiResponse.success("Conversation retrieved successfully", conversation));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve conversation", e.getMessage()));
        }
    }

    @GetMapping("/messages")
    public ResponseEntity<ApiResponse<List<RepairMessageDto>>> getMessages(
            @PathVariable Long repairId,
            Authentication authentication
    ) {
        try {
            List<RepairMessageDto> messages = repairChatService.getMessages(repairId, authentication);
            return ResponseEntity.ok(ApiResponse.success("Messages retrieved successfully", messages));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve messages", e.getMessage()));
        }
    }

    @PostMapping("/messages")
    public ResponseEntity<ApiResponse<RepairMessageDto>> sendMessage(
            @PathVariable Long repairId,
            @RequestBody RepairMessageRequest request,
            Authentication authentication
    ) {
        try {
            RepairMessageDto message = repairChatService.sendMessage(repairId, request, authentication);
            return ResponseEntity.ok(ApiResponse.success("Message sent successfully", message));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to send message", e.getMessage()));
        }
    }
}
