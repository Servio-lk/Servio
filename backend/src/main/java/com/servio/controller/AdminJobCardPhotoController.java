package com.servio.controller;

import com.servio.dto.ApiResponse;
import com.servio.dto.JobCardPhotoDto;
import com.servio.service.JobCardPhotoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/admin/job-card-photos")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminJobCardPhotoController {
    private final JobCardPhotoService jobCardPhotoService;

    @PostMapping
    public ResponseEntity<?> addPhoto(@RequestBody JobCardPhotoDto dto) {
        try {
            JobCardPhotoDto created = jobCardPhotoService.addPhoto(dto);
            return ResponseEntity.ok(ApiResponse.success("Photo added successfully", created));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to add photo", e.getMessage()));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getPhotoById(@PathVariable Long id) {
        try {
            JobCardPhotoDto photo = jobCardPhotoService.getPhotoById(id);
            return ResponseEntity.ok(ApiResponse.success("Photo retrieved successfully", photo));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve photo", e.getMessage()));
        }
    }

    @GetMapping("/job-card/{jobCardId}")
    public ResponseEntity<?> getPhotosByJobCard(@PathVariable Long jobCardId) {
        try {
            List<JobCardPhotoDto> photos = jobCardPhotoService.getPhotosByJobCard(jobCardId);
            return ResponseEntity.ok(ApiResponse.success("Photos retrieved successfully", photos));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve photos", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deletePhoto(@PathVariable Long id) {
        try {
            jobCardPhotoService.deletePhoto(id);
            return ResponseEntity.ok(ApiResponse.success("Photo deleted successfully", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to delete photo", e.getMessage()));
        }
    }
}
