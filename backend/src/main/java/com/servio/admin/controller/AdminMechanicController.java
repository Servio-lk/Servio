package com.servio.admin.controller;

import com.servio.admin.dto.MechanicDto;
import com.servio.admin.service.MechanicService;
import com.servio.common.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/mechanics")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminMechanicController {
    private final MechanicService mechanicService;

    @PostMapping
    public ResponseEntity<ApiResponse<MechanicDto>> createMechanic(@RequestBody MechanicDto dto) {
        MechanicDto created = mechanicService.createMechanic(dto);
        return ResponseEntity.ok(ApiResponse.success("Mechanic created successfully", created));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<MechanicDto>> getMechanicById(@PathVariable Long id) {
        MechanicDto mechanic = mechanicService.getMechanicById(id);
        return ResponseEntity.ok(ApiResponse.success("Mechanic retrieved successfully", mechanic));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<MechanicDto>>> getAllMechanics() {
        List<MechanicDto> mechanics = mechanicService.getAllMechanics();
        return ResponseEntity.ok(ApiResponse.success("Mechanics retrieved successfully", mechanics));
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<ApiResponse<List<MechanicDto>>> getMechanicsByStatus(@PathVariable String status) {
        List<MechanicDto> mechanics = mechanicService.getMechanicsByStatus(status);
        return ResponseEntity.ok(ApiResponse.success("Mechanics retrieved successfully", mechanics));
    }

    @GetMapping("/available")
    public ResponseEntity<ApiResponse<List<MechanicDto>>> getAvailableMechanics() {
        List<MechanicDto> mechanics = mechanicService.getAvailableMechanics();
        return ResponseEntity.ok(ApiResponse.success("Available mechanics retrieved successfully", mechanics));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<MechanicDto>> updateMechanic(@PathVariable Long id, @RequestBody MechanicDto dto) {
        MechanicDto updated = mechanicService.updateMechanic(id, dto);
        return ResponseEntity.ok(ApiResponse.success("Mechanic updated successfully", updated));
    }

    @PatchMapping("/{id}/status/{status}")
    public ResponseEntity<ApiResponse<Void>> updateMechanicStatus(@PathVariable Long id, @PathVariable String status) {
        mechanicService.updateMechanicStatus(id, status);
        return ResponseEntity.ok(ApiResponse.success("Mechanic status updated successfully", null));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteMechanic(@PathVariable Long id) {
        mechanicService.deleteMechanic(id);
        return ResponseEntity.ok(ApiResponse.success("Mechanic deleted successfully", null));
    }
}
