package com.servio.controller;

import com.servio.dto.ApiResponse;
import com.servio.dto.JobTaskDto;
import com.servio.service.JobTaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/admin/job-tasks")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminJobTaskController {
    private final JobTaskService jobTaskService;

    @PostMapping
    public ResponseEntity<?> createJobTask(@RequestBody JobTaskDto dto) {
        try {
            JobTaskDto created = jobTaskService.createJobTask(dto);
            return ResponseEntity.ok(ApiResponse.success("Job task created successfully", created));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to create job task", e.getMessage()));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getJobTaskById(@PathVariable Long id) {
        try {
            JobTaskDto task = jobTaskService.getJobTaskById(id);
            return ResponseEntity.ok(ApiResponse.success("Job task retrieved successfully", task));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve job task", e.getMessage()));
        }
    }

    @GetMapping("/job-card/{jobCardId}")
    public ResponseEntity<?> getTasksByJobCard(@PathVariable Long jobCardId) {
        try {
            List<JobTaskDto> tasks = jobTaskService.getTasksByJobCard(jobCardId);
            return ResponseEntity.ok(ApiResponse.success("Job tasks retrieved successfully", tasks));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve job tasks", e.getMessage()));
        }
    }

    @GetMapping("/mechanic/{mechanicId}")
    public ResponseEntity<?> getTasksByMechanic(@PathVariable Long mechanicId) {
        try {
            List<JobTaskDto> tasks = jobTaskService.getTasksByMechanic(mechanicId);
            return ResponseEntity.ok(ApiResponse.success("Job tasks retrieved successfully", tasks));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve job tasks", e.getMessage()));
        }
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<?> getTasksByStatus(@PathVariable String status) {
        try {
            List<JobTaskDto> tasks = jobTaskService.getTasksByStatus(status);
            return ResponseEntity.ok(ApiResponse.success("Job tasks retrieved successfully", tasks));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve job tasks", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateJobTask(@PathVariable Long id, @RequestBody JobTaskDto dto) {
        try {
            JobTaskDto updated = jobTaskService.updateJobTask(id, dto);
            return ResponseEntity.ok(ApiResponse.success("Job task updated successfully", updated));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to update job task", e.getMessage()));
        }
    }

    @PatchMapping("/{id}/status/{status}")
    public ResponseEntity<?> updateTaskStatus(@PathVariable Long id, @PathVariable String status) {
        try {
            JobTaskDto updated = jobTaskService.updateTaskStatus(id, status);
            return ResponseEntity.ok(ApiResponse.success("Job task status updated successfully", updated));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to update job task status", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteJobTask(@PathVariable Long id) {
        try {
            jobTaskService.deleteJobTask(id);
            return ResponseEntity.ok(ApiResponse.success("Job task deleted successfully", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to delete job task", e.getMessage()));
        }
    }
}
