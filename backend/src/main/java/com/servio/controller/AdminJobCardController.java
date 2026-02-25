package com.servio.controller;

import com.servio.dto.ApiResponse;
import com.servio.dto.JobCardDto;
import com.servio.service.JobCardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/admin/job-cards")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminJobCardController {
    private final JobCardService jobCardService;

    @PostMapping
    public ResponseEntity<?> createJobCard(@RequestBody JobCardDto dto) {
        try {
            JobCardDto created = jobCardService.createJobCard(dto);
            return ResponseEntity.ok(ApiResponse.success("Job card created successfully", created));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to create job card", e.getMessage()));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getJobCardById(@PathVariable Long id) {
        try {
            JobCardDto jobCard = jobCardService.getJobCardById(id);
            return ResponseEntity.ok(ApiResponse.success("Job card retrieved successfully", jobCard));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve job card", e.getMessage()));
        }
    }

    @GetMapping
    public ResponseEntity<?> getAllJobCards() {
        try {
            List<JobCardDto> jobCards = jobCardService.getAllJobCards();
            return ResponseEntity.ok(ApiResponse.success("Job cards retrieved successfully", jobCards));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve job cards", e.getMessage()));
        }
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<?> getJobCardsByStatus(@PathVariable String status) {
        try {
            List<JobCardDto> jobCards = jobCardService.getJobCardsByStatus(status);
            return ResponseEntity.ok(ApiResponse.success("Job cards retrieved successfully", jobCards));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve job cards", e.getMessage()));
        }
    }

    @GetMapping("/appointment/{appointmentId}")
    public ResponseEntity<?> getJobCardsByAppointment(@PathVariable Long appointmentId) {
        try {
            List<JobCardDto> jobCards = jobCardService.getJobCardsByAppointment(appointmentId);
            return ResponseEntity.ok(ApiResponse.success("Job cards retrieved successfully", jobCards));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve job cards", e.getMessage()));
        }
    }

    @GetMapping("/mechanic/{mechanicId}")
    public ResponseEntity<?> getJobCardsByMechanic(@PathVariable Long mechanicId) {
        try {
            List<JobCardDto> jobCards = jobCardService.getJobCardsByMechanic(mechanicId);
            return ResponseEntity.ok(ApiResponse.success("Job cards retrieved successfully", jobCards));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve job cards", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateJobCard(@PathVariable Long id, @RequestBody JobCardDto dto) {
        try {
            JobCardDto updated = jobCardService.updateJobCard(id, dto);
            return ResponseEntity.ok(ApiResponse.success("Job card updated successfully", updated));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to update job card", e.getMessage()));
        }
    }

    @PatchMapping("/{id}/status/{status}")
    public ResponseEntity<?> updateJobCardStatus(@PathVariable Long id, @PathVariable String status) {
        try {
            JobCardDto updated = jobCardService.updateJobCardStatus(id, status);
            return ResponseEntity.ok(ApiResponse.success("Job card status updated successfully", updated));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to update job card status", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteJobCard(@PathVariable Long id) {
        try {
            jobCardService.deleteJobCard(id);
            return ResponseEntity.ok(ApiResponse.success("Job card deleted successfully", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to delete job card", e.getMessage()));
        }
    }
}
