package com.servio.admin.controller;

import com.servio.admin.dto.WalkInCustomerDto;
import com.servio.admin.service.WalkInCustomerService;
import com.servio.common.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/walk-in-customers")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminWalkInCustomerController {
    private final WalkInCustomerService walkInCustomerService;

    @PostMapping
    public ResponseEntity<ApiResponse<WalkInCustomerDto>> createWalkInCustomer(@RequestBody WalkInCustomerDto dto) {
        WalkInCustomerDto created = walkInCustomerService.createWalkInCustomer(dto);
        return ResponseEntity.ok(ApiResponse.success("Walk-in customer created successfully", created));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<WalkInCustomerDto>> getWalkInCustomerById(@PathVariable Long id) {
        WalkInCustomerDto customer = walkInCustomerService.getWalkInCustomerById(id);
        return ResponseEntity.ok(ApiResponse.success("Walk-in customer retrieved successfully", customer));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<WalkInCustomerDto>>> getAllWalkInCustomers() {
        List<WalkInCustomerDto> customers = walkInCustomerService.getAllWalkInCustomers();
        return ResponseEntity.ok(ApiResponse.success("Walk-in customers retrieved successfully", customers));
    }

    @GetMapping("/unregistered")
    public ResponseEntity<ApiResponse<List<WalkInCustomerDto>>> getUnregisteredCustomers() {
        List<WalkInCustomerDto> customers = walkInCustomerService.getUnregisteredCustomers();
        return ResponseEntity.ok(ApiResponse.success("Unregistered customers retrieved successfully", customers));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<WalkInCustomerDto>> updateWalkInCustomer(@PathVariable Long id, @RequestBody WalkInCustomerDto dto) {
        WalkInCustomerDto updated = walkInCustomerService.updateWalkInCustomer(id, dto);
        return ResponseEntity.ok(ApiResponse.success("Walk-in customer updated successfully", updated));
    }

    @PatchMapping("/{id}/register/{userId}")
    public ResponseEntity<ApiResponse<Void>> markAsRegistered(@PathVariable Long id, @PathVariable UUID userId) {
        walkInCustomerService.markAsRegistered(id, userId);
        return ResponseEntity.ok(ApiResponse.success("Customer marked as registered successfully", null));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteWalkInCustomer(@PathVariable Long id) {
        walkInCustomerService.deleteWalkInCustomer(id);
        return ResponseEntity.ok(ApiResponse.success("Walk-in customer deleted successfully", null));
    }
}
