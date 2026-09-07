package com.servio.admin.controller;

import com.servio.repair.dto.RepairConversationDto;
import com.servio.common.dto.ApiResponse;
import com.servio.admin.dto.AssignMechanicRequest;
import com.servio.admin.entity.Mechanic;
import com.servio.repair.dto.RepairMessageRequest;
import com.servio.repair.dto.RepairMessageDto;

import com.servio.repair.service.RepairChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/repairs/{repairId}")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminRepairChatController {
    private final RepairChatService repairChatService;

    @PostMapping("/assign-mechanic")
    public ResponseEntity<ApiResponse<RepairConversationDto>> assignMechanic(
            @PathVariable Long repairId,
            @RequestBody AssignMechanicRequest request
    ) {
        try {
            RepairConversationDto conversation = repairChatService.assignMechanic(repairId, request.getMechanicId());
            return ResponseEntity.ok(ApiResponse.success("Mechanic assigned successfully", conversation));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to assign mechanic", e.getMessage()));
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
