package com.servio.admin.controller;

import com.servio.repair.dto.RepairConversationDto;
import com.servio.common.dto.ApiResponse;
import com.servio.repair.service.RepairChatService;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/conversations")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminChatInboxController {
    
    private final RepairChatService repairChatService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<RepairConversationDto>>> getAllConversations() {
        try {
            List<RepairConversationDto> list = repairChatService.getAdminConversationList();
            return ResponseEntity.ok(ApiResponse.success("Conversations retrieved successfully", list));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve conversations", e.getMessage()));
        }
    }

    @PatchMapping("/{conversationId}/read")
    public ResponseEntity<ApiResponse<Void>> markMessagesAsRead(
            @PathVariable Long conversationId,
            Authentication authentication
    ) {
        try {
            repairChatService.markMessagesRead(conversationId, authentication);
            return ResponseEntity.ok(ApiResponse.success("Messages marked as read", null));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to mark read", e.getMessage()));
        }
    }
}
