package com.servio.controller;

import com.servio.dto.ApiResponse;
import com.servio.dto.WalkInCustomerDto;
import com.servio.service.WalkInCustomerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/admin/walk-in-customers")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminWalkInCustomerController {
    private final WalkInCustomerService walkInCustomerService;

    @PostMapping
    public ResponseEntity<?> createWalkInCustomer(@RequestBody WalkInCustomerDto dto) {
        try {
            WalkInCustomerDto created = walkInCustomerService.createWalkInCustomer(dto);
            return ResponseEntity.ok(ApiResponse.success("Walk-in customer created successfully", created));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to create walk-in customer", e.getMessage()));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getWalkInCustomerById(@PathVariable Long id) {
        try {
            WalkInCustomerDto customer = walkInCustomerService.getWalkInCustomerById(id);
            return ResponseEntity.ok(ApiResponse.success("Walk-in customer retrieved successfully", customer));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to retrieve walk-in customer", e.getMessage()));
        }
    }

    @GetMapping
    public ResponseEntity<?> getAllWalkInCustomers() {
        try {
            List<WalkInCustomerDto> customers = walkInCustomerService.getAllWalkInCustomers();
            return ResponseEntity.ok(ApiResponse.success("Walk-in customers retrieved successfully", customers));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to retrieve walk-in customers", e.getMessage()));
        }
    }

    @GetMapping("/unregistered")
    public ResponseEntity<?> getUnregisteredCustomers() {
        try {
            List<WalkInCustomerDto> customers = walkInCustomerService.getUnregisteredCustomers();
            return ResponseEntity.ok(ApiResponse.success("Unregistered customers retrieved successfully", customers));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to retrieve unregistered customers", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateWalkInCustomer(@PathVariable Long id, @RequestBody WalkInCustomerDto dto) {
        try {
            WalkInCustomerDto updated = walkInCustomerService.updateWalkInCustomer(id, dto);
            return ResponseEntity.ok(ApiResponse.success("Walk-in customer updated successfully", updated));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to update walk-in customer", e.getMessage()));
        }
    }

    @PatchMapping("/{id}/register/{userId}")
    public ResponseEntity<?> markAsRegistered(@PathVariable Long id, @PathVariable Long userId) {
        try {
            walkInCustomerService.markAsRegistered(id, userId);
            return ResponseEntity.ok(ApiResponse.success("Customer marked as registered successfully", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to register customer", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteWalkInCustomer(@PathVariable Long id) {
        try {
            walkInCustomerService.deleteWalkInCustomer(id);
            return ResponseEntity.ok(ApiResponse.success("Walk-in customer deleted successfully", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to delete walk-in customer", e.getMessage()));
        }
    }
}
