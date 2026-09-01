package com.servio.admin.controller;

import com.servio.admin.dto.JobCardDto;
import com.servio.admin.service.JobCardService;
import com.servio.common.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/job-cards")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminJobCardController {
    private final JobCardService jobCardService;

    @PostMapping
    public ResponseEntity<ApiResponse<JobCardDto>> createJobCard(@RequestBody JobCardDto dto) {
        JobCardDto created = jobCardService.createJobCard(dto);
        return ResponseEntity.ok(ApiResponse.success("Job card created successfully", created));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<JobCardDto>> getJobCardById(@PathVariable Long id) {
        JobCardDto jobCard = jobCardService.getJobCardById(id);
        return ResponseEntity.ok(ApiResponse.success("Job card retrieved successfully", jobCard));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<JobCardDto>>> getAllJobCards() {
        List<JobCardDto> jobCards = jobCardService.getAllJobCards();
        return ResponseEntity.ok(ApiResponse.success("Job cards retrieved successfully", jobCards));
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<ApiResponse<List<JobCardDto>>> getJobCardsByStatus(@PathVariable String status) {
        List<JobCardDto> jobCards = jobCardService.getJobCardsByStatus(status);
        return ResponseEntity.ok(ApiResponse.success("Job cards retrieved successfully", jobCards));
    }

    @GetMapping("/appointment/{appointmentId}")
    public ResponseEntity<ApiResponse<List<JobCardDto>>> getJobCardsByAppointment(@PathVariable Long appointmentId) {
        List<JobCardDto> jobCards = jobCardService.getJobCardsByAppointment(appointmentId);
        return ResponseEntity.ok(ApiResponse.success("Job cards retrieved successfully", jobCards));
    }

    @GetMapping("/mechanic/{mechanicId}")
    public ResponseEntity<ApiResponse<List<JobCardDto>>> getJobCardsByMechanic(@PathVariable Long mechanicId) {
        List<JobCardDto> jobCards = jobCardService.getJobCardsByMechanic(mechanicId);
        return ResponseEntity.ok(ApiResponse.success("Job cards retrieved successfully", jobCards));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<JobCardDto>> updateJobCard(@PathVariable Long id, @RequestBody JobCardDto dto) {
        JobCardDto updated = jobCardService.updateJobCard(id, dto);
        return ResponseEntity.ok(ApiResponse.success("Job card updated successfully", updated));
    }

    @PatchMapping("/{id}/status/{status}")
    public ResponseEntity<ApiResponse<JobCardDto>> updateJobCardStatus(@PathVariable Long id, @PathVariable String status) {
        JobCardDto updated = jobCardService.updateJobCardStatus(id, status);
        return ResponseEntity.ok(ApiResponse.success("Job card status updated successfully", updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteJobCard(@PathVariable Long id) {
        jobCardService.deleteJobCard(id);
        return ResponseEntity.ok(ApiResponse.success("Job card deleted successfully", null));
    }
}
