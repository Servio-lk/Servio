package com.servio.controller;

import com.servio.dto.ApiResponse;
import com.servio.dto.ServiceRecordDto;
import com.servio.dto.ServiceRecordRequest;
import com.servio.service.ServiceRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/servicerecords")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ServiceRecordController {
    private final ServiceRecordService serviceRecordService;

    @PostMapping
    public ResponseEntity<ApiResponse<ServiceRecordDto>> createServiceRecord(
            @RequestBody ServiceRecordRequest request) {
        ServiceRecordDto record = serviceRecordService.createServiceRecord(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Service record created successfully", record));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ServiceRecordDto>> updateServiceRecord(
            @PathVariable Long id,
            @RequestBody ServiceRecordRequest request) {
        ServiceRecordDto record = serviceRecordService.updateServiceRecord(id, request);
        return ResponseEntity.ok(ApiResponse.success("Service record updated successfully", record));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteServiceRecord(@PathVariable Long id) {
        serviceRecordService.deleteServiceRecord(id);
        return ResponseEntity.ok(ApiResponse.success("Service record deleted successfully", null));
    }
}
