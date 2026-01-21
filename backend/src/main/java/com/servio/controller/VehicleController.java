package com.servio.controller;

import com.servio.dto.*;
import com.servio.service.VehicleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/vehicles")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class VehicleController {
    
    private final VehicleService vehicleService;
    
    @PostMapping
    public ResponseEntity<ApiResponse<VehicleDto>> createVehicle(@RequestBody VehicleRequest request) {
        VehicleDto vehicle = vehicleService.createVehicle(request);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.<VehicleDto>builder()
                .success(true)
                .message("Vehicle created successfully")
                .data(vehicle)
                .build());
    }
    
    @GetMapping
    public ResponseEntity<ApiResponse<List<VehicleDto>>> getAllVehicles() {
        List<VehicleDto> vehicles = vehicleService.getAllVehicles();
        return ResponseEntity.ok(ApiResponse.<List<VehicleDto>>builder()
            .success(true)
            .message("Vehicles retrieved successfully")
            .data(vehicles)
            .build());
    }
    
    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<List<VehicleDto>>> getVehiclesByUserId(@PathVariable Long userId) {
        List<VehicleDto> vehicles = vehicleService.getVehiclesByUserId(userId);
        return ResponseEntity.ok(ApiResponse.<List<VehicleDto>>builder()
            .success(true)
            .message("User vehicles retrieved successfully")
            .data(vehicles)
            .build());
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<VehicleDto>> getVehicleById(@PathVariable Long id) {
        VehicleDto vehicle = vehicleService.getVehicleById(id);
        return ResponseEntity.ok(ApiResponse.<VehicleDto>builder()
            .success(true)
            .message("Vehicle retrieved successfully")
            .data(vehicle)
            .build());
    }
    
    @GetMapping("/{id}/stats")
    public ResponseEntity<ApiResponse<VehicleStatsDto>> getVehicleStats(@PathVariable Long id) {
        VehicleStatsDto stats = vehicleService.getVehicleStats(id);
        return ResponseEntity.ok(ApiResponse.<VehicleStatsDto>builder()
            .success(true)
            .message("Vehicle statistics retrieved successfully")
            .data(stats)
            .build());
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<VehicleDto>> updateVehicle(
        @PathVariable Long id,
        @RequestBody VehicleRequest request
    ) {
        VehicleDto vehicle = vehicleService.updateVehicle(id, request);
        return ResponseEntity.ok(ApiResponse.<VehicleDto>builder()
            .success(true)
            .message("Vehicle updated successfully")
            .data(vehicle)
            .build());
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteVehicle(@PathVariable Long id) {
        vehicleService.deleteVehicle(id);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
            .success(true)
            .message("Vehicle deleted successfully")
            .build());
    }
}
