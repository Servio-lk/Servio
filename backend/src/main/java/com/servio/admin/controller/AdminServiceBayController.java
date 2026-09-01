package com.servio.admin.controller;

import com.servio.admin.dto.ServiceBayDto;
import com.servio.admin.service.ServiceBayService;
import com.servio.common.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/service-bays")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminServiceBayController {
    private final ServiceBayService serviceBayService;

    @PostMapping
    public ResponseEntity<ApiResponse<ServiceBayDto>> createServiceBay(@RequestBody ServiceBayDto dto) {
        ServiceBayDto created = serviceBayService.createServiceBay(dto);
        return ResponseEntity.ok(ApiResponse.success("Service bay created successfully", created));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ServiceBayDto>> getServiceBayById(@PathVariable Long id) {
        ServiceBayDto bay = serviceBayService.getServiceBayById(id);
        return ResponseEntity.ok(ApiResponse.success("Service bay retrieved successfully", bay));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<ServiceBayDto>>> getAllServiceBays() {
        List<ServiceBayDto> bays = serviceBayService.getAllServiceBays();
        return ResponseEntity.ok(ApiResponse.success("Service bays retrieved successfully", bays));
    }

    @GetMapping("/available")
    public ResponseEntity<ApiResponse<List<ServiceBayDto>>> getAvailableBays() {
        List<ServiceBayDto> bays = serviceBayService.getAvailableBays();
        return ResponseEntity.ok(ApiResponse.success("Available bays retrieved successfully", bays));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ServiceBayDto>> updateServiceBay(@PathVariable Long id, @RequestBody ServiceBayDto dto) {
        ServiceBayDto updated = serviceBayService.updateServiceBay(id, dto);
        return ResponseEntity.ok(ApiResponse.success("Service bay updated successfully", updated));
    }

    @PatchMapping("/{id}/status/{status}")
    public ResponseEntity<ApiResponse<Void>> updateServiceBayStatus(@PathVariable Long id, @PathVariable String status) {
        serviceBayService.updateServiceBayStatus(id, status);
        return ResponseEntity.ok(ApiResponse.success("Service bay status updated successfully", null));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteServiceBay(@PathVariable Long id) {
        serviceBayService.deleteServiceBay(id);
        return ResponseEntity.ok(ApiResponse.success("Service bay deleted successfully", null));
    }
}
