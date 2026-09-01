package com.servio.admin.controller;

import com.servio.admin.dto.JobCardPhotoDto;
import com.servio.admin.entity.PhotoType;
import com.servio.admin.service.JobCardPhotoService;
import com.servio.common.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/job-card-photos")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminJobCardPhotoController {
    private final JobCardPhotoService jobCardPhotoService;

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<JobCardPhotoDto>> uploadPhoto(
            @RequestParam("jobCardId") Long jobCardId,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "photoType", required = false) PhotoType photoType,
            @RequestParam(value = "description", required = false) String description,
            Authentication authentication
    ) {
        UUID uploadedById = null;
        if (authentication != null && authentication.isAuthenticated()) {
            try {
                uploadedById = UUID.fromString(authentication.getName());
            } catch (IllegalArgumentException ignored) {}
        }
        JobCardPhotoDto created = jobCardPhotoService.uploadPhoto(jobCardId, file, photoType, description, uploadedById);
        return ResponseEntity.ok(ApiResponse.success("Photo uploaded successfully", created));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<JobCardPhotoDto>> addPhoto(@RequestBody JobCardPhotoDto dto) {
        JobCardPhotoDto created = jobCardPhotoService.addPhoto(dto);
        return ResponseEntity.ok(ApiResponse.success("Photo added successfully", created));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<JobCardPhotoDto>> getPhotoById(@PathVariable Long id) {
        JobCardPhotoDto photo = jobCardPhotoService.getPhotoById(id);
        return ResponseEntity.ok(ApiResponse.success("Photo retrieved successfully", photo));
    }

    @GetMapping("/job-card/{jobCardId}")
    public ResponseEntity<ApiResponse<List<JobCardPhotoDto>>> getPhotosByJobCard(@PathVariable Long jobCardId) {
        List<JobCardPhotoDto> photos = jobCardPhotoService.getPhotosByJobCard(jobCardId);
        return ResponseEntity.ok(ApiResponse.success("Photos retrieved successfully", photos));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deletePhoto(@PathVariable Long id) {
        jobCardPhotoService.deletePhoto(id);
        return ResponseEntity.ok(ApiResponse.success("Photo deleted successfully", null));
    }
}
