package com.servio.repair.controller;

import com.servio.common.dto.ApiResponse;
import com.servio.repair.service.RepairChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
public class ChatController {
    private final RepairChatService repairChatService;

    @GetMapping("/unread")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getUnreadCount(Authentication authentication) {
        try {
            long count = repairChatService.getGlobalUnreadCount(authentication);
            return ResponseEntity.ok(ApiResponse.success("Unread count retrieved", Map.of("count", count)));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve unread count", e.getMessage()));
        }
    }
}
