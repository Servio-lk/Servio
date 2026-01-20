package com.servio.backend.controller;

import com.servio.backend.entity.Service;
import com.servio.backend.service.AdminServiceService;
import com.servio.dto.ApiResponse;
import com.servio.dto.admin.ServiceRequest;
import com.servio.dto.admin.ServiceToggleRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/services")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminServiceController {

    private final AdminServiceService adminServiceService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Service>>> getAllServices() {
        List<Service> services = adminServiceService.getAllServices();
        return ResponseEntity.ok(ApiResponse.success("Services retrieved successfully", services));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Service>> getServiceById(@PathVariable Long id) {
        Service service = adminServiceService.getServiceById(id);
        return ResponseEntity.ok(ApiResponse.success("Service retrieved successfully", service));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Service>> createService(@Valid @RequestBody ServiceRequest request) {
        Service service = adminServiceService.createService(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Service created successfully", service));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Service>> updateService(
            @PathVariable Long id,
            @Valid @RequestBody ServiceRequest request) {
        Service service = adminServiceService.updateService(id, request);
        return ResponseEntity.ok(ApiResponse.success("Service updated successfully", service));
    }

    @PatchMapping("/{id}/toggle")
    public ResponseEntity<ApiResponse<Service>> toggleServiceStatus(
            @PathVariable Long id,
            @Valid @RequestBody ServiceToggleRequest request) {
        Service service = adminServiceService.toggleServiceStatus(id, request);
        return ResponseEntity.ok(ApiResponse.success("Service status updated successfully", service));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteService(@PathVariable Long id) {
        adminServiceService.deleteService(id);
        return ResponseEntity.ok(ApiResponse.success("Service deleted successfully", null));
    }
}
