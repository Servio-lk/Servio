package com.servio.repair.controller;

import com.servio.admin.dto.JobCardPhotoDto;
import com.servio.admin.entity.PhotoType;
import com.servio.admin.service.JobCardPhotoService;
import com.servio.common.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
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
@RequestMapping("/api/repairs")
@RequiredArgsConstructor
@Tag(name = "Repair Job Card Photos", description = "Endpoints for uploading inspection photos for repair job cards")
public class JobCardPhotoController {

    private final JobCardPhotoService jobCardPhotoService;

    @PostMapping(value = "/{id}/job-cards/{cardId}/photos", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAuthority('ADMIN') or hasAuthority('MECHANIC')")
    @Operation(summary = "Upload an inspection or repair photo for a job card")
    public ResponseEntity<ApiResponse<JobCardPhotoDto>> uploadJobCardPhoto(
            @PathVariable("id") Long repairId,
            @PathVariable("cardId") Long cardId,
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

        JobCardPhotoDto created = jobCardPhotoService.uploadPhoto(cardId, file, photoType, description, uploadedById);
        return ResponseEntity.ok(ApiResponse.success("Inspection photo uploaded successfully", created));
    }

    @GetMapping("/{id}/job-cards/{cardId}/photos")
    @Operation(summary = "Get all inspection photos for a job card")
    public ResponseEntity<ApiResponse<List<JobCardPhotoDto>>> getJobCardPhotos(
            @PathVariable("id") Long repairId,
            @PathVariable("cardId") Long cardId
    ) {
        List<JobCardPhotoDto> photos = jobCardPhotoService.getPhotosByJobCard(cardId);
        return ResponseEntity.ok(ApiResponse.success("Photos retrieved successfully", photos));
    }
}
