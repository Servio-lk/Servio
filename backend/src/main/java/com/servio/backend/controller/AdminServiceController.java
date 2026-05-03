package com.servio.backend.controller;

import com.servio.backend.entity.Service;
import com.servio.backend.service.AdminServiceService;
import com.servio.backend.service.CloudinaryService;
import com.servio.dto.ApiResponse;
import com.servio.dto.admin.AdminServiceDto;
import com.servio.dto.admin.ServiceRequest;
import com.servio.dto.admin.ServicePhotoUploadResponse;
import com.servio.dto.admin.ServiceToggleRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/admin/services")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminServiceController {

    private final AdminServiceService adminServiceService;
    private final CloudinaryService cloudinaryService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<AdminServiceDto>>> getAllServices() {
        List<AdminServiceDto> services = adminServiceService.getAllServices();
        return ResponseEntity.ok(ApiResponse.success("Services retrieved successfully", services));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<AdminServiceDto>> getServiceById(@PathVariable Long id) {
        Service service = adminServiceService.getServiceById(id);
        return ResponseEntity.ok(ApiResponse.success("Service retrieved successfully", adminServiceService.convertToDto(service)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<AdminServiceDto>> createService(@Valid @RequestBody ServiceRequest request) {
        Service service = adminServiceService.createService(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Service created successfully", adminServiceService.convertToDto(service)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<AdminServiceDto>> updateService(
            @PathVariable Long id,
            @Valid @RequestBody ServiceRequest request) {
        Service service = adminServiceService.updateService(id, request);
        return ResponseEntity.ok(ApiResponse.success("Service updated successfully", adminServiceService.convertToDto(service)));
    }

    @PatchMapping("/{id}/toggle")
    public ResponseEntity<ApiResponse<AdminServiceDto>> toggleServiceStatus(
            @PathVariable Long id,
            @Valid @RequestBody ServiceToggleRequest request) {
        Service service = adminServiceService.toggleServiceStatus(id, request);
        return ResponseEntity.ok(ApiResponse.success("Service status updated successfully", adminServiceService.convertToDto(service)));
    }

    @PatchMapping("/{id}/publish")
    public ResponseEntity<ApiResponse<AdminServiceDto>> publishService(@PathVariable Long id) {
        Service service = adminServiceService.publishService(id);
        return ResponseEntity.ok(ApiResponse.success("Service published successfully", adminServiceService.convertToDto(service)));
    }

    @PatchMapping("/{id}/hide")
    public ResponseEntity<ApiResponse<AdminServiceDto>> hideService(@PathVariable Long id) {
        Service service = adminServiceService.hideService(id);
        return ResponseEntity.ok(ApiResponse.success("Service hidden successfully", adminServiceService.convertToDto(service)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteService(@PathVariable Long id) {
        adminServiceService.deleteService(id);
        return ResponseEntity.ok(ApiResponse.success("Service deleted successfully", null));
    }

    @PostMapping(value = "/photos/upload", consumes = "multipart/form-data")
    public ResponseEntity<ApiResponse<ServicePhotoUploadResponse>> uploadPhoto(@RequestParam("file") MultipartFile file) {
        ServicePhotoUploadResponse photo = cloudinaryService.uploadServicePhoto(file);
        return ResponseEntity.ok(ApiResponse.success("Photo uploaded successfully", photo));
    }

    @PostMapping(value = "/icons/upload", consumes = "multipart/form-data")
    public ResponseEntity<ApiResponse<ServicePhotoUploadResponse>> uploadIcon(@RequestParam("file") MultipartFile file) {
        ServicePhotoUploadResponse icon = cloudinaryService.uploadServiceIcon(file);
        return ResponseEntity.ok(ApiResponse.success("Icon uploaded successfully", icon));
    }
}
