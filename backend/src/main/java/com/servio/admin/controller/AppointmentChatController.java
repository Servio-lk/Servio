package com.servio.admin.controller;

import com.servio.common.dto.ApiResponse;
import com.servio.repair.dto.RepairConversationDto;
import com.servio.repair.dto.RepairMessageDto;
import com.servio.repair.dto.RepairMessageRequest;
import com.servio.repair.service.RepairChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/appointments/{appointmentId}")
@RequiredArgsConstructor
public class AppointmentChatController {
    private final RepairChatService repairChatService;

    @GetMapping({"/conversation", "/conversation/"})
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

    @GetMapping({"/messages", "/conversation/messages"})
    public ResponseEntity<ApiResponse<List<RepairMessageDto>>> getMessages(
            @PathVariable Long appointmentId,
            Authentication authentication) {
        try {
            RepairConversationDto conversation = repairChatService.getConversationByAppointment(appointmentId, authentication);
            List<RepairMessageDto> messages = repairChatService.getMessages(conversation.getRepairId(), authentication);
            return ResponseEntity.ok(ApiResponse.success("Messages retrieved successfully", messages));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve messages", e.getMessage()));
        }
    }

    @PostMapping({"/messages", "/conversation/messages"})
    public ResponseEntity<ApiResponse<RepairMessageDto>> sendMessage(
            @PathVariable Long appointmentId,
            @RequestBody RepairMessageRequest request,
            Authentication authentication) {
        try {
            RepairConversationDto conversation = repairChatService.getConversationByAppointment(appointmentId, authentication);
            RepairMessageDto message = repairChatService.sendMessage(conversation.getRepairId(), request, authentication);
            return ResponseEntity.ok(ApiResponse.success("Message sent successfully", message));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to send message", e.getMessage()));
        }
    }
}
