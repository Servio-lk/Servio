package com.servio.booking.controller;

import com.servio.catalog.entity.Service;

import com.servio.common.dto.ApiResponse;
import com.servio.booking.dto.ServiceRecordDto;
import com.servio.booking.dto.ServiceRecordRequest;
import com.servio.booking.service.ServiceRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/servicerecords")
@RequiredArgsConstructor
public class ServiceRecordController {
    private final ServiceRecordService serviceRecordService;

    @PostMapping
    @PreAuthorize("hasAnyAuthority('ADMIN', 'MECHANIC')")
    public ResponseEntity<ApiResponse<ServiceRecordDto>> createServiceRecord(
            @RequestBody ServiceRecordRequest request) {
        ServiceRecordDto record = serviceRecordService.createServiceRecord(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Service record created successfully", record));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('ADMIN', 'MECHANIC')")
    public ResponseEntity<ApiResponse<ServiceRecordDto>> updateServiceRecord(
            @PathVariable Long id,
            @RequestBody ServiceRecordRequest request) {
        ServiceRecordDto record = serviceRecordService.updateServiceRecord(id, request);
        return ResponseEntity.ok(ApiResponse.success("Service record updated successfully", record));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('ADMIN', 'MECHANIC')")
    public ResponseEntity<ApiResponse<Void>> deleteServiceRecord(@PathVariable Long id) {
        serviceRecordService.deleteServiceRecord(id);
        return ResponseEntity.ok(ApiResponse.success("Service record deleted successfully", null));
    }
}
