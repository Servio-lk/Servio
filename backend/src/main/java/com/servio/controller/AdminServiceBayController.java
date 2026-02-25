package com.servio.controller;

import com.servio.dto.ApiResponse;
import com.servio.dto.ServiceBayDto;
import com.servio.service.ServiceBayService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/admin/service-bays")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminServiceBayController {
    private final ServiceBayService serviceBayService;

    @PostMapping
    public ResponseEntity<?> createServiceBay(@RequestBody ServiceBayDto dto) {
        try {
            ServiceBayDto created = serviceBayService.createServiceBay(dto);
            return ResponseEntity.ok(ApiResponse.success("Service bay created successfully", created));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to create service bay", e.getMessage()));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getServiceBayById(@PathVariable Long id) {
        try {
            ServiceBayDto bay = serviceBayService.getServiceBayById(id);
            return ResponseEntity.ok(ApiResponse.success("Service bay retrieved successfully", bay));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to retrieve service bay", e.getMessage()));
        }
    }

    @GetMapping
    public ResponseEntity<?> getAllServiceBays() {
        try {
            List<ServiceBayDto> bays = serviceBayService.getAllServiceBays();
            return ResponseEntity.ok(ApiResponse.success("Service bays retrieved successfully", bays));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to retrieve service bays", e.getMessage()));
        }
    }

    @GetMapping("/available")
    public ResponseEntity<?> getAvailableBays() {
        try {
            List<ServiceBayDto> bays = serviceBayService.getAvailableBays();
            return ResponseEntity.ok(ApiResponse.success("Available bays retrieved successfully", bays));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to retrieve available bays", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateServiceBay(@PathVariable Long id, @RequestBody ServiceBayDto dto) {
        try {
            ServiceBayDto updated = serviceBayService.updateServiceBay(id, dto);
            return ResponseEntity.ok(ApiResponse.success("Service bay updated successfully", updated));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to update service bay", e.getMessage()));
        }
    }

    @PatchMapping("/{id}/status/{status}")
    public ResponseEntity<?> updateServiceBayStatus(@PathVariable Long id, @PathVariable String status) {
        try {
            serviceBayService.updateServiceBayStatus(id, status);
            return ResponseEntity.ok(ApiResponse.success("Service bay status updated successfully", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to update service bay status", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteServiceBay(@PathVariable Long id) {
        try {
            serviceBayService.deleteServiceBay(id);
            return ResponseEntity.ok(ApiResponse.success("Service bay deleted successfully", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to delete service bay", e.getMessage()));
        }
    }
}
