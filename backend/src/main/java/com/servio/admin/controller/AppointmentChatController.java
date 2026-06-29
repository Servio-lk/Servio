package com.servio.admin.controller;

import com.servio.common.dto.ApiResponse;
import com.servio.repair.dto.RepairConversationDto;
import com.servio.repair.service.RepairChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/appointments/{appointmentId}/conversation")
@RequiredArgsConstructor
public class AppointmentChatController {
    private final RepairChatService repairChatService;

    @GetMapping
    public ResponseEntity<ApiResponse<RepairConversationDto>> getConversation(
            @PathVariable Long appointmentId,
            Authentication authentication) {
        try {
            RepairConversationDto conversation = repairChatService.getConversationByAppointment(appointmentId, authentication);
            return ResponseEntity.ok(ApiResponse.success("Conversation retrieved successfully", conversation));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve conversation", e.getMessage()));
        }
    }
}
