package com.servio.controller;

import com.servio.dto.ApiResponse;
import com.servio.dto.MechanicDto;
import com.servio.service.MechanicService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/admin/mechanics")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminMechanicController {
    private final MechanicService mechanicService;

    @PostMapping
    public ResponseEntity<?> createMechanic(@RequestBody MechanicDto dto) {
        try {
            MechanicDto created = mechanicService.createMechanic(dto);
            return ResponseEntity.ok(ApiResponse.success("Mechanic created successfully", created));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to create mechanic", e.getMessage()));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getMechanicById(@PathVariable Long id) {
        try {
            MechanicDto mechanic = mechanicService.getMechanicById(id);
            return ResponseEntity.ok(ApiResponse.success("Mechanic retrieved successfully", mechanic));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve mechanic", e.getMessage()));
        }
    }

    @GetMapping
    public ResponseEntity<?> getAllMechanics() {
        try {
            List<MechanicDto> mechanics = mechanicService.getAllMechanics();
            return ResponseEntity.ok(ApiResponse.success("Mechanics retrieved successfully", mechanics));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve mechanics", e.getMessage()));
        }
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<?> getMechanicsByStatus(@PathVariable String status) {
        try {
            List<MechanicDto> mechanics = mechanicService.getMechanicsByStatus(status);
            return ResponseEntity.ok(ApiResponse.success("Mechanics retrieved successfully", mechanics));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve mechanics", e.getMessage()));
        }
    }

    @GetMapping("/available")
    public ResponseEntity<?> getAvailableMechanics() {
        try {
            List<MechanicDto> mechanics = mechanicService.getAvailableMechanics();
            return ResponseEntity.ok(ApiResponse.success("Available mechanics retrieved successfully", mechanics));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to retrieve available mechanics", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateMechanic(@PathVariable Long id, @RequestBody MechanicDto dto) {
        try {
            MechanicDto updated = mechanicService.updateMechanic(id, dto);
            return ResponseEntity.ok(ApiResponse.success("Mechanic updated successfully", updated));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to update mechanic", e.getMessage()));
        }
    }

    @PatchMapping("/{id}/status/{status}")
    public ResponseEntity<?> updateMechanicStatus(@PathVariable Long id, @PathVariable String status) {
        try {
            mechanicService.updateMechanicStatus(id, status);
            return ResponseEntity.ok(ApiResponse.success("Mechanic status updated successfully", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to update mechanic status", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteMechanic(@PathVariable Long id) {
        try {
            mechanicService.deleteMechanic(id);
            return ResponseEntity.ok(ApiResponse.success("Mechanic deleted successfully", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to delete mechanic", e.getMessage()));
        }
    }
}
