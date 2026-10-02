package com.servio.admin.controller;

import com.servio.admin.dto.MechanicDto;
import com.servio.admin.dto.StaffFileUploadResponse;
import com.servio.admin.service.MechanicService;
import com.servio.admin.service.StaffCloudinaryService;
import com.servio.auth.entity.User;
import com.servio.auth.repository.UserRepository;
import com.servio.common.dto.ApiResponse;
import com.servio.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

@RestController
@RequestMapping("/api/mechanic")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('MECHANIC')")
public class MechanicSelfController {
    private final MechanicService mechanicService;
    private final StaffCloudinaryService staffCloudinaryService;
    private final UserRepository userRepository;

    private User getAuthenticatedUser(Authentication authentication) {
        String principal = authentication.getPrincipal().toString();
        try {
            UUID userId = UUID.fromString(principal);
            return userRepository.findById(userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Authenticated user not found"));
        } catch (IllegalArgumentException e) {
            return userRepository.findByEmail(principal)
                    .orElseThrow(() -> new ResourceNotFoundException("Authenticated user not found for: " + principal));
        }
    }

    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<MechanicDto>> getProfile(Authentication authentication) {
        try {
            User user = getAuthenticatedUser(authentication);
            MechanicDto dto = mechanicService.getMechanicByEmail(user.getEmail());
            return ResponseEntity.ok(ApiResponse.success("Mechanic profile retrieved", dto));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve profile: " + e.getMessage(), null));
        }
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<MechanicDto>> updateProfile(
            Authentication authentication,
            @RequestBody MechanicDto dto
    ) {
        try {
            User user = getAuthenticatedUser(authentication);
            MechanicDto updated = mechanicService.updateMechanicProfileByEmail(user.getEmail(), dto, false);
            return ResponseEntity.ok(ApiResponse.success("Profile saved successfully", updated));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to save profile: " + e.getMessage(), null));
        }
    }

    @PostMapping("/profile/submit")
    public ResponseEntity<ApiResponse<MechanicDto>> submitProfileForVerification(
            Authentication authentication,
            @RequestBody MechanicDto dto
    ) {
        try {
            User user = getAuthenticatedUser(authentication);
            MechanicDto submitted = mechanicService.updateMechanicProfileByEmail(user.getEmail(), dto, true);
            return ResponseEntity.ok(ApiResponse.success("Profile submitted for verification", submitted));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to submit profile: " + e.getMessage(), null));
        }
    }

    @PostMapping(value = "/documents/upload", consumes = "multipart/form-data")
    public ResponseEntity<ApiResponse<StaffFileUploadResponse>> uploadDocument(
            Authentication authentication,
            @RequestParam("file") MultipartFile file,
            @RequestParam String documentType
    ) {
        try {
            User user = getAuthenticatedUser(authentication);
            MechanicDto mechanic = mechanicService.getMechanicByEmail(user.getEmail());
            StaffFileUploadResponse uploaded = staffCloudinaryService.uploadStaffFile(file, documentType, mechanic.getId());
            return ResponseEntity.ok(ApiResponse.success("Document uploaded successfully", uploaded));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to upload document: " + e.getMessage(), null));
        }
    }
}
